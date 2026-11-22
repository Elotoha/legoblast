"""Cross-language asset conversion and SDL smoke test with generated fixtures."""

import json
import os
from pathlib import Path
import struct
import subprocess
import sys
import tempfile
import wave

from PIL import Image


def chunk(kind, data):
    return struct.pack(">4sI", kind, len(data)) + data + b"\0" * (len(data) % 2)


def write_ilbm(path):
    header = struct.pack(">HHhhBBBBHBBhh", 2, 1, 0, 0, 1, 1, 1, 0, 0, 1, 1, 2, 1)
    palette = bytes((255, 0, 0, 0, 255, 0))
    body = bytes((128, 1, 64, 0, 1, 128, 0))
    form = b"ILBM" + chunk(b"BMHD", header) + chunk(b"CMAP", palette) + chunk(b"BODY", body)
    path.write_bytes(chunk(b"FORM", form))


def write_wav(path, values, rate):
    with wave.open(str(path), "wb") as wav:
        wav.setparams((1, 2, rate, 0, "NONE", "not compressed"))
        wav.writeframes(struct.pack(f"<{len(values)}h", *values))


def run(args, **kwargs):
    return subprocess.run(args, check=True, text=True, **kwargs)


def upscale_checks(root, converter):
    tool = str(Path(converter).with_name("upscale.py"))
    diagonal = Image.new("P", (3, 3), 0)
    diagonal.putpalette([0, 0, 0, 255, 255, 255])
    diagonal.putpixel((1, 0), 1)
    diagonal.putpixel((0, 1), 1)
    diagonal.info["transparency"] = 0
    diagonal.save(root / "diagonal.png")
    for factor in (2, 3, 4):
        resized = root / f"diagonal-{factor}x.png"
        run([sys.executable, tool, str(root / "diagonal.png"), str(resized),
             "--method", "pixel-art", "--factor", str(factor)])
        with Image.open(resized) as scaled:
            assert scaled.size == (3 * factor, 3 * factor)
            assert scaled.mode == "P" and scaled.info["transparency"] == 0
            assert set(scaled.getdata()) == {0, 1}
            assert scaled.getpixel((factor, factor)) == 1

    sheet = Image.new("RGBA", (4, 1), (0, 255, 0, 0))
    sheet.putpixel((0, 0), (255, 0, 0, 255))
    for x in (2, 3):
        sheet.putpixel((x, 0), (0, 0, 255, 255))
    sheet.save(root / "sheet.png")
    resized = root / "sheet-4x.png"
    run([sys.executable, tool, str(root / "sheet.png"), str(resized), "--method", "lanczos",
         "--factor", "4", "--grid", "2", "1"])
    with Image.open(resized) as scaled:
        left = list(scaled.crop((0, 0, 8, 4)).getdata())
        right = set(scaled.crop((8, 0, 16, 4)).getdata())
        assert any(0 < alpha < 255 for _, _, _, alpha in left)
        assert all((r, g, b) == (255, 0, 0) for r, g, b, alpha in left if alpha)
        assert right == {(0, 0, 255, 255)}


def main(converter, checks, preview):
    with tempfile.TemporaryDirectory() as temp:
        root = Path(temp)
        upscale_checks(root, converter)
        write_ilbm(root / "fixture.iff")
        high = Image.new("P", (8, 4), 1)
        high.putpalette([255, 0, 0, 0, 255, 0])
        high.save(root / "high.png")
        mask = Image.new("L", (8, 4), 255)
        mask.putpixel((1, 0), 0)
        mask.save(root / "high-mask.png")
        sample = bytes((64, 192))
        voice = struct.pack(">IIIHBBI", len(sample), 0, 0, 8000, 1, 0, 65536)
        (root / "tone.8svx").write_bytes(chunk(b"FORM", b"8SVX" + chunk(b"VHDR", voice) +
                                                             chunk(b"BODY", sample)))
        (root / "bar.raw").write_bytes(bytes((128, 0, 0, 0)))
        (root / "effect.raw").write_bytes(bytes((64, 192)))
        write_wav(root / "left.wav", [2048, 4096, 8192], 48000)
        write_wav(root / "right.wav", [2048, 2048, 2048], 48000)

        spec = {
            "images": {
                "sprite": {
                    "logical_size": [1, 1], "pixel_size": [2, 1], "anchor": [1, 0],
                    "grid": [2, 1], "frame_ticks": 2,
                    "cycles": [{"first": 0, "last": 1, "ticks": 1}],
                    "upscale": {"method": "pixel-art", "factors": [2, 3, 4]},
                    "sources": {"1": {"path": "fixture.iff", "format": "ilbm"},
                                "4": {"path": "high.png", "format": "png", "mask": "high-mask.png"}}
                },
                "bar": {
                    "logical_size": [2, 1], "pixel_size": [4, 1],
                    "sources": {"1": {"path": "bar.raw", "format": "planar", "width": 4,
                                      "height": 1, "planes": 2, "stride": 2,
                                      "layout": "plane-major",
                                      "palette": ["#000000", "#ffffff", "#ff0000", "#0000ff"]}}
                },
                "shade": {
                    "logical_size": [2, 1], "pixel_size": [4, 1], "grid": [2, 1],
                    "upscale": {"method": "lanczos", "factors": [4]},
                    "sources": {"1": {"path": "sheet.png", "format": "png"}}
                }
            },
            "sounds": {
                "effect": {"priority": 2, "volume": .5,
                           "source": {"path": "effect.raw", "format": "pcm-s8", "rate": 24000,
                                      "channels": 1}},
                "tone": {"source": {"path": "tone.8svx", "format": "8svx"}}
            },
            "music": {
                "cue": {"loop": [1, 3], "stems": [{"path": "left.wav", "format": "wav"},
                                                {"path": "right.wav", "format": "wav"}]}
            }
        }
        recipe = root / "recipe.json"
        recipe.write_text(json.dumps(spec), encoding="utf-8")
        package = root / "bundle"
        command = [sys.executable, converter, str(recipe)]
        run(command + [str(package), "--validator", preview])
        with Image.open(package / "sprite@2.png") as sprite, Image.open(package / "sprite@2-mask.png") as opacity:
            assert sprite.size == opacity.size == (4, 2)
            assert list(sprite.getdata()) == [0, 0, 1, 1] * 2
            assert list(opacity.getdata()) == [255, 255, 0, 0] * 2
        with Image.open(package / "shade@4.png") as shade, Image.open(root / "sheet-4x.png") as reference:
            assert shade.tobytes() == reference.tobytes()
        run([checks, str(package)])
        run([preview, str(package), "--frames", "4"],
            env={**os.environ, "SDL_VIDEODRIVER": "dummy", "SDL_AUDIODRIVER": "dummy",
                 "SDL_RENDER_DRIVER": "software"})

        missing = package / "sprite@1.png"
        missing.unlink()
        rejected = subprocess.run([preview, str(package), "--check"], capture_output=True, text=True)
        assert rejected.returncode != 0 and "images/sprite" in rejected.stderr and missing.name in rejected.stderr

        spec["music"]["cue"]["loop"] = [1, 9]
        recipe.write_text(json.dumps(spec), encoding="utf-8")
        invalid = root / "bad-package"
        rejected = subprocess.run(command + [str(invalid), "--validator", preview],
                                  capture_output=True, text=True)
        assert rejected.returncode != 0 and "music/cue" in rejected.stderr and not invalid.exists()


if __name__ == "__main__":
    main(*sys.argv[1:])

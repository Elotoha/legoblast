#!/usr/bin/env python3
"""Export side-by-side 4x PNGs from the tracked, self-describing Amiga images."""

from concurrent.futures import ThreadPoolExecutor
from io import BytesIO
import json
from pathlib import Path
import subprocess
from tempfile import TemporaryDirectory

from PIL import Image

from convert import read_ilbm
from upscale import upscale

ROOT = Path(__file__).resolve().parents[2]


def decode(path, kind):
    if kind == b"ILBM":
        try:
            indexed, mask = read_ilbm(path)
            if mask:
                pixels = indexed.convert("RGBA")
                pixels.putalpha(Image.frombytes("L", indexed.size, mask))
                return pixels
            return indexed
        except (KeyError, ValueError):
            # FFmpeg handles additional ILBM modes and redundant metadata chunks.
            decoded = subprocess.run(
                ["ffmpeg", "-v", "error", "-xerror", "-i", str(path),
                 "-frames:v", "1", "-c:v", "png", "-f", "image2pipe", "pipe:1"],
                check=True, capture_output=True,
            )
            with Image.open(BytesIO(decoded.stdout)) as image:
                return image.copy()
    with Image.open(path) as image:
        return image.copy()


def export_animation(path, destinations):
    with TemporaryDirectory() as directory:
        temp = Path(directory)
        probe = subprocess.run(
            ["ffprobe", "-v", "error", "-select_streams", "v:0", "-show_frames",
             "-show_entries", "frame=duration_time", "-of", "json", str(path)],
            check=True, capture_output=True,
        )
        durations = [float(frame["duration_time"]) * 1000
                     for frame in json.loads(probe.stdout)["frames"]]
        subprocess.run(
            ["ffmpeg", "-v", "error", "-xerror", "-i", str(path), "-map", "0:v:0",
             "-fps_mode", "passthrough", str(temp / "%06d.png")],
            check=True, capture_output=True,
        )
        frames = sorted(temp.glob("*.png"))
        if len(frames) != len(durations) or any(duration <= 0 for duration in durations):
            raise ValueError("decoded frames and original frame durations differ")
        for method, destination in destinations:
            if destination.exists():
                with Image.open(destination) as existing:
                    if not existing.is_animated:
                        raise ValueError(f"existing output is not animated: {destination}")
                continue
            rendered = []
            for frame in frames:
                with Image.open(frame) as original:
                    enlarged, _ = upscale(original.convert("RGBA"), 4, method)
                rendered.append(enlarged)
            with destination.open("xb") as stream:
                rendered[0].save(stream, format="PNG", save_all=True, append_images=rendered[1:],
                                 duration=durations, loop=0)
    return path, None


def export(item):
    path, kind, lanczos_path, pixel_path = item
    try:
        destinations = (("lanczos", ROOT / lanczos_path), ("pixel-art", ROOT / pixel_path))
        if kind == b"ANIM":
            return export_animation(ROOT / path, destinations)
        source = decode(ROOT / path, kind)
        expected = (source.width * 4, source.height * 4)
        for method, output in destinations:
            if output.exists():
                with Image.open(output) as existing:
                    existing.verify()
                    if existing.size != expected:
                        raise ValueError(f"existing output has unexpected dimensions: {output}")
                continue
            image, _ = upscale(source.convert("RGBA") if method == "lanczos" else source,
                               4, method)
            with output.open("xb") as stream:
                image.save(stream, format="PNG")
        return path, None
    except (KeyError, OSError, ValueError, subprocess.CalledProcessError) as error:
        return path, error


def main():
    tracked = subprocess.check_output(
        ["git", "ls-files", "-z", "--", "amiga/src"], cwd=ROOT
    ).decode().strip("\0").split("\0")
    reserved = set()
    items = []
    for path in sorted(map(Path, tracked)):
        with (ROOT / path).open("rb") as stream:
            header = stream.read(12)
        kind = header[8:12] if header[:4] == b"FORM" else b""
        if kind not in (b"ILBM", b"ANIM") and path.suffix.lower() not in (".jpg", ".jpeg"):
            continue
        stem = path.stem
        lanczos_path = path.with_name(f"{stem}.png")
        pixel_path = path.with_name(f"{stem}_pixelart.png")
        if any(candidate.as_posix().casefold() in reserved for candidate in (lanczos_path, pixel_path)):
            stem = f"{stem}_{path.suffix[1:].lower()}"
            lanczos_path = path.with_name(f"{stem}.png")
            pixel_path = path.with_name(f"{stem}_pixelart.png")
        reserved.update(candidate.as_posix().casefold() for candidate in (lanczos_path, pixel_path))
        items.append((path, kind, lanczos_path, pixel_path))

    failures = []
    stills = [item for item in items if item[1] != b"ANIM"]
    animations = [item for item in items if item[1] == b"ANIM"]
    with ThreadPoolExecutor(max_workers=3) as workers:
        results = list(workers.map(export, stills))
    for item in animations:
        results.append(export(item))
    for path, error in results:
        if error:
            failures.append(path)
            print(f"{path}: {error}", flush=True)
    print(f"{len(items) - len(failures)}/{len(items)} graphics exported")
    return bool(failures)


if __name__ == "__main__":
    raise SystemExit(main())

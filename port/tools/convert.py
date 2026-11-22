#!/usr/bin/env python3
"""Prepare a modern asset package from an explicit conversion recipe."""

import argparse
import json
import os
from pathlib import Path
import re
import shutil
import struct
import subprocess
import tempfile

from PIL import Image, ImageChops, ImageCms, ImageColor

from upscale import upscale

ID = re.compile(r"[a-z0-9][a-z0-9_-]*\Z")


def chunks(data):
    if len(data) < 12 or data[:4] != b"FORM":
        raise ValueError("expected an IFF FORM")
    end = 8 + int.from_bytes(data[4:8], "big")
    if not 12 <= end <= len(data):
        raise ValueError("invalid IFF length")
    pos = 12
    result = {}
    while pos < end:
        if pos + 8 > end:
            raise ValueError("truncated IFF chunk header")
        kind, length = struct.unpack_from(">4sI", data, pos)
        pos += 8
        if pos + length > end or kind in result:
            raise ValueError("truncated or duplicate IFF chunk")
        result[kind] = data[pos:pos + length]
        pos += length + (length & 1)
    return data[8:12], result


def unpack_row(data, pos, size, compressed):
    if not compressed:
        row = data[pos:pos + size]
        if len(row) != size:
            raise ValueError("truncated image scanline")
        return row, pos + size
    row = bytearray()
    while len(row) < size:
        if pos >= len(data):
            raise ValueError("truncated ByteRun1 scanline")
        control = struct.unpack_from("b", data, pos)[0]
        pos += 1
        if control >= 0:
            count = control + 1
            if pos + count > len(data):
                raise ValueError("truncated ByteRun1 literal")
            row.extend(data[pos:pos + count])
            pos += count
        elif control != -128:
            if pos >= len(data):
                raise ValueError("truncated ByteRun1 repeat")
            row.extend(data[pos:pos + 1] * (1 - control))
            pos += 1
    if len(row) != size:
        raise ValueError("ByteRun1 packet crosses a scanline")
    return row, pos


def planar(width, height, depth, colors, rows, masking=0, transparent=0):
    if not (1 <= width <= 8192 and 1 <= height <= 8192 and 1 <= depth <= 8):
        raise ValueError("unsupported planar dimensions or depth")
    if not colors or len(colors) > 768 or len(colors) % 3:
        raise ValueError("invalid palette")
    pixels = bytearray()
    mask = bytearray()
    for scanline in rows:
        for x in range(width):
            byte, bit = divmod(x, 8)
            value = sum(((scanline[p][byte] >> (7 - bit)) & 1) << p for p in range(depth))
            if value >= len(colors) // 3:
                raise ValueError("pixel references an undefined palette entry")
            pixels.append(value)
            if masking == 1:
                mask.append(255 if scanline[depth][byte] & (128 >> bit) else 0)
    image = Image.frombytes("P", (width, height), bytes(pixels))
    image.putpalette(colors)
    if masking == 2:
        if not 0 <= transparent < len(colors) // 3:
            raise ValueError("transparent index is outside the palette")
        image.info["transparency"] = transparent
    return image, bytes(mask)


def read_ilbm(path):
    kind, parts = chunks(path.read_bytes())
    if kind != b"ILBM":
        raise ValueError("expected a still ILBM image")
    width, height, _, _, depth, masking, compression, _, transparent, *_ = struct.unpack_from(
        ">HHhhBBBBHBBhh", parts[b"BMHD"]
    )
    mode = int.from_bytes(parts.get(b"CAMG", b"\0" * 4), "big")
    if mode & (0x800 | 0x80) or masking not in (0, 1, 2) or compression not in (0, 1):
        raise ValueError("unsupported ILBM display, mask or compression mode")
    body = parts[b"BODY"]

    def rows():
        pos = 0
        for _ in range(height):
            row = []
            for _ in range(depth + (masking == 1)):
                scan, pos = unpack_row(body, pos, ((width + 15) // 16) * 2, compression)
                row.append(scan)
            yield row
        if pos != len(body):
            raise ValueError("unexpected bytes after ILBM image")

    return planar(width, height, depth, parts[b"CMAP"], rows(), masking, transparent)


def read_raw(path, spec):
    width, height, depth = (spec[key] for key in ("width", "height", "planes"))
    stride = spec.get("stride", ((width + 15) // 16) * 2)
    layout = spec["layout"]
    if stride < (width + 7) // 8 or layout not in ("plane-major", "row-interleaved"):
        raise ValueError("invalid RAW stride or layout")
    data = path.read_bytes()
    if len(data) != stride * height * depth:
        raise ValueError("RAW length differs from declared layout")

    def rows():
        for y in range(height):
            starts = ((p * height + y if layout == "plane-major" else y * depth + p) * stride
                      for p in range(depth))
            yield [data[start:start + stride] for start in starts]

    colors = bytes(channel for color in spec["palette"] for channel in ImageColor.getrgb(color))
    transparent = spec.get("transparent_index", 0)
    return planar(width, height, depth, colors, rows(), 2 if "transparent_index" in spec else 0,
                  transparent)


def prepare_image(root, definition, indexed, destination, mask_destination):
    source = root / definition["path"]
    kind = definition["format"]
    if kind == "ilbm":
        image, mask = read_ilbm(source)
    elif kind == "planar":
        image, mask = read_raw(source, definition)
    elif kind == "png":
        with Image.open(source) as original:
            if original.format != "PNG" or getattr(original, "is_animated", False):
                raise ValueError("expected a still PNG")
            image = original.copy()
        mask = b""
    else:
        raise ValueError(f"unknown image input format {kind}")
    if "mask" in definition:
        if mask:
            raise ValueError("both embedded and external opacity masks were supplied")
        with Image.open(root / definition["mask"]) as opacity:
            if opacity.format != "PNG" or opacity.mode != "L" or opacity.size != image.size:
                raise ValueError("external mask must be an 8-bit grayscale PNG of the same size")
            mask = opacity.tobytes()
    if indexed and image.mode != "P":
        raise ValueError("palette animation requires an indexed source")
    if mask:
        opacity = Image.frombytes("L", image.size, mask)
        if indexed:
            opacity.save(mask_destination)
        else:
            image = image.convert("RGBA")
            image.putalpha(ImageChops.multiply(image.getchannel("A"), opacity))
    if not indexed:
        image = image.convert("RGBA")
    image.save(destination)
    return image.size, bool(indexed and mask)


def image_variants(root, stage, name, entry):
    variants = {}
    indexed = bool(entry.get("cycles"))
    for tier, source in entry["sources"].items():
        if tier not in ("1", "2", "3", "4"):
            raise ValueError("unsupported image tier")
        filename = f"{name}@{tier}.png"
        maskname = f"{name}@{tier}-mask.png"
        size, mask = prepare_image(root, source, indexed, stage / filename, stage / maskname)
        if size != tuple(value * int(tier) for value in entry["pixel_size"]):
            raise ValueError(f"tier {tier} has incorrect pixel dimensions")
        variants[tier] = {"image": filename}
        if mask:
            variants[tier]["mask"] = maskname
    if "1" not in variants:
        raise ValueError("missing base image")

    if "upscale" not in entry:
        return variants
    settings = entry["upscale"]
    factors = settings["factors"]
    if not isinstance(factors, list) or any(type(value) is not int or value not in (2, 3, 4)
                                          for value in factors):
        raise ValueError("upscale factors must be a list containing 2, 3 or 4")
    method = settings["method"]
    if method not in ("pixel-art", "lanczos"):
        raise ValueError("unknown upscale method")
    base = variants["1"]
    with Image.open(stage / base["image"]) as source:
        opacity = None
        if "mask" in base:
            with Image.open(stage / base["mask"]) as mask:
                opacity = mask.copy()
        for tier in sorted(set(factors)):
            if str(tier) in variants:
                continue
            image, mask = upscale(source, tier, method, entry.get("grid", (1, 1)), opacity)
            filename = f"{name}@{tier}.png"
            image.save(stage / filename)
            variants[str(tier)] = {"image": filename}
            if mask is not None:
                maskname = f"{name}@{tier}-mask.png"
                mask.save(stage / maskname)
                variants[str(tier)]["mask"] = maskname
    return variants


def prepare_audio(source, definition, destination):
    args = ["ffmpeg", "-nostdin", "-v", "error"]
    kind = definition["format"]
    if kind == "pcm-s8":
        args += ["-f", "s8", "-ar", str(definition["rate"]), "-ac", str(definition["channels"])]
    elif kind == "8svx":
        form, _ = chunks(source.read_bytes())
        if form != b"8SVX":
            raise ValueError("expected an IFF 8SVX sound")
        args += ["-f", "iff"]
    elif kind in ("wav", "flac"):
        args += ["-f", kind]
    else:
        raise ValueError("supply a lossless WAV/FLAC render for tracker inputs")
    codec = "pcm_s16le" if destination.suffix == ".wav" else "flac"
    subprocess.run(args + ["-i", str(source), "-map", "0:a:0", "-c:a", codec, str(destination)],
                   check=True)


def convert(recipe, destination, validator):
    spec = json.loads(recipe.read_text(encoding="utf-8"))
    root = recipe.parent
    if destination.exists():
        raise ValueError(f"output already exists: {destination}")
    if not isinstance(spec, dict) or any(not isinstance(spec.get(key, {}), dict)
                                        for key in ("images", "sounds", "music")):
        raise ValueError("resource groups must be objects")
    destination.parent.mkdir(parents=True, exist_ok=True)
    stage = Path(tempfile.mkdtemp(prefix=".assets-", dir=destination.parent))
    try:
        result = {"version": 1, "images": {}, "sounds": {}, "music": {}}
        for category in ("images", "sounds", "music"):
            for name, entry in spec.get(category, {}).items():
                try:
                    if not isinstance(entry, dict) or not ID.fullmatch(name):
                        raise ValueError("invalid resource identifier")
                    item = {k: v for k, v in entry.items()
                            if k not in ("sources", "source", "stems", "upscale")}
                    if category == "images":
                        item["variants"] = image_variants(root, stage, name, entry)
                    elif category == "sounds":
                        source = entry["source"]
                        filename = f"sound-{name}.wav"
                        prepare_audio(root / source["path"], source, stage / filename)
                        item["file"] = filename
                    else:
                        files = []
                        for index, source in enumerate(entry["stems"]):
                            filename = f"music-{name}-{index}.flac"
                            prepare_audio(root / source["path"], source, stage / filename)
                            files.append(filename)
                        if not files:
                            raise ValueError("a music cue needs at least one stem")
                        item["files"] = files
                    result[category][name] = item
                except (ValueError, TypeError, OSError, KeyError, struct.error, ImageCms.PyCMSError,
                        subprocess.SubprocessError) as error:
                    raise ValueError(f"{category}/{name} ({entry!r}): {error}") from error
        (stage / "manifest.json").write_text(json.dumps(result, indent=2) + "\n", encoding="utf-8")
        completed = subprocess.run([str(validator.resolve()), str(stage), "--check"])
        if completed.returncode:
            raise ValueError("package validation failed")
        os.rename(stage, destination)
    finally:
        if stage.exists():
            shutil.rmtree(stage)


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("recipe", type=Path)
    parser.add_argument("destination", type=Path)
    parser.add_argument("--validator", type=Path, required=True, help="asset_preview binary used before publishing output")
    args = parser.parse_args()
    try:
        convert(args.recipe, args.destination, args.validator)
    except (ValueError, OSError, TypeError) as error:
        parser.exit(1, f"{error}\n")


if __name__ == "__main__":
    main()

#!/usr/bin/env python3
"""Upscale art offline while keeping each animation frame independent."""

import argparse
from io import BytesIO
from pathlib import Path

import numpy as np
from PIL import Image, ImageCms

METHODS = ("pixel-art", "lanczos")
FACTORS = (2, 3, 4)


def scale_edges(source, factor):
    """Scale2x and Scale3x choose existing pixels along diagonal edges."""
    padded = np.pad(source, 1, mode="edge")
    a, b, c = padded[:-2, :-2], padded[:-2, 1:-1], padded[:-2, 2:]
    d, e, f = padded[1:-1, :-2], source, padded[1:-1, 2:]
    g, h, i = padded[2:, :-2], padded[2:, 1:-1], padded[2:, 2:]
    edge = (b != h) & (d != f)
    upper_left, upper_right = d == b, b == f
    lower_left, lower_right = d == h, h == f
    height, width = source.shape
    target = np.empty((height * factor, width * factor), dtype=source.dtype)

    if factor == 2:
        neighbors = ((d, upper_left), (f, upper_right),
                     (d, lower_left), (f, lower_right))
    else:
        neighbors = (
            (d, upper_left),
            (b, (upper_left & (e != c)) | (upper_right & (e != a))),
            (f, upper_right),
            (d, (upper_left & (e != g)) | (lower_left & (e != a))),
            (e, None),
            (f, (upper_right & (e != i)) | (lower_right & (e != c))),
            (d, lower_left),
            (h, (lower_left & (e != i)) | (lower_right & (e != g))),
            (f, lower_right),
        )
    for index, (neighbor, condition) in enumerate(neighbors):
        row, column = divmod(index, factor)
        cell = target[row::factor, column::factor]
        cell[:] = e
        if condition is not None:
            np.copyto(cell, neighbor, where=edge & condition)
    return target


def pixel_art(frame, mask, factor):
    if frame.mode == "P":
        source = np.asarray(frame)
        if mask is not None:
            source = source.astype(np.uint16) | (np.asarray(mask).astype(np.uint16) << 8)
    else:
        source = np.asarray(frame).copy().view(np.uint32).reshape(frame.height, frame.width)
        source[np.asarray(frame)[..., 3] == 0] = 0

    if factor == 4:
        enlarged = scale_edges(scale_edges(source, 2), 2)
    else:
        enlarged = scale_edges(source, factor)

    if frame.mode == "P":
        result = Image.fromarray(enlarged.astype(np.uint8))
        result.putpalette(frame.getpalette())
        opacity = Image.fromarray((enlarged >> 8).astype(np.uint8)) if mask is not None else None
        return result, opacity
    return Image.fromarray(enlarged.view(np.uint8).reshape(*enlarged.shape, 4)), None


def lanczos(frame, size):
    """Filter linear RGB weighted by alpha, then return straight sRGB."""
    values = np.asarray(frame, dtype=np.float32) / 255.0
    alpha = values[..., 3]
    rgb = values[..., :3]
    linear = np.where(rgb <= .04045, rgb / 12.92, ((rgb + .055) / 1.055) ** 2.4)

    def filtered(channel):
        return np.asarray(Image.fromarray(channel).resize(size, Image.Resampling.LANCZOS))

    output_alpha = np.clip(filtered(alpha), 0, 1)
    output = np.empty((size[1], size[0], 4), dtype=np.uint8)
    for channel in range(3):
        weighted = filtered(linear[..., channel] * alpha)
        straight = np.divide(weighted, output_alpha, out=np.zeros_like(weighted),
                             where=output_alpha >= 0.5 / 255)
        straight = np.clip(straight, 0, 1)
        srgb = np.where(straight <= .0031308, 12.92 * straight, 1.055 * straight ** (1 / 2.4) - .055)
        output[..., channel] = np.rint(srgb * 255).astype(np.uint8)
    output[..., 3] = np.rint(output_alpha * 255).astype(np.uint8)
    return Image.fromarray(output)


def upscale(image, factor, method, grid=(1, 1), mask=None):
    if type(factor) is not int or factor not in FACTORS or method not in METHODS:
        raise ValueError("expected pixel-art or lanczos at 2x, 3x or 4x")
    columns, rows = grid
    if (type(columns) is not int or type(rows) is not int or columns < 1 or rows < 1
            or image.width % columns or image.height % rows):
        raise ValueError("image size must be divisible by the positive sprite grid")
    size = (image.width * factor, image.height * factor)
    if max(size) > 8192:
        raise ValueError("upscaled image exceeds the 8192 pixel package limit")
    profile = image.info.get("icc_profile")
    transparency = image.info.get("transparency")
    if method == "lanczos":
        if image.mode == "P" or mask is not None:
            raise ValueError("use pixel-art to preserve palette indices or independent masks")
        image = image.convert("RGBA")
        if profile:
            image = ImageCms.profileToProfile(image, BytesIO(profile), ImageCms.createProfile("sRGB"),
                                              outputMode="RGBA")
            profile = image.info.get("icc_profile")
    elif image.mode != "P":
        image = image.convert("RGBA")
    if mask is not None and (mask.mode != "L" or mask.size != image.size):
        raise ValueError("opacity mask must be grayscale and match the image")

    target = Image.new(image.mode, size)
    output_mask = Image.new("L", size) if mask is not None else None
    if image.mode == "P":
        target.putpalette(image.getpalette())
        if transparency is not None:
            target.info["transparency"] = transparency
    if profile:
        target.info["icc_profile"] = profile
    width, height = image.width // columns, image.height // rows
    for row in range(rows):
        for column in range(columns):
            left, top = column * width, row * height
            bounds = (left, top, left + width, top + height)
            frame = image.crop(bounds)
            offset = (left * factor, top * factor)
            if method == "lanczos":
                target.paste(lanczos(frame, (width * factor, height * factor)), offset)
            else:
                enlarged, opacity = pixel_art(frame, mask.crop(bounds) if mask is not None else None,
                                              factor)
                target.paste(enlarged, offset)
                if opacity is not None:
                    output_mask.paste(opacity, offset)
    return target, output_mask


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("source", type=Path, help="still PNG")
    parser.add_argument("destination", type=Path)
    parser.add_argument("--method", choices=METHODS, required=True)
    parser.add_argument("--factor", type=int, choices=FACTORS, required=True)
    parser.add_argument("--grid", type=int, nargs=2, metavar=("COLUMNS", "ROWS"), default=(1, 1))
    args = parser.parse_args()
    try:
        if args.destination.suffix.lower() != ".png":
            raise ValueError("destination must have a .png extension")
        with Image.open(args.source) as image:
            if image.format != "PNG" or getattr(image, "is_animated", False):
                raise ValueError("expected a still PNG")
            result, _ = upscale(image, args.factor, args.method, args.grid)
        with args.destination.open("xb") as output:
            result.save(output, format="PNG")
    except (OSError, ValueError, ImageCms.PyCMSError) as error:
        parser.exit(1, f"{args.source}: {error}\n")


if __name__ == "__main__":
    main()

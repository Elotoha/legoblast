#!/usr/bin/env python3
"""Fetch pinned Android build dependencies and stage the original game assets."""

import hashlib
from pathlib import Path
import shutil
import struct
import subprocess
import tarfile
import zlib
from tempfile import TemporaryDirectory

HERE = Path(__file__).resolve().parent
ROOT = HERE.parent.parent
GENERATED = HERE / "generated"
SDL = "SDL3-3.2.30"
DR_COMMIT = "e381981afa52800b9a3864df548353ff67252fbc"
ORIGINAL_BINARY = (
    "LEGO_SPRITES.DAT", "bigbloc.dat", "timer1.dat", "Jauge.Dat", "JaugeTeams.Dat", "bois.raw",
    "PODIUM.RAW", "Podium.col", "lego_feelings.dat", "proxima.crp", "Proxima.col",
    "MENU_CREDITS.RAW", "MENU_Credits.col", "MENU_Bonus2.raw", "MENU_Bonus.col", "statsblocs.dat",
    "MENUA.raw", "MENUA.col", "MENUB.raw", "MENUB.col", "mainmenubox.dat", "tinytxt8.font", "aachen13.font",
)
SOURCE_BINARY = (
    "Lego_Blocs.dat", "bobs_nus22.col", "Lego_Sprites.col", "Lego_SpritesIndex.dat",
    "Lego_Sprites8.dat", "Lego_SpritesIndex8.dat", "Mec8_normal.col",
)


def fetch(url, filename, expected_sha256):
    path = GENERATED / filename
    if not path.is_file() or hashlib.sha256(path.read_bytes()).hexdigest() != expected_sha256:
        temporary = path.with_suffix(path.suffix + ".tmp")
        subprocess.run(["curl", "--fail", "--silent", "--show-error", "--location", "--retry", "2",
                        url, "-o", str(temporary)], check=True)
        if hashlib.sha256(temporary.read_bytes()).hexdigest() != expected_sha256:
            raise RuntimeError(f"Invalid checksum for {filename}")
        temporary.replace(path)
    return path


def copy_files(source, destination, names):
    for name in names:
        shutil.copyfile(source / name, destination / name)


def stage_assets():
    source = ROOT / "amiga/src"
    release = ROOT / "amiga/release_aminet/LegoBlast.lha"
    staging = GENERATED / "assets"
    with TemporaryDirectory() as scratch_name:
        scratch = Path(scratch_name)
        if shutil.which("bsdtar"):
            extract = ["bsdtar", "-xf", str(release)]
        elif lha := shutil.which("lhasa") or shutil.which("lha"):
            extract = [lha, "x", str(release)]
        else:
            raise RuntimeError("Install bsdtar or lhasa to extract the original game release")
        subprocess.run(extract, cwd=scratch, check=True, stdout=subprocess.DEVNULL)
        original = {p.name.casefold(): p for p in (scratch / "binary").iterdir()}
        shutil.rmtree(staging, ignore_errors=True)
        binary = staging / "data/binary"
        binary.mkdir(parents=True)
        for name in ORIGINAL_BINARY:
            shutil.copyfile(original[name.casefold()], binary / name)
        for file in original.values():
            if file.name.casefold().startswith("barrej") and file.suffix.casefold() == ".raw":
                shutil.copyfile(file, binary / file.name)
        copy_files(source / "binary", binary, SOURCE_BINARY)
        for pattern in ("Lego_Level*.dat", "Lego_Flam_*.Dat"):
            copy_files(source / "binary", binary, [p.name for p in (source / "binary").glob(pattern)])
        worlds = staging / "data/LEGO_WORLDS"
        worlds.mkdir()
        copy_files(source / "LEGO_WORLDS", worlds, [p.name for p in (source / "LEGO_WORLDS").glob("*.col")])
        audio = staging / "data/audio"
        audio.mkdir()
        for pattern in ("*.wav", "*.flac"):
            copy_files(ROOT / "port/legoblast/audio", audio,
                       [p.name for p in (ROOT / "port/legoblast/audio").glob(pattern)])

    manifest = hashlib.sha256()
    for file in sorted(staging.rglob("*")):
        if file.is_file():
            manifest.update(str(file.relative_to(staging)).encode("utf-8"))
            manifest.update(hashlib.sha256(file.read_bytes()).digest())
    (staging / "data.id").write_text(manifest.hexdigest() + "\n", encoding="ascii")


def stage_icon():
    binary = GENERATED / "assets/data/binary"
    heads = (binary / "statsblocs.dat").read_bytes()
    palette = (binary / "Podium.col").read_bytes()
    plane_size = 3 * 122

    # The first nine rows of the first portrait contain the face. Plane 0
    # is its mask, and planes 1–7 index the same palette as the podium.
    face = []
    for y in range(9):
        row = []
        for x in range(3, 14):
            offset = 3 * y + x // 8
            mask = 128 >> (x % 8)
            index = sum(1 << plane for plane in range(7)
                        if heads[(plane + 1) * plane_size + offset] & mask)
            row.append(palette[index * 4 + 1:index * 4 + 4] + b"\xff" if heads[offset] & mask else None)
        face.append(row)

    def write_icon(relative, size, zoom, background):
        pixels = bytearray(background * size * size)
        left = (size - len(face[0]) * zoom) // 2
        top = (size - len(face) * zoom) // 2
        for y, row in enumerate(face):
            for x, color in enumerate(row):
                if color is None:
                    continue
                for dy in range(zoom):
                    start = 4 * ((top + y * zoom + dy) * size + left + x * zoom)
                    pixels[start:start + 4 * zoom] = color * zoom

        def chunk(kind, data):
            return (struct.pack(">I", len(data)) + kind + data +
                    struct.pack(">I", zlib.crc32(kind + data)))

        scanlines = b"".join(b"\0" + pixels[row:row + 4 * size]
                             for row in range(0, len(pixels), 4 * size))
        png = (b"\x89PNG\r\n\x1a\n" +
               chunk(b"IHDR", struct.pack(">IIBBBBB", size, size, 8, 6, 0, 0, 0)) +
               chunk(b"IDAT", zlib.compress(scanlines)) + chunk(b"IEND", b""))
        path = GENERATED / "res" / relative
        path.parent.mkdir(parents=True, exist_ok=True)
        path.write_bytes(png)

    write_icon("drawable-nodpi/legoblast_head.png", 108, 5, b"\0" * 4)
    write_icon("mipmap-xxxhdpi/legoblast.png", 192, 12, b"\0\0\0\xff")

def main():
    GENERATED.mkdir(exist_ok=True)
    sdl = fetch(f"https://github.com/libsdl-org/SDL/releases/download/release-3.2.30/{SDL}.tar.gz",
                SDL + ".tar.gz", "4c3b09330d866dc52eb65b66259a6684ad387252ca8c57901b3a2b534eb42e3d")
    if not (GENERATED / SDL / "CMakeLists.txt").is_file():
        with tarfile.open(sdl) as archive:
            archive.extractall(GENERATED, filter="data")
    fetch(f"https://raw.githubusercontent.com/mackron/dr_libs/{DR_COMMIT}/dr_flac.h",
          "dr_flac.h", "bd569c910a7c465e481fd50af84e2871e81e2154e30ac510d98f953cc0d5a546")
    stage_assets()
    stage_icon()


if __name__ == "__main__":
    main()

#!/usr/bin/env python3
"""Export the original sample bytes and P61 tracks to PCM WAV and FLAC."""

import argparse
import struct
import subprocess
import tempfile
import wave
from pathlib import Path


def export_samples(source, destination):
    samples = {path.name.casefold(): path for path in (source / "sons").iterdir() if path.is_file()}
    for line in (source / "samples.def").read_text(encoding="latin-1").splitlines():
        if line.startswith("*"):
            break
        label, data = line.split(":", 1)
        name, period = data.split(",", 1)
        number = int(label.split("/", 1)[0])
        pcm = samples[name.casefold()].read_bytes()
        # ChargeOneSon passes whole words directly to Paula, including any IFF header.
        pcm = pcm[: len(pcm) - len(pcm) % 2]
        signed = struct.unpack(f"{len(pcm)}b", pcm)
        with wave.open(str(destination / f"sample-{number:02}.wav"), "wb") as output:
            output.setparams((1, 2, round(3546895 / int(period)), 0, "NONE", "not compressed"))
            output.writeframes(struct.pack(f"<{len(signed)}h", *(sample * 256 for sample in signed)))


def render_music(module, destination, channel_options):
    with tempfile.TemporaryDirectory() as scratch:
        wav = Path(scratch) / "music.wav"
        args = ["xmp", "--norc", "--nocmd", "-q", "-e", "protracker", "-A",
                "-p", "100", "-P", "100", "-f", "48000", "-b", "16"]
        subprocess.run(args + channel_options + ["-o", str(wav), str(module)], check=True)
        subprocess.run(["ffmpeg", "-nostdin", "-v", "error", "-y", "-i", str(wav),
                        "-c:a", "flac", str(destination)], check=True)


def export_menu_voices(source, destination):
    module = source / "mods" / "Mod_Menu.P6"
    for channel in range(4):
        render_music(module, destination / f"Mod_Menu_Voice{channel + 1}.flac", ["-S", str(channel)])


def export_music(source, destination):
    for module in sorted((source / "mods").glob("Mod_*.P6")):
        # LaunchZik reserves Paula channel 3 for effects. xmp uses zero-based channels.
        channels = ["-M", "3"] if "Game" in module.stem else []
        render_music(module, destination / f"{module.stem}.flac", channels)
    export_menu_voices(source, destination)


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("source", type=Path, help="path to amiga/src")
    parser.add_argument("destination", type=Path)
    parser.add_argument("--samples-only", action="store_true")
    args = parser.parse_args()
    args.destination.mkdir(parents=True, exist_ok=True)
    export_samples(args.source, args.destination)
    if not args.samples_only:
        export_music(args.source, args.destination)


if __name__ == "__main__":
    main()

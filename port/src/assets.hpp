#pragma once

#include <cstdint>
#include <filesystem>
#include <map>
#include <string>
#include <vector>

struct Size {
    int w;
    int h;
};

struct Point {
    int x;
    int y;
};

struct PaletteCycle {
    unsigned first;
    unsigned last;
    unsigned ticks;
    int direction;
};

struct ImagePixels {
    Size size;
    std::vector<std::uint8_t> pixels;
    std::vector<std::uint8_t> palette;
    std::vector<std::uint8_t> mask;

    std::vector<std::uint8_t> rgba(std::uint64_t tick,
                                   const std::vector<PaletteCycle>& cycles) const;
};

struct ImageAsset {
    Size logicalSize;
    Point anchor;
    unsigned columns;
    unsigned rows;
    unsigned frameTicks;
    std::vector<PaletteCycle> cycles;
    std::map<int, ImagePixels> variants;

    int tier(double scale) const;
};

struct AudioClip {
    unsigned rate;
    unsigned channels;
    std::vector<float> samples;

    std::size_t frames() const { return samples.size() / channels; }
};

struct Sound {
    AudioClip clip;
    int priority;
    float volume;
};

struct Music {
    std::vector<AudioClip> stems;
    std::size_t loopStart;
    std::size_t loopEnd;
    float volume;
};

struct Assets {
    std::map<std::string, ImageAsset> images;
    std::map<std::string, Sound> sounds;
    std::map<std::string, Music> music;
};

Assets loadAssets(const std::filesystem::path& package);

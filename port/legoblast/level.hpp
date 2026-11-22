#pragma once
#include <array>
#include <cstdint>
#include <filesystem>
#include <span>
#include <string>
#include <vector>

namespace legoblast {
inline constexpr int Width = 19;
inline constexpr int Height = 15;
inline constexpr int TileSize = 16;
using Bytes = std::vector<std::uint8_t>;

struct Point {
    std::int16_t x;
    std::int16_t y;
};
struct Teleporter {
    Point from;
    Point to;
};
struct Level {
    std::string name;
    std::uint32_t warningTime, totalTime;
    std::int16_t minX, minY, maxX, maxY, fillCount;
    std::uint16_t speed, bombs, reach, push;
    std::array<Point, 8> starts;
    std::uint16_t palette, flamePalette;
    std::array<std::uint16_t, 30> blocks;
    std::uint16_t bombTime, autoFire;
    std::array<std::uint16_t, 18> reserved;
    std::array<std::uint16_t, 30> bonusWeights;
    std::array<std::uint8_t, Width * Height> tiles;
    std::vector<Teleporter> teleporters;
};
struct RandomState {
    std::uint32_t d0, d1;
    void init(std::uint32_t videoPosition);
    std::uint32_t next();
    std::uint16_t test(std::int32_t threshold);
};

Bytes readBytes(const std::filesystem::path& path);
Level decodeLevel(std::span<const std::uint8_t> bytes);
Level loadLevel(const std::filesystem::path& path);
Bytes readLevelPalette(const std::filesystem::path& sourceRoot, std::uint16_t palette);
void dynaInit(Level& level, RandomState& state);
std::array<std::uint8_t, 257> makeBonusTable(const Level& level);
struct LevelRandoms {
    std::vector<std::uint8_t> teleporterFrames;
    std::array<std::uint8_t, Width * Height> hiddenBonuses{};
};
LevelRandoms initialLevelRandoms(const Level& level, RandomState& state);
Bytes staticLevelRgb(const Level& level, std::span<const std::uint8_t> bank,
                     std::span<const std::uint8_t> palette);
}

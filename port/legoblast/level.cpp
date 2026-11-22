#include "level.hpp"

#include <algorithm>
#include <bit>
#include <fstream>
#include <stdexcept>

namespace legoblast {
namespace {
class Reader {
public:
    explicit Reader(std::span<const std::uint8_t> bytes) : bytes_(bytes) {}
    std::uint8_t byte() {
        if (position_ >= bytes_.size())
            throw std::runtime_error("truncated level");
        return bytes_[position_++];
    }
    std::uint16_t word() {
        const auto high = byte();
        return std::uint16_t(high << 8 | byte());
    }
    std::int16_t signedWord() { return std::bit_cast<std::int16_t>(word()); }
    std::uint32_t longWord() {
        const auto high = word();
        return std::uint32_t(high) << 16 | word();
    }
    Point point() { return {signedWord(), signedWord()}; }
    std::size_t position() const { return position_; }
private:
    std::span<const std::uint8_t> bytes_;
    std::size_t position_ = 0;
};

bool indestructible(std::uint8_t tile) { return tile == 1 || tile == 3; }

constexpr unsigned BlockBytes = 2 * TileSize * 7;
constexpr unsigned EmptyBlock = 148;
constexpr unsigned TeleporterBlockSlot = 20;
constexpr std::array<unsigned, 24> BonusIdx{148, 60, 30, 55, 40, 40, 40, 40, 40, 40,
                                            70, 75, 40, 40, 40, 95, 65, 90, 40, 190,
                                            285, 290, 85, 40};
constexpr std::array<unsigned, 16> PipeIdx{195, 195, 195, 196, 195, 197, 198, 199,
                                           195, 200, 201, 202, 203, 204, 205, 206};

std::uint16_t blockWord(std::span<const std::uint8_t> bank, unsigned block, int y, int plane) {
    const auto offset = block * BlockBytes + (y * 7 + plane) * 2;
    if (offset + 2 > bank.size())
        throw std::runtime_error("block image index outside Lego_Blocs.dat");
    return std::uint16_t(bank[offset] << 8 | bank[offset + 1]);
}

unsigned colorAt(std::span<const std::uint8_t> bank, unsigned front, unsigned back,
                 int x, int y, bool composite) {
    unsigned color = 0;
    const unsigned bit = 1u << (15 - x);
    const bool useBackground = composite && (blockWord(bank, front, y, 0) & bit);
    for (int plane = 1; plane <= 6; ++plane) {
        auto value = blockWord(bank, front, y, plane);
        if (useBackground)
            value |= blockWord(bank, back, y, plane);
        if (value & bit)
            color |= 1u << (plane - 1);
    }
    return color;
}
}

Bytes readBytes(const std::filesystem::path& path) {
    std::ifstream input(path, std::ios::binary | std::ios::ate);
    if (!input)
        throw std::runtime_error("cannot open " + path.string());
    const auto end = input.tellg();
    if (end < 0 || end > 16 * 1024 * 1024)
        throw std::runtime_error("invalid file size: " + path.string());
    Bytes data(static_cast<std::size_t>(end));
    input.seekg(0);
    if (!input.read(reinterpret_cast<char*>(data.data()), static_cast<std::streamsize>(data.size())))
        throw std::runtime_error("cannot read " + path.string());
    return data;
}

Bytes readLevelPalette(const std::filesystem::path& sourceRoot, std::uint16_t palette) {
    constexpr std::array<const char*, 6> files{
        "binary/bobs_nus22.col", "LEGO_WORLDS/Alien_World.col",
        "LEGO_WORLDS/Antique_World3.col", "LEGO_WORLDS/Tronic_World4.col",
        "LEGO_WORLDS/Wood_World.col", "LEGO_WORLDS/Dyna_World.col",
    };
    return readBytes(sourceRoot / files.at(palette));
}

// Level_* declarations in lego17.asm and Teleporteurs in Levels.i.
Level decodeLevel(std::span<const std::uint8_t> bytes) {
    Reader reader(bytes);
    Level level{};
    const auto nameOffset = reader.longWord();
    level.warningTime = reader.longWord();
    level.totalTime = reader.longWord();
    level.minX = reader.signedWord();
    level.minY = reader.signedWord();
    level.maxX = reader.signedWord();
    level.maxY = reader.signedWord();
    level.fillCount = reader.signedWord();
    level.speed = reader.word();
    level.bombs = reader.word();
    level.reach = reader.word();
    level.push = reader.word();
    for (auto& start : level.starts)
        start = reader.point();
    level.palette = reader.word();
    level.flamePalette = reader.word();
    for (auto& block : level.blocks)
        block = reader.word();
    level.bombTime = reader.word();
    level.autoFire = reader.word();
    for (auto& value : level.reserved)
        value = reader.word();
    for (auto& weight : level.bonusWeights)
        weight = reader.word();
    for (auto& tile : level.tiles)
        tile = reader.byte();
    reader.byte(); // Level_Nothing.
    for (;;) {
        const auto x = reader.signedWord();
        if (x < 0)
            break;
        const Point source{x, reader.signedWord()};
        level.teleporters.push_back({source, reader.point()});
    }
    if (nameOffset < reader.position() || nameOffset >= bytes.size())
        throw std::runtime_error("invalid level name offset");
    const auto name = bytes.subspan(nameOffset);
    const auto end = std::ranges::find(name, 0);
    if (end == name.end())
        throw std::runtime_error("unterminated level name");
    level.name.assign(name.begin(), end);
    return level;
}

Level loadLevel(const std::filesystem::path& path) {
    try {
        return decodeLevel(readBytes(path));
    } catch (const std::runtime_error& error) {
        throw std::runtime_error(path.string() + ": " + error.what());
    }
}

// rnd.i. MULS.L keeps the low 32 bits, SUB.B preserves D1's upper 24 bits.
std::uint32_t RandomState::next() {
    d0 = (std::rotr(d0, int(d1 & 31u)) + 49877u) * 271u;
    d1 = (d1 & 0xffffff00u) | ((d1 - d0) & 255u);
    return d0;
}

void RandomState::init(std::uint32_t videoPosition) {
    d0 += videoPosition;
    d1 ^= videoPosition;
}

std::uint16_t RandomState::test(std::int32_t threshold) {
    const auto sample = static_cast<std::uint16_t>(next());
    return threshold < sample ? sample : 0;
}

// Levels.i:DynaInit. CMP.W/BLE compares the signed low word, not an unsigned roll.
void dynaInit(Level& level, RandomState& state) {
    for (auto& tile : level.tiles)
        if (tile < 128 && !indestructible(tile))
            tile = std::bit_cast<std::int16_t>(static_cast<std::uint16_t>(state.next())) > 50 ? 2 : 0;

    constexpr std::array<Point, 5> cross{{{0, 0}, {-1, 0}, {1, 0}, {0, -1}, {0, 1}}};
    for (unsigned i = 0; i < 6; ++i) {
        for (const auto delta : cross) {
            const auto point = level.starts[i];
            const int offset = (point.y + delta.y) * Width + point.x + delta.x;
            if (offset < 0 || offset >= Width * Height)
                throw std::runtime_error("DynaInit spawn outside the level");
            if (!indestructible(level.tiles[offset]))
                level.tiles[offset] = 0;
        }
    }
}

// Levels.i:MakeRndCorresp. The 68k sums into a word and leaves the rounded remainder empty.
std::array<std::uint8_t, 257> makeBonusTable(const Level& level) {
    std::array<std::uint8_t, 257> table{};
    constexpr unsigned entries = 24;
    std::uint16_t total = 0;
    for (unsigned i = 0; i < entries; ++i)
        total = static_cast<std::uint16_t>(total + level.bonusWeights[i]);
    if (!total)
        return table;
    unsigned offset = 0;
    for (unsigned i = 0; i < entries; ++i) {
        const auto weight = std::bit_cast<std::int16_t>(level.bonusWeights[i]);
        if (weight < 0)
            throw std::runtime_error("negative bonus weight");
        const auto count = unsigned(weight) * 256 / total;
        if (count > table.size() - offset)
            throw std::runtime_error("bonus table would overflow");
        std::fill_n(table.begin() + offset, count, static_cast<std::uint8_t>(i));
        offset += count;
    }
    return table;
}

// Levels.i: Teleporteurs runs before the row-major destructible block scan.
LevelRandoms initialLevelRandoms(const Level& level, RandomState& state) {
    LevelRandoms result;
    const auto table = makeBonusTable(level);
    result.teleporterFrames.reserve(level.teleporters.size());
    for (std::size_t i = 0; i < level.teleporters.size(); ++i)
        result.teleporterFrames.push_back(static_cast<std::uint8_t>(135 + state.next() % 8));
    for (std::size_t i = 0; i < level.tiles.size(); ++i)
        if (level.tiles[i] == 2)
            result.hiddenBonuses[i] = table[(state.next() >> 8) & 255u];
    return result;
}

// The initial board in Levels.i, using the interleaved mask and six bitplanes in Grafx.i.
unsigned bonusImage(unsigned bonus) { return BonusIdx.at(bonus); }

Bytes staticLevelIndices(const Level& level, std::span<const std::uint8_t> bank) {
    if (bank.empty() || bank.size() % BlockBytes)
        throw std::runtime_error("invalid block bank");
    std::array<bool, Width * Height> tele{};
    for (const auto& entry : level.teleporters) {
        const int x = entry.from.x / 2;
        const int y = entry.from.y / 2;
        if (x < 0 || x >= Width || y < 0 || y >= Height)
            continue;
        if (entry.from.x % 2 == 0 && entry.from.y % 2 == 0)
            tele[y * Width + x] = entry.to.x != 0 || entry.to.y != 0;
    }

    Bytes indexed(Width * Height * TileSize * TileSize);
    for (int cell = 0; cell < Width * Height; ++cell) {
        const auto tile = level.tiles[cell];
        const bool black = tile == 255;
        const bool slab = (tile >= 4 && tile <= 7) || (tile >= 12 && tile <= 16);
        const auto background = level.blocks[0];
        unsigned front = EmptyBlock;
        if (!black && tile != 0 && !slab) {
            if (tile & 64)
                front = BonusIdx.at(tile - 64);
            else if (tile & 32)
                front = PipeIdx.at(tile - 32);
            else
                front = level.blocks.at(tile);
        }
        for (int y = 0; y < TileSize; ++y) {
            for (int x = 0; x < TileSize; ++x) {
                // A slab replaces the floor layer after the teleporter layer was drawn.
                const unsigned backColor = slab ? colorAt(bank, level.blocks[tile], background, x, y, true) :
                    tele[cell] ? colorAt(bank, level.blocks[TeleporterBlockSlot], background, x, y, true) :
                    colorAt(bank, background, 0, x, y, false);
                const bool seeFloor = !black && (blockWord(bank, front, y, 0) & (1u << (15 - x)));
                const auto value = colorAt(bank, front, 0, x, y, false) | (seeFloor ? backColor : 0);
                const auto pixel = (cell / Width * TileSize + y) * Width * TileSize +
                                   cell % Width * TileSize + x;
                indexed[pixel] = static_cast<std::uint8_t>(value);
            }
        }
    }
    return indexed;
}

Bytes levelRgb(std::span<const std::uint8_t> indexed, std::span<const std::uint8_t> palette) {
    if (palette.size() != 64 * 4)
        throw std::runtime_error("invalid 0RGB level palette");
    Bytes rgb(indexed.size() * 3);
    for (std::size_t pixel = 0; pixel < indexed.size(); ++pixel)
        std::copy_n(palette.begin() + indexed[pixel] * 4 + 1, 3, rgb.begin() + pixel * 3);
    return rgb;
}

Bytes staticLevelRgb(const Level& level, std::span<const std::uint8_t> bank,
                     std::span<const std::uint8_t> palette) {
    return levelRgb(staticLevelIndices(level, bank), palette);
}

// TraceWithFont / TraceLittle: mask the six underlying planes, then OR the image.
void drawLevelPattern(Bytes& board, int x, int y, unsigned width, unsigned frame,
                      std::span<const std::uint8_t> bank) {
    if (width != 8 && width != 16)
        throw std::runtime_error("unsupported planar width");
    const unsigned stride = width / 8 * 7;
    const std::size_t base = std::size_t(frame) * stride * width;
    if (base + stride * width > bank.size())
        throw std::runtime_error("invalid planar frame index");
    for (unsigned py = 0; py < width; ++py) {
        for (unsigned px = 0; px < width; ++px) {
            const int screenX = x + static_cast<int>(px);
            const int screenY = y + static_cast<int>(py);
            if (screenX < 0 || screenY < 0 || screenX >= Width * TileSize || screenY >= Height * TileSize)
                continue;
            const auto offset = base + py * stride + px / 8;
            auto& result = board.at(screenY * Width * TileSize + screenX);
            const unsigned bit = 0x80u >> (px & 7);
            if (!(bank[offset] & bit))
                result = 0;
            for (unsigned plane = 0; plane < 6; ++plane)
                if (bank[offset + (plane + 1) * (width / 8)] & bit)
                    result |= static_cast<std::uint8_t>(1u << plane);
        }
    }
}
}

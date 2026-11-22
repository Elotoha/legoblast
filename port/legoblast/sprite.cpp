#include "sprite.hpp"

#include <array>
#include <stdexcept>

namespace legoblast {
namespace {
constexpr unsigned HardwareSpriteBytes = 104;
unsigned readBig(std::span<const std::uint8_t> bytes, std::size_t offset, unsigned width) {
    if (offset > bytes.size() || width > bytes.size() - offset)
        throw std::runtime_error("original sprite bank or index is truncated");
    unsigned value = 0;
    for (unsigned i = 0; i < width; ++i)
        value = value << 8 | bytes[offset + i];
    return value;
}

Bytes decodeSprite(std::span<const std::uint8_t> sprites, std::span<const unsigned> offsets,
                   std::span<const unsigned> palette) {
    Bytes rgba(SpriteWidth * SpriteHeight * 4);
    for (int y = 0; y < SpriteHeight; ++y) {
        const unsigned line = 4 + y * 4; // skip SPRxPOS and SPRxCTL.
        std::array<unsigned, 4> planes{};
        for (std::size_t i = 0; i < offsets.size(); ++i) {
            const auto source = std::size_t(offsets[i]) + line;
            planes[2 * i] = readBig(sprites, source, 2);
            planes[2 * i + 1] = readBig(sprites, source + 2, 2);
        }
        for (int x = 0; x < SpriteWidth; ++x) {
            unsigned color = 0;
            for (unsigned plane = 0; plane < planes.size(); ++plane)
                color |= ((planes[plane] >> (15 - x)) & 1) << plane;
            if (color) {
                const auto rgb = palette[color];
                const auto at = (y * SpriteWidth + x) * 4;
                rgba[at] = (rgb >> 16) & 255;
                rgba[at + 1] = (rgb >> 8) & 255;
                rgba[at + 2] = rgb & 255;
                rgba[at + 3] = 255;
            }
        }
    }
    return rgba;
}
}

Bytes attachedSprite(std::span<const std::uint8_t> sprites, std::span<const std::uint8_t> indices,
                     std::span<const std::uint8_t> palette, unsigned frame) {
    // BPLCON4 $0055 selects bank 5. SUITEO loads it starting at file entry 16.
    std::array<unsigned, 16> colors{};
    for (std::size_t i = 1; i < colors.size(); ++i)
        colors[i] = readBig(palette, (16 + i) * 4, 4);
    const auto index = std::size_t(frame) * 8;
    std::array<unsigned, 2> offsets{};
    if (indices.size() == 4 * 199 * 8 && sprites.size() == 4 * 225 * 2 * HardwareSpriteBytes &&
        frame >= 4 * 199 && frame < 4 * 225) {
        // The shipped index has 199 entries per player, in linear order, while
        // the shipped attached bank actually has 225 sequential frames per player.
        offsets = {2 * frame * HardwareSpriteBytes, (2 * frame + 1) * HardwareSpriteBytes};
    } else {
        offsets = {readBig(indices, index, 4), readBig(indices, index + 4, 4)};
    }
    return decodeSprite(sprites, offsets, colors);
}

Bytes independentSprite(std::span<const std::uint8_t> sprites, std::span<const std::uint8_t> indices,
                        std::span<const std::uint8_t> palette, unsigned player, unsigned frame) {
    // Mec8_normal.col holds the high and low RGB nibble words for each player.
    std::array<unsigned, 4> colors{};
    for (std::size_t i = 1; i < colors.size(); ++i) {
        const auto offset = player * 16 + i * 4;
        const auto high = readBig(palette, offset, 2);
        const auto low = readBig(palette, offset + 2, 2);
        for (unsigned channel = 0; channel < 3; ++channel) {
            const auto shift = channel * 4;
            const auto component = ((high >> shift & 15) << 4) | (low >> shift & 15);
            colors[i] |= component << (channel * 8);
        }
    }
    constexpr unsigned FramesPerPlayer = 199;
    // From 190 onwards the independent bank contains the older result artwork.
    if (frame >= 190)
        frame = 33;
    const std::array offsets{readBig(indices, (player * FramesPerPlayer + frame) * 4, 4)};
    return decodeSprite(sprites, offsets, colors);
}
}

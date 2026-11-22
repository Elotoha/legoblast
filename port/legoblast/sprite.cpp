#include "sprite.hpp"

#include <array>
#include <stdexcept>

namespace legoblast {
namespace {
unsigned readBig(std::span<const std::uint8_t> bytes, std::size_t offset, unsigned width) {
    if (offset > bytes.size() || width > bytes.size() - offset)
        throw std::runtime_error("original sprite bank or index is truncated");
    unsigned value = 0;
    for (unsigned i = 0; i < width; ++i)
        value = value << 8 | bytes[offset + i];
    return value;
}

// CalcMot selects two attached two-plane sprites through AdrIndex.
} // namespace

Bytes attachedSprite(std::span<const std::uint8_t> sprites, std::span<const std::uint8_t> indices,
                     std::span<const std::uint8_t> palette, unsigned frame) {
    // SUITEO loads this file after 64 playfield entries. BPLCON4 $0055 selects bank
    // 5 (registers 80-95); the 16-entry bank begins at file entry 80 - 64.
    constexpr unsigned bankFileOffset = 16;
    const auto index = static_cast<std::size_t>(frame) * 8;
    const auto lower = readBig(indices, index, 4);
    const auto upper = readBig(indices, index + 4, 4);
    Bytes rgba(SpriteWidth * SpriteHeight * 4);
    for (int y = 0; y < SpriteHeight; ++y) {
        const unsigned line = 4 + y * 4; // skip SPRxPOS and SPRxCTL.
        const std::array<unsigned, 4> planes{
            readBig(sprites, std::size_t(lower) + line, 2), readBig(sprites, std::size_t(lower) + line + 2, 2),
            readBig(sprites, std::size_t(upper) + line, 2), readBig(sprites, std::size_t(upper) + line + 2, 2),
        };
        for (int x = 0; x < SpriteWidth; ++x) {
            unsigned color = 0;
            for (unsigned plane = 0; plane < planes.size(); ++plane)
                color |= ((planes[plane] >> (15 - x)) & 1) << plane;
            if (color) {
                const auto rgb = readBig(palette, (bankFileOffset + color) * 4, 4);
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

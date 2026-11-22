#pragma once

#include "level.hpp"

namespace legoblast {
inline constexpr int SpriteWidth = 16;
inline constexpr int SpriteHeight = 24;

// Decodes the four-player mode's attached sprites and their AGA palette.
Bytes attachedSprite(std::span<const std::uint8_t> sprites, std::span<const std::uint8_t> indices,
                     std::span<const std::uint8_t> palette, unsigned frame);
Bytes independentSprite(std::span<const std::uint8_t> sprites, std::span<const std::uint8_t> indices,
                        std::span<const std::uint8_t> palette, unsigned player, unsigned frame);
}

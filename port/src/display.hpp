#pragma once

#include "assets.hpp"

#include <SDL3/SDL.h>

#include <chrono>
#include <memory>

inline constexpr Size Canvas{320, 256};
inline constexpr auto TickDuration = std::chrono::milliseconds(20);

struct Viewport {
    double scale;
    double x;
    double y;

    SDL_FRect place(Point point, Size logical, Point anchor) const;
};

Viewport viewport(Size output);

class SpriteTexture {
public:
    void draw(SDL_Renderer* renderer, const ImageAsset& asset, const Viewport& view,
              Point position, std::uint64_t tick);

private:
    std::unique_ptr<SDL_Texture, decltype(&SDL_DestroyTexture)> texture_{nullptr, SDL_DestroyTexture};
    const ImagePixels* pixels_{};
    std::vector<std::uint64_t> phase_;
};

#include "display.hpp"

#include <algorithm>
#include <cmath>
#include <stdexcept>

Viewport viewport(Size output) {
    if (output.w <= 0 || output.h <= 0)
        return {0, 0, 0};
    const double fit = std::min(double(output.w) / Canvas.w, double(output.h) / Canvas.h);
    const double scale = fit >= 1 ? std::floor(fit) : fit;
    return {scale, std::floor((output.w - Canvas.w * scale) / 2),
            std::floor((output.h - Canvas.h * scale) / 2)};
}

SDL_FRect Viewport::place(Point point, Size logical, Point anchor) const {
    return {static_cast<float>(x + (double(point.x) - anchor.x) * scale),
            static_cast<float>(y + (double(point.y) - anchor.y) * scale),
            static_cast<float>(logical.w * scale), static_cast<float>(logical.h * scale)};
}

void SpriteTexture::draw(SDL_Renderer* renderer, const ImageAsset& asset, const Viewport& view,
                         Point position, std::uint64_t tick) {
    if (view.scale == 0)
        return;
    const auto& pixels = asset.variants.at(asset.tier(view.scale));
    std::vector<std::uint64_t> phase;
    for (const auto& cycle : asset.cycles)
        phase.push_back((tick / cycle.ticks) % (cycle.last - cycle.first + 1));

    const bool newImage = pixels_ != &pixels;
    if (newImage) {
        texture_.reset(SDL_CreateTexture(renderer, SDL_PIXELFORMAT_RGBA32, SDL_TEXTUREACCESS_STATIC,
                                         pixels.size.w, pixels.size.h));
        if (!texture_ || !SDL_SetTextureBlendMode(texture_.get(), SDL_BLENDMODE_BLEND) ||
            !SDL_SetTextureScaleMode(texture_.get(), SDL_SCALEMODE_NEAREST))
            throw std::runtime_error(SDL_GetError());
    }
    if (newImage || phase_ != phase) {
        const auto data = pixels.rgba(tick, asset.cycles);
        if (!SDL_UpdateTexture(texture_.get(), nullptr, data.data(), pixels.size.w * 4))
            throw std::runtime_error(SDL_GetError());
        pixels_ = &pixels;
        phase_ = std::move(phase);
    }

    const auto frame = tick / asset.frameTicks % (asset.columns * asset.rows);
    const auto width = pixels.size.w / asset.columns;
    const auto height = pixels.size.h / asset.rows;
    const SDL_FRect source{float(frame % asset.columns * width), float(frame / asset.columns * height),
                           float(width), float(height)};
    const auto destination = view.place(position, asset.logicalSize, asset.anchor);
    if (!SDL_RenderTexture(renderer, texture_.get(), &source, &destination))
        throw std::runtime_error(SDL_GetError());
}

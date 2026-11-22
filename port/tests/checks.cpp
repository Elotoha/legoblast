#include "audio.hpp"
#include "display.hpp"

#include <array>
#include <cmath>
#include <iostream>
#include <stdexcept>

namespace {
void expect(bool condition, const char* message) {
    if (!condition)
        throw std::runtime_error(message);
}

void displayChecks(const Assets& assets) {
    const auto& sprite = assets.images.at("sprite");
    const auto& bar = assets.images.at("bar");
    expect(sprite.tier(1) == 1 && sprite.tier(3) == 3 && sprite.tier(4) == 4 &&
           bar.tier(4) == 1, "base and HD selection must be per asset");
    const auto& base = sprite.variants.at(1);
    const auto before = base.rgba(0, sprite.cycles);
    const auto after = base.rgba(1, sprite.cycles);
    expect(before[0] == 255 && before[1] == 0 && before[3] == 255 && before[7] == 0 &&
           after[0] == 0 && after[1] == 255 && after[7] == 0, "cycle or separate opacity mask");
    const auto high = sprite.variants.at(4).rgba(0, sprite.cycles);
    expect(high[3] == 255 && high[7] == 0, "external HD mask");
    const auto raw = bar.variants.at(1).rgba(0, {});
    expect(raw[0] == 255 && raw[1] == 255 && raw[4] == 0, "planar decode");

    const auto small = viewport({160, 128});
    const auto view = viewport({1920, 1080});
    const auto spriteRect = view.place({12, 8}, sprite.logicalSize, sprite.anchor);
    expect(small.scale == 0.5 && view.scale == 4 && view.x == 320 && view.y == 28 &&
           spriteRect.x == 364 && spriteRect.y == 60 && spriteRect.w == 4,
           "viewport or logical anchor");

    const auto destroySurface = SDL_DestroySurface;
    std::unique_ptr<SDL_Surface, decltype(destroySurface)> surface(
        SDL_CreateSurface(1280, 1024, SDL_PIXELFORMAT_RGBA32), destroySurface);
    expect(bool(surface), SDL_GetError());
    std::unique_ptr<SDL_Renderer, decltype(&SDL_DestroyRenderer)> renderer(
        SDL_CreateSoftwareRenderer(surface.get()), SDL_DestroyRenderer);
    expect(bool(renderer), SDL_GetError());
    expect(SDL_SetRenderDrawColor(renderer.get(), 0, 0, 0, 255), SDL_GetError());
    expect(SDL_RenderClear(renderer.get()), SDL_GetError());
    const auto exact = viewport({1280, 1024});
    SpriteTexture texture;
    texture.draw(renderer.get(), sprite, exact, {1, 0}, 0);
    texture.draw(renderer.get(), bar, exact, {0, 1}, 0);
    expect(SDL_RenderPresent(renderer.get()), SDL_GetError());
    Uint8 r{}, g{}, b{}, a{};
    expect(SDL_ReadSurfacePixel(surface.get(), 0, 0, &r, &g, &b, &a) && r == 0 && g == 255,
           "HD source must be presented");
    expect(SDL_ReadSurfacePixel(surface.get(), 0, 4, &r, &g, &b, &a) && r == 255 && g == 255,
           "base-resolution interface asset must be presented alongside HD");
}

void audioChecks(const Assets& assets) {
    const auto& cue = assets.music.at("cue");
    const auto& sound = assets.sounds.at("effect");
    const auto& iffSound = assets.sounds.at("tone").clip;
    expect(iffSound.rate == 8000 && iffSound.frames() == 2 &&
           iffSound.samples == std::vector<float>{.5f, -.5f}, "8SVX conversion");
    expect(sound.clip.rate == 24000 && sound.clip.frames() == 2, "source rate or frame count changed");
    Mixer music(1);
    music.play(cue);
    music.enableStem(1, false);
    std::array<float, 10> samples{};
    music.render(samples);
    expect(samples == std::array<float, 10>{.0625f, .0625f, .125f, .125f, .25f, .25f,
                                            .125f, .125f, .25f, .25f}, "sample-exact music loop");
    music.enableStem(1, true);
    std::array<float, 2> stereo{};
    music.render(stereo);
    expect(stereo[0] == .1875f && stereo[1] == .1875f, "stem must rejoin at current phase");
    Mixer effects(1);
    const Sound quieter{sound.clip, 1, .25f};
    expect(effects.play(quieter) && effects.play(sound, 2) && !effects.play(quieter),
           "effect priority arbitration");
    effects.render(samples);
    expect(samples[0] == .25f && samples[2] == 0 && samples[4] == -.25f && samples[8] == .25f,
           "sample-rate conversion or repeated effect");
}
}

int main(int argc, char** argv) {
    try {
        expect(argc == 2, "package argument required");
        const auto assets = loadAssets(argv[1]);
        displayChecks(assets);
        audioChecks(assets);
    } catch (const std::exception& error) {
        std::cerr << error.what() << '\n';
        return 1;
    }
}

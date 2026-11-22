#include "audio.hpp"
#include "display.hpp"

#include <SDL3/SDL_main.h>

#include <array>
#include <charconv>
#include <iostream>
#include <stdexcept>
#include <string_view>

namespace {
void check(bool ok) {
    if (!ok)
        throw std::runtime_error(SDL_GetError());
}

template<class T, void (*Destroy)(T*)>
using Handle = std::unique_ptr<T, decltype(Destroy)>;

unsigned frameLimit(std::string_view input) {
    unsigned frames{};
    const auto [end, error] = std::from_chars(input.data(), input.data() + input.size(), frames);
    if (error != std::errc{} || end != input.data() + input.size() || frames == 0)
        throw std::runtime_error("expected a positive frame count");
    return frames;
}

void preview(const Assets& assets, unsigned limit) {
    check(SDL_Init(SDL_INIT_VIDEO | SDL_INIT_AUDIO));
    SDL_Window* windowRaw{};
    SDL_Renderer* rendererRaw{};
    check(SDL_CreateWindowAndRenderer("Aperçu des ressources", 960, 768,
                                     SDL_WINDOW_RESIZABLE | SDL_WINDOW_HIGH_PIXEL_DENSITY,
                                     &windowRaw, &rendererRaw));
    const Handle<SDL_Window, SDL_DestroyWindow> window(windowRaw, SDL_DestroyWindow);
    const Handle<SDL_Renderer, SDL_DestroyRenderer> renderer(rendererRaw, SDL_DestroyRenderer);
    const SDL_AudioSpec audio{SDL_AUDIO_F32, 2, Mixer::Rate};
    const Handle<SDL_AudioStream, SDL_DestroyAudioStream> stream(
        SDL_OpenAudioDeviceStream(SDL_AUDIO_DEVICE_DEFAULT_PLAYBACK, &audio, nullptr, nullptr),
        SDL_DestroyAudioStream);
    check(bool(stream));
    check(SDL_ResumeAudioStreamDevice(stream.get()));

    Mixer mixer(4);
    if (!assets.music.empty())
        mixer.play(assets.music.begin()->second);
    SpriteTexture texture;
    auto image = assets.images.begin();
    auto sound = assets.sounds.begin();
    std::array<float, 480 * 2> audioBlock{};
    const auto start = std::chrono::steady_clock::now();
    unsigned frames{};
    bool running = true;
    while (running && (limit == 0 || frames < limit)) {
        SDL_Event event;
        while (SDL_PollEvent(&event)) {
            if (event.type == SDL_EVENT_QUIT ||
                (event.type == SDL_EVENT_KEY_DOWN && event.key.key == SDLK_ESCAPE))
                running = false;
            if (event.type != SDL_EVENT_KEY_DOWN || event.key.repeat)
                continue;
            if (event.key.key == SDLK_RIGHT && image != assets.images.end()) {
                if (++image == assets.images.end())
                    image = assets.images.begin();
            }
            if (event.key.key == SDLK_SPACE && sound != assets.sounds.end()) {
                mixer.play(sound->second);
                if (++sound == assets.sounds.end())
                    sound = assets.sounds.begin();
            }
        }

        const auto queued = SDL_GetAudioStreamQueued(stream.get());
        check(queued >= 0);
        if (queued < static_cast<int>(3 * sizeof(audioBlock))) {
            mixer.render(audioBlock);
            check(SDL_PutAudioStreamData(stream.get(), audioBlock.data(), sizeof(audioBlock)));
        }

        Size output{};
        check(SDL_GetCurrentRenderOutputSize(renderer.get(), &output.w, &output.h));
        const auto view = viewport(output);
        check(SDL_SetRenderDrawColor(renderer.get(), 18, 24, 32, 255));
        check(SDL_RenderClear(renderer.get()));
        const auto area = view.place({0, 0}, Canvas, {0, 0});
        check(SDL_SetRenderDrawColor(renderer.get(), 38, 52, 62, 255));
        check(SDL_RenderFillRect(renderer.get(), &area));
        if (image != assets.images.end()) {
            const auto& asset = image->second;
            const auto tick = (std::chrono::steady_clock::now() - start) / TickDuration;
            texture.draw(renderer.get(), asset, view,
                         {(Canvas.w - asset.logicalSize.w) / 2 + asset.anchor.x,
                          (Canvas.h - asset.logicalSize.h) / 2 + asset.anchor.y}, tick);
        }
        check(SDL_RenderPresent(renderer.get()));
        ++frames;
        SDL_Delay(4);
    }
}
}

int main(int argc, char** argv) {
    try {
        if (argc < 2 || argc > 4)
            throw std::runtime_error("usage: asset_preview PACKAGE [--check | --frames N]");
        const auto assets = loadAssets(argv[1]);
        if (argc == 3 && std::string_view(argv[2]) == "--check") {
            std::cout << assets.images.size() << " images, " << assets.sounds.size() << " sounds, "
                      << assets.music.size() << " music cues\n";
            return 0;
        }
        unsigned frames{};
        if (argc != 2) {
            if (argc != 4 || std::string_view(argv[2]) != "--frames")
                throw std::runtime_error("unknown option");
            frames = frameLimit(argv[3]);
        }
        struct QuitSDL {
            ~QuitSDL() { SDL_Quit(); }
        } quit;
        preview(assets, frames);
    } catch (const std::exception& error) {
        std::cerr << error.what() << '\n';
        return 1;
    }
}

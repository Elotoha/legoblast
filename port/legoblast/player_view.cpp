#include "players.hpp"

#include <SDL3/SDL.h>
#include <SDL3/SDL_main.h>

#include <algorithm>
#include <iostream>
#include <memory>
#include <stdexcept>
#include <string_view>

using namespace legoblast;

namespace {
template<class T, void (*Destroy)(T*)>
using Handle = std::unique_ptr<T, decltype(Destroy)>;
using Texture = Handle<SDL_Texture, SDL_DestroyTexture>;
constexpr int SpriteWidth = 16;
constexpr int SpriteHeight = 24;
constexpr int BoardWidth = Width * TileSize;
constexpr int BoardHeight = Height * TileSize;

void check(bool success) {
    if (!success)
        throw std::runtime_error(SDL_GetError());
}

unsigned readBig(std::span<const std::uint8_t> bytes, std::size_t offset, unsigned width) {
    if (offset > bytes.size() || width > bytes.size() - offset)
        throw std::runtime_error("original sprite bank or index is truncated");
    unsigned value = 0;
    for (unsigned i = 0; i < width; ++i)
        value = value << 8 | bytes[offset + i];
    return value;
}

// CalcMot selects two attached two-plane sprites through AdrIndex.
Bytes attachedSprite(const Bytes& sprites, const Bytes& indices, const Bytes& palette, int frame) {
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
                const auto rgb = readBig(palette, color * 4, 4);
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

Controls keyboard() {
    const auto* keys = SDL_GetKeyboardState(nullptr);
    Controls input{};
    input[static_cast<std::size_t>(Control::Keyboard1)] = {
        keys[SDL_SCANCODE_LEFT], keys[SDL_SCANCODE_RIGHT], keys[SDL_SCANCODE_UP],
        keys[SDL_SCANCODE_DOWN], keys[SDL_SCANCODE_RALT]};
    input[static_cast<std::size_t>(Control::Keyboard2)] = {
        keys[SDL_SCANCODE_W], keys[SDL_SCANCODE_R], keys[SDL_SCANCODE_3] || keys[SDL_SCANCODE_4],
        keys[SDL_SCANCODE_E], keys[SDL_SCANCODE_SPACE]};
    input[static_cast<std::size_t>(Control::Keyboard3)] = {
        keys[SDL_SCANCODE_KP_7], keys[SDL_SCANCODE_KP_9], keys[SDL_SCANCODE_KP_LEFTBRACE],
        keys[SDL_SCANCODE_KP_8], keys[SDL_SCANCODE_RIGHT]};
    return input;
}

Texture texture(SDL_Renderer* renderer, SDL_PixelFormat format, int width, int height) {
    Texture result(SDL_CreateTexture(renderer, format, SDL_TEXTUREACCESS_STATIC, width, height),
                   SDL_DestroyTexture);
    check(bool(result) && SDL_SetTextureScaleMode(result.get(), SDL_SCALEMODE_NEAREST));
    return result;
}

int view(const std::filesystem::path& root, const std::filesystem::path& spriteFile,
         const std::filesystem::path& levelFile, bool smoke) {
    const auto binary = root / "binary";
    const auto level = loadLevel(levelFile);
    const auto board = staticLevelRgb(level, readBytes(binary / "Lego_Blocs.dat"),
                                      readLevelPalette(root, level.palette));
    const auto sprites = readBytes(spriteFile);
    const auto indices = readBytes(binary / "Lego_SpritesIndex.dat");
    const auto palette = readBytes(binary / "Lego_Sprites.col");
    PlayerMap map(level);
    Players players;
    players.prepare(level, true, false);
    PlayerTick tick{};

    check(SDL_Init(SDL_INIT_VIDEO));
    SDL_Window* windowRaw{};
    SDL_Renderer* rendererRaw{};
    check(SDL_CreateWindowAndRenderer("LegoBlast - verification des joueurs", 912, 720,
                                     SDL_WINDOW_RESIZABLE, &windowRaw, &rendererRaw));
    Handle<SDL_Window, SDL_DestroyWindow> window(windowRaw, SDL_DestroyWindow);
    Handle<SDL_Renderer, SDL_DestroyRenderer> renderer(rendererRaw, SDL_DestroyRenderer);
    check(SDL_SetRenderLogicalPresentation(renderer.get(), BoardWidth, BoardHeight,
                                          SDL_LOGICAL_PRESENTATION_INTEGER_SCALE));
    check(SDL_SetWindowMinimumSize(window.get(), BoardWidth, BoardHeight));
    auto background = texture(renderer.get(), SDL_PIXELFORMAT_RGB24, BoardWidth, BoardHeight);
    check(SDL_UpdateTexture(background.get(), nullptr, board.data(), BoardWidth * 3));
    auto sprite = texture(renderer.get(), SDL_PIXELFORMAT_RGBA32, SpriteWidth, SpriteHeight);
    check(SDL_SetTextureBlendMode(sprite.get(), SDL_BLENDMODE_BLEND));

    auto previous = SDL_GetTicks();
    Uint64 elapsed = 0;
    bool running = true;
    while (running) {
        SDL_Event event{};
        while (SDL_PollEvent(&event))
            if (event.type == SDL_EVENT_QUIT ||
                (event.type == SDL_EVENT_KEY_DOWN && event.key.key == SDLK_ESCAPE))
                running = false;
        const auto now = SDL_GetTicks();
        elapsed += smoke ? 20 : std::min<Uint64>(now - previous, 100);
        previous = now;
        for (; elapsed >= 20; elapsed -= 20) {
            auto input = keyboard();
            if (smoke) {
                auto& player = input[static_cast<std::size_t>(Control::Keyboard1)];
                player.fire = tick.autoCounter == 0;
            }
            ++tick.autoCounter;
            players.tick(input, tick, map);
        }
        check(SDL_RenderClear(renderer.get()));
        check(SDL_RenderTexture(renderer.get(), background.get(), nullptr, nullptr));
        for (const auto& player : players.slots()) {
            if (!player.visible)
                continue;
            const auto image = attachedSprite(sprites, indices, palette, player.frameBase + player.frame);
            check(SDL_UpdateTexture(sprite.get(), nullptr, image.data(), SpriteWidth * 4));
            const auto point = player.center();
            const SDL_FRect box{float(point.x - 7), float(point.y - 20), SpriteWidth, SpriteHeight};
            check(SDL_RenderTexture(renderer.get(), sprite.get(), nullptr, &box));
        }
        check(SDL_RenderPresent(renderer.get()));
        if (smoke && tick.autoCounter == 31) {
            if (players.slots()[0].activation != Activation::Ready || players.slots()[0].frame != 33)
                throw std::runtime_error("appearance smoke test failed");
            break;
        }
        if (!smoke)
            SDL_Delay(2);
    }
    return 0;
}
}

int main(int argc, char* argv[]) {
    struct Quit { ~Quit() { SDL_Quit(); } } quit;
    try {
        if (argc != 4 && (argc != 5 || std::string_view(argv[4]) != "--smoke"))
            throw std::runtime_error("usage: legoblast_players AMIGA_SRC LEGO_SPRITES.DAT LEVEL.dat [--smoke]");
        return view(argv[1], argv[2], argv[3], argc == 5);
    } catch (const std::exception& error) {
        std::cerr << error.what() << '\n';
        return 1;
    }
}

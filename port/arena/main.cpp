#include "rules.hpp"

#include <SDL3/SDL.h>
#include <SDL3/SDL_main.h>

#include <algorithm>
#include <array>
#include <iostream>
#include <memory>
#include <stdexcept>
#include <string>
#include <string_view>

namespace {
using ember::Point;
constexpr int CanvasWidth = 320;
constexpr int CanvasHeight = 240;
constexpr int TileSize = 20;
constexpr int Left = 30;
constexpr int Top = 35;
constexpr SDL_Color Ink{12, 19, 31, 255};
constexpr SDL_Color White{236, 238, 215, 255};
constexpr SDL_Color Muted{157, 182, 188, 255};
constexpr SDL_Color Amber{255, 179, 75, 255};
constexpr SDL_Color Cyan{84, 227, 214, 255};
constexpr std::array<SDL_Color, 2> colors{Amber, Cyan};

void check(bool ok) {
    if (!ok)
        throw std::runtime_error(SDL_GetError());
}

void color(SDL_Renderer* renderer, SDL_Color value) {
    check(SDL_SetRenderDrawColor(renderer, value.r, value.g, value.b, value.a));
}

void rect(SDL_Renderer* renderer, int x, int y, int w, int h, SDL_Color value) {
    color(renderer, value);
    const SDL_FRect box{float(x), float(y), float(w), float(h)};
    check(SDL_RenderFillRect(renderer, &box));
}

void text(SDL_Renderer* renderer, int x, int y, const std::string& label, SDL_Color value) {
    color(renderer, value);
    check(SDL_RenderDebugText(renderer, float(x), float(y), label.c_str()));
}

void drawTile(SDL_Renderer* renderer, const ember::Arena& arena, Point cell) {
    const int x = Left + cell.x * TileSize;
    const int y = Top + cell.y * TileSize;
    const auto tile = arena.tileAt(cell);
    rect(renderer, x, y, 20, 20, (cell.x + cell.y) % 2 ? SDL_Color{26, 43, 55, 255}
                                                      : SDL_Color{29, 47, 60, 255});
    rect(renderer, x + 3, y + 16, 2, 1, {43, 65, 76, 255});
    if (tile == ember::Tile::Steel) {
        rect(renderer, x + 1, y + 1, 18, 18, {39, 65, 78, 255});
        rect(renderer, x + 1, y + 1, 18, 2, {76, 112, 119, 255});
        rect(renderer, x + 2, y + 16, 16, 2, {24, 40, 54, 255});
        rect(renderer, x + 4, y + 6, 2, 2, {123, 145, 142, 255});
        rect(renderer, x + 14, y + 6, 2, 2, {123, 145, 142, 255});
    }
    if (tile == ember::Tile::Crate) {
        rect(renderer, x + 2, y + 3, 16, 15, {111, 68, 47, 255});
        rect(renderer, x + 2, y + 3, 16, 2, {204, 130, 74, 255});
        for (int i = 5; i < 14; ++i)
            rect(renderer, x + i, y + i + 1, 3, 1, {176, 107, 61, 255});
        rect(renderer, x + 4, y + 15, 12, 2, {67, 45, 47, 255});
    }
    if (const int energy = arena.flameAt(cell); energy > 0) {
        rect(renderer, x + 1, y + 6, 18, 8, {225, 83, 49, 255});
        rect(renderer, x + 6, y + 2, 8, 16, {255, 149, 57, 255});
        if (energy > 5)
            rect(renderer, x + 6, y + 6, 8, 8, {255, 228, 141, 255});
    }
}

void draw(SDL_Renderer* renderer, const ember::Arena& arena) {
    color(renderer, Ink);
    check(SDL_RenderClear(renderer));
    text(renderer, 30, 8, "EMBER RELAY", White);
    const auto& players = arena.players();
    text(renderer, 30, 22, "AMBRE " + std::to_string(players[0].score), Amber);
    text(renderer, 142, 22, std::to_string((arena.ticksLeft() + 49) / 50) + "s", White);
    text(renderer, 230, 22, "CYAN " + std::to_string(players[1].score), Cyan);
    for (int y = 0; y < ember::Height; ++y)
        for (int x = 0; x < ember::Width; ++x)
            drawTile(renderer, arena, {x, y});

    for (const auto& bomb : arena.bombs()) {
        const int x = Left + bomb.cell.x * TileSize;
        const int y = Top + bomb.cell.y * TileSize;
        rect(renderer, x + 4, y + 7, 12, 9, Ink);
        rect(renderer, x + 6, y + 5, 8, 12, Ink);
        rect(renderer, x + 7, y + 8, 2, 2, Muted);
        rect(renderer, x + 12, y + 4, 4, 2, (bomb.fuse / 6) % 2 ? colors[bomb.owner] : White);
    }
    for (int i = 0; i < 2; ++i) {
        if (!players[i].alive)
            continue;
        const Point cell = players[i].cell;
        const int x = Left + cell.x * TileSize;
        const int y = Top + cell.y * TileSize;
        rect(renderer, x + 4, y + 16, 12, 2, Ink);
        rect(renderer, x + 5, y + 7, 10, 9, colors[i]);
        rect(renderer, x + 6, y + 4, 8, 5, colors[i]);
        rect(renderer, x + 7, y + 8, 7, 3, Ink);
        rect(renderer, x + 11, y + 8, 2, 2, White);
        rect(renderer, x + 5, y + 15, 4, 2, Muted);
        rect(renderer, x + 11, y + 15, 4, 2, Muted);
    }
    text(renderer, 22, 225, "AMBRE ZQSD + ESPACE", Amber);
    text(renderer, 185, 225, "CYAN FLECHES + M", Cyan);

    if (arena.result() != ember::Result::Playing) {
        rect(renderer, 40, 91, 240, 58, Ink);
        rect(renderer, 40, 91, 240, 2, Muted);
        const auto result = arena.result();
        const auto label = result == ember::Result::Draw ? "MANCHE NULLE" :
                           result == ember::Result::Amber ? "AMBRE GAGNE" : "CYAN GAGNE";
        text(renderer, 55, 103, arena.matchComplete() ? std::string(label) + " LE MATCH" : label, White);
        text(renderer, 55, 124, arena.matchComplete() ? "ENTREE : NOUVEAU MATCH" : "ENTREE : MANCHE SUIVANTE", Muted);
    }
    check(SDL_RenderPresent(renderer));
}

Point direction(const bool* keys, int player) {
    if (player == 0) {
        // Physical bindings support both AZERTY (ZQSD) and QWERTY (WASD).
        if (keys[SDL_SCANCODE_W]) return {0, -1};
        if (keys[SDL_SCANCODE_A]) return {-1, 0};
        if (keys[SDL_SCANCODE_S]) return {0, 1};
        if (keys[SDL_SCANCODE_D]) return {1, 0};
    } else {
        if (keys[SDL_SCANCODE_UP]) return {0, -1};
        if (keys[SDL_SCANCODE_LEFT]) return {-1, 0};
        if (keys[SDL_SCANCODE_DOWN]) return {0, 1};
        if (keys[SDL_SCANCODE_RIGHT]) return {1, 0};
    }
    return {};
}

void play(bool smoke) {
    check(SDL_Init(SDL_INIT_VIDEO));
    SDL_Window* window{};
    SDL_Renderer* renderer{};
    check(SDL_CreateWindowAndRenderer("Ember Relay", 960, 720,
                                     SDL_WINDOW_RESIZABLE | SDL_WINDOW_HIGH_PIXEL_DENSITY,
                                     &window, &renderer));
    const std::unique_ptr<SDL_Window, decltype(&SDL_DestroyWindow)> windowHandle(window, SDL_DestroyWindow);
    const std::unique_ptr<SDL_Renderer, decltype(&SDL_DestroyRenderer)> rendererHandle(renderer, SDL_DestroyRenderer);
    check(SDL_SetRenderLogicalPresentation(renderer, CanvasWidth, CanvasHeight,
                                          SDL_LOGICAL_PRESENTATION_INTEGER_SCALE));
    check(SDL_SetWindowMinimumSize(window, CanvasWidth, CanvasHeight));

    ember::Arena arena;
    std::array<ember::Input, 2> input{};
    Uint64 previous = SDL_GetTicks();
    Uint64 pending{};
    unsigned frames{};
    bool running = true;
    while (running) {
        SDL_Event event;
        while (SDL_PollEvent(&event)) {
            if (event.type == SDL_EVENT_QUIT)
                running = false;
            if (event.type != SDL_EVENT_KEY_DOWN || event.key.repeat)
                continue;
            if (event.key.scancode == SDL_SCANCODE_ESCAPE)
                running = false;
            if (event.key.scancode == SDL_SCANCODE_RETURN && arena.result() != ember::Result::Playing) {
                arena.nextRound();
                input = {};
            }
            if (event.key.scancode == SDL_SCANCODE_SPACE)
                input[0].plant = true;
            if (event.key.key == SDLK_M || event.key.scancode == SDL_SCANCODE_KP_0)
                input[1].plant = true;
        }
        const auto now = SDL_GetTicks();
        pending += std::min<Uint64>(now - previous, 100);
        previous = now;
        if (smoke) {
            pending = ember::TickMs;
            input[0].plant = frames == 0;
        }
        for (; pending >= ember::TickMs; pending -= ember::TickMs) {
            for (int i = 0; i < 2; ++i)
                input[i].direction = direction(SDL_GetKeyboardState(nullptr), i);
            arena.tick(input);
            for (auto& control : input)
                control.plant = false;
        }
        draw(renderer, arena);
        if (smoke && ++frames == ember::FuseTicks) {
            if (arena.result() != ember::Result::Cyan)
                throw std::runtime_error("scripted round did not end as expected");
            break;
        }
        if (!smoke)
            SDL_Delay(8);
    }
}
}

int main(int argc, char** argv) {
    struct QuitSDL { ~QuitSDL() { SDL_Quit(); } } quit;
    try {
        play(argc == 2 && std::string_view(argv[1]) == "--smoke");
        return 0;
    } catch (const std::exception& error) {
        std::cerr << error.what() << '\n';
        return 1;
    }
}

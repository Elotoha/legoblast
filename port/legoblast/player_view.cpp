#include "session.hpp"
#include "sprite.hpp"

#include <SDL3/SDL.h>
#include <SDL3/SDL_main.h>

#include <algorithm>
#include <iostream>
#include <memory>
#include <stdexcept>
#include <string_view>
#include <utility>

using namespace legoblast;

namespace {
template<class T, void (*Destroy)(T*)>
using Handle = std::unique_ptr<T, decltype(Destroy)>;
using Texture = Handle<SDL_Texture, SDL_DestroyTexture>;
constexpr int BoardWidth = Width * TileSize;
constexpr int BoardHeight = Height * TileSize;
constexpr int HudHeight = 26;

void check(bool success) {
    if (!success)
        throw std::runtime_error(SDL_GetError());
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

class Gamepads {
public:
    ~Gamepads() {
        for (auto* pad : pads_)
            if (pad)
                SDL_CloseGamepad(pad);
    }

    void update(const SDL_Event& event) {
        if (event.type == SDL_EVENT_GAMEPAD_ADDED) {
            const auto slot = std::ranges::find(pads_, nullptr);
            if (slot != pads_.end())
                *slot = SDL_OpenGamepad(event.gdevice.which);
        } else if (event.type == SDL_EVENT_GAMEPAD_REMOVED) {
            for (auto& pad : pads_)
                if (pad && SDL_GetGamepadID(pad) == event.gdevice.which) {
                    SDL_CloseGamepad(pad);
                    pad = nullptr;
                    break;
                }
        }
    }

    void read(Controls& input) const {
        constexpr Sint16 deadZone = 12000;
        for (std::size_t i = 0; i < pads_.size(); ++i) {
            if (auto* pad = pads_[i]) {
                const auto x = SDL_GetGamepadAxis(pad, SDL_GAMEPAD_AXIS_LEFTX);
                const auto y = SDL_GetGamepadAxis(pad, SDL_GAMEPAD_AXIS_LEFTY);
                input[i] = {
                    x < -deadZone || SDL_GetGamepadButton(pad, SDL_GAMEPAD_BUTTON_DPAD_LEFT),
                    x > deadZone || SDL_GetGamepadButton(pad, SDL_GAMEPAD_BUTTON_DPAD_RIGHT),
                    y < -deadZone || SDL_GetGamepadButton(pad, SDL_GAMEPAD_BUTTON_DPAD_UP),
                    y > deadZone || SDL_GetGamepadButton(pad, SDL_GAMEPAD_BUTTON_DPAD_DOWN),
                    SDL_GetGamepadButton(pad, SDL_GAMEPAD_BUTTON_SOUTH)};
            }
        }
    }

private:
    std::array<SDL_Gamepad*, 4> pads_{};
};

Texture texture(SDL_Renderer* renderer, SDL_PixelFormat format, int width, int height) {
    Texture result(SDL_CreateTexture(renderer, format, SDL_TEXTUREACCESS_STATIC, width, height),
                   SDL_DestroyTexture);
    check(bool(result) && SDL_SetTextureScaleMode(result.get(), SDL_SCALEMODE_NEAREST));
    return result;
}

Session makeSession(const std::filesystem::path& binary, const std::filesystem::path& level,
                    MatchOptions options) {
    if (options.arena == ArenaMode::Fixed)
        return Session(loadLevel(level), options);
    if (options.arena == ArenaMode::Dynablaster)
        return Session(loadLevel(binary / "Lego_Level999.dat"), options);
    std::vector<Level> levels;
    std::size_t startingIndex = 0;
    bool found = false;
    const int worlds = options.teams ? 6 : 5;
    for (int world = 0; world < worlds; ++world)
        for (int index = 1; index <= 30; ++index) {
            const auto number = std::to_string(1000 + 100 * world + index).substr(1);
            const auto file = "Lego_Level" + number + ".dat";
            const auto path = binary / file;
            if (!std::filesystem::is_regular_file(path))
                continue;
            if (level.filename() == path.filename()) {
                startingIndex = levels.size();
                found = true;
            }
            levels.push_back(loadLevel(path));
        }
    if (!found)
        throw std::runtime_error("starting level is not in the arena list for this mode");
    return Session(std::move(levels), startingIndex, options);
}

int view(const std::filesystem::path& root, const std::filesystem::path& spriteFile,
         const std::filesystem::path& levelFile, bool smoke, MatchOptions options) {
    const auto binary = root / "binary";
    auto session = makeSession(binary, levelFile, options);
    const auto& level = session.arena();
    const auto bank = readBytes(binary / "Lego_Blocs.dat");
    auto boardPalette = readLevelPalette(root, level.palette);
    constexpr std::array<const char*, 3> flameFiles{
        "Lego_Flam_bib.Dat", "Lego_Flam_Manu.Dat", "Lego_Flam_lazer.Dat",
    };
    auto flameBank = readBytes(binary / flameFiles.at(level.flamePalette));
    auto lastPalette = level.palette, lastFlamePalette = level.flamePalette;
    auto lastArena = session.arenaIndex();
    auto terrain = staticLevelIndices(level, bank);
    auto displayedTiles = level.tiles;
    const auto sprites = readBytes(spriteFile);
    const auto indices = readBytes(binary / "Lego_SpritesIndex.dat");
    const auto palette = readBytes(binary / "Lego_Sprites.col");
    const auto independent = readBytes(binary / "Lego_Sprites8.dat");
    const auto independentIndices = readBytes(binary / "Lego_SpritesIndex8.dat");
    const auto independentPalette = readBytes(binary / "Mec8_normal.col");
    unsigned smokeFrame = 0;

    check(SDL_Init(SDL_INIT_VIDEO | SDL_INIT_GAMEPAD));
    Gamepads pads;
    SDL_Window* windowRaw{};
    SDL_Renderer* rendererRaw{};
    check(SDL_CreateWindowAndRenderer("LegoBlast", 912, 798,
                                     SDL_WINDOW_RESIZABLE, &windowRaw, &rendererRaw));
    Handle<SDL_Window, SDL_DestroyWindow> window(windowRaw, SDL_DestroyWindow);
    Handle<SDL_Renderer, SDL_DestroyRenderer> renderer(rendererRaw, SDL_DestroyRenderer);
    check(SDL_SetRenderLogicalPresentation(renderer.get(), BoardWidth, BoardHeight + HudHeight,
                                          SDL_LOGICAL_PRESENTATION_INTEGER_SCALE));
    check(SDL_SetWindowMinimumSize(window.get(), BoardWidth, BoardHeight + HudHeight));
    auto background = texture(renderer.get(), SDL_PIXELFORMAT_RGB24, BoardWidth, BoardHeight);
    auto sprite = texture(renderer.get(), SDL_PIXELFORMAT_RGBA32, SpriteWidth, SpriteHeight);
    check(SDL_SetTextureBlendMode(sprite.get(), SDL_BLENDMODE_BLEND));

    auto previous = SDL_GetTicks();
    Uint64 elapsed = 0;
    bool running = true;
    while (running) {
        SDL_Event event{};
        while (SDL_PollEvent(&event)) {
            pads.update(event);
            if (event.type == SDL_EVENT_QUIT ||
                (event.type == SDL_EVENT_KEY_DOWN && event.key.key == SDLK_ESCAPE))
                running = false;
            if (event.type == SDL_EVENT_KEY_DOWN && !event.key.repeat) {
                if (event.key.key == SDLK_F5)
                    session.resetMatch();
                if (event.key.key == SDLK_P)
                    session.togglePause();
            }
        }
        const auto now = SDL_GetTicks();
        elapsed += smoke ? 20 : std::min<Uint64>(now - previous, 100);
        previous = now;
        for (; elapsed >= 20; elapsed -= 20) {
            auto input = keyboard();
            pads.read(input);
            if (smoke) {
                input = {};
                ++smokeFrame;
                const bool acknowledge = session.phase() == RoundPhase::Result;
                input[static_cast<std::size_t>(Control::Joy0)].fire =
                    smokeFrame == 1 || smokeFrame == 425 || acknowledge;
                input[static_cast<std::size_t>(Control::Joy1)].fire = smokeFrame == 1;
            }
            session.tick(input);
        }
        const auto& bombs = session.bombs();
        const auto& map = session.map();
        const auto arenaChanged = lastArena != session.arenaIndex();
        lastArena = session.arenaIndex();
        if (lastPalette != level.palette) {
            boardPalette = readLevelPalette(root, level.palette);
            lastPalette = level.palette;
        }
        if (lastFlamePalette != level.flamePalette) {
            flameBank = readBytes(binary / flameFiles.at(level.flamePalette));
            lastFlamePalette = level.flamePalette;
        }
        if (arenaChanged || displayedTiles != bombs.level().tiles) {
            displayedTiles = bombs.level().tiles;
            terrain = staticLevelIndices(bombs.level(), bank);
        }
        auto frame = terrain;
        for (const auto& bumper : session.bumpers())
            if (bumper.state >= 0 && map.at(bumper.cell.x, bumper.cell.y).visible == 27)
                drawLevelBlock(frame, bumper.cell, bumper.frame + bumper.imageOffset, level.blocks[0], bank);
        for (const auto& closing : session.closingFrames())
            drawLevelPattern(frame, closing.tile.x * 16, closing.tile.y * 16, 16, closing.image, bank);
        for (const auto& block : bombs.brokenBlocks())
            drawLevelPattern(frame, block.cell.x * 8, block.cell.y * 8, 16, block.frame, bank);
        for (int y = 0; y < Height * 2; ++y)
            for (int x = 0; x < Width * 2; ++x)
                if (const auto mask = bombs.flameMask(x, y); mask && !std::as_const(map).at(x, y).visible)
                    drawLevelPattern(frame, x * 8, y * 8, 8, mask, flameBank);
        for (const auto& bomb : bombs.bombs())
            if (bomb.active)
                drawLevelPattern(frame, bomb.cell.x * 8, bomb.cell.y * 8, 16, bomb.image(), bank);
        const auto rgb = levelRgb(frame, boardPalette);
        check(SDL_UpdateTexture(background.get(), nullptr, rgb.data(), BoardWidth * 3));
        check(SDL_SetRenderDrawColor(renderer.get(), 14, 19, 29, 255));
        check(SDL_RenderClear(renderer.get()));
        const SDL_FRect boardBox{0, HudHeight, BoardWidth, BoardHeight};
        check(SDL_RenderTexture(renderer.get(), background.get(), nullptr, &boardBox));
        check(SDL_SetRenderDrawColor(renderer.get(), 238, 235, 200, 255));
        const auto label = "MANCHE " + std::to_string(session.roundNumber()) +
                           "   " + std::to_string(session.remaining() / 50) + " S   " +
                           std::to_string(session.score()[0]) + " - " + std::to_string(session.score()[1]);
        check(SDL_RenderDebugText(renderer.get(), 6, 4, label.c_str()));
        std::string message;
        if (session.paused()) message = "PAUSE";
        else if (session.phase() == RoundPhase::AwaitingPlayers)
            message = session.retrying() ? (session.survivorMode() ? "SURVIVOR" : "DON'T MOVE") :
                "FEU POUR APPARAITRE";
        else if (session.phase() == RoundPhase::Result || session.phase() == RoundPhase::MatchComplete) {
            const auto winning = std::ranges::find(session.winners(), true);
            if (session.arenasFinished()) message = "FIN DES ARENES";
            else if (winning == session.winners().end()) message = "EGALITE";
            else {
                const auto slot = winning - session.winners().begin();
                message = (session.isTeamMatch() ? "EQUIPE " + std::to_string(slot % 2 + 1) :
                           "JOUEUR " + std::to_string(slot + 1)) +
                    (session.phase() == RoundPhase::MatchComplete ? " GAGNE LE MATCH" : " GAGNE");
            }
            message += " / FEU";
        } else if (session.alert()) message = "ALERTE";
        if (!message.empty())
            check(SDL_RenderDebugText(renderer.get(), 6, 15, message.c_str()));
        std::vector<const Player*> visiblePlayers;
        for (const auto& player : session.players())
            if (player.visible)
                visiblePlayers.push_back(&player);
        std::stable_sort(visiblePlayers.begin(), visiblePlayers.end(), [](const auto* a, const auto* b) {
            return a->sprite.y < b->sprite.y;
        });
        const bool independentMode = std::ranges::count_if(session.players(), [](const auto& player) {
            return player.control >= 0;
        }) > 4;
        for (const auto* player : visiblePlayers) {
            const auto frame = player->frame + player->imageOffset;
            const auto slot = static_cast<unsigned>(player - session.players().data());
            const auto image = independentMode ?
                independentSprite(independent, independentIndices, independentPalette, slot, frame) :
                attachedSprite(sprites, indices, palette, player->frameBase + frame);
            check(SDL_UpdateTexture(sprite.get(), nullptr, image.data(), SpriteWidth * 4));
            const auto point = player->center();
            const SDL_FRect box{float(point.x - 7), float(point.y - 20 + HudHeight), SpriteWidth, SpriteHeight};
            check(SDL_RenderTexture(renderer.get(), sprite.get(), nullptr, &box));
        }
        check(SDL_RenderPresent(renderer.get()));
        if (smoke && session.roundNumber() == 2) {
            if (session.score()[1] != 1 || session.players()[0].control < 0 ||
                session.players()[1].control < 0)
                throw std::runtime_error("match smoke test lost the score or controller");
            break;
        }
        if (smoke && smokeFrame >= 1200)
            throw std::runtime_error("match smoke test did not finish a round");
        if (!smoke)
            SDL_Delay(2);
    }
    return 0;
}
}

int main(int argc, char* argv[]) {
    struct Quit { ~Quit() { SDL_Quit(); } } quit;
    try {
        MatchOptions options;
        bool smoke = false;
        std::vector<std::string_view> paths;
        for (int i = 1; i < argc; ++i) {
            const std::string_view arg = argv[i];
            if (arg == "--free") options.fiveWins = false;
            else if (arg == "--teams") options.teams = true;
            else if (arg == "--survivor") options.survivor = true;
            else if (arg == "--sequential") options.arena = ArenaMode::Sequential;
            else if (arg == "--random") options.arena = ArenaMode::Random;
            else if (arg == "--dyna") options.arena = ArenaMode::Dynablaster;
            else if (arg == "--smoke") smoke = true;
            else paths.push_back(arg);
        }
        if (options.teams && options.survivor)
            throw std::runtime_error("choose teams or survivor");
        if (paths.size() <= 1) {
            const std::string_view number = paths.empty() ? "001" : paths.front();
            if (number.size() != 3 || number.find_first_not_of("0123456789") != number.npos)
                throw std::runtime_error("expected a three-digit level number");
            const char* base = SDL_GetBasePath();
            if (!base)
                throw std::runtime_error(SDL_GetError());
            const std::filesystem::path root = std::filesystem::path(reinterpret_cast<const char8_t*>(base)) / "data";
            return view(root, root / "binary/LEGO_SPRITES.DAT",
                        root / "binary" / ("Lego_Level" + std::string(number) + ".dat"), smoke, options);
        }
        if (paths.size() != 3)
            throw std::runtime_error("usage: legoblast_players [LEVEL | AMIGA_SRC SPRITES LEVEL.dat] "
                                     "[--free] [--teams | --survivor] [--sequential | --random | --dyna]");
        return view(paths[0], paths[1], paths[2], smoke, options);
    } catch (const std::exception& error) {
        std::cerr << error.what() << '\n';
        return 1;
    }
}

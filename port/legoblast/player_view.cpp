#include "hud.hpp"
#include "screens.hpp"
#include "sound_output.hpp"
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
constexpr int ScreenWidth = Hud::Width / 2;
constexpr int ScreenHeight = BoardHeight + Hud::Height;
constexpr int BoardX = (ScreenWidth - BoardWidth) / 2;
enum class ViewResult { Closed, MainMenu };

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
    Gamepads() {
        int count = 0;
        std::unique_ptr<SDL_JoystickID, decltype(&SDL_free)> ids(SDL_GetGamepads(&count), SDL_free);
        for (int i = 0; ids && i < count && i < static_cast<int>(pads_.size()); ++i)
            pads_[i] = SDL_OpenGamepad(ids.get()[i]);
    }

    ~Gamepads() {
        for (auto* pad : pads_)
            if (pad)
                SDL_CloseGamepad(pad);
    }

    void update(const SDL_Event& event) {
        if (event.type == SDL_EVENT_GAMEPAD_ADDED) {
            if (std::ranges::any_of(pads_, [&](auto* pad) { return pad && SDL_GetGamepadID(pad) == event.gdevice.which; }))
                return;
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
                    MatchOptions options, const std::vector<ArenaEntry>& arenaList) {
    if (options.arena == ArenaMode::Fixed)
        return Session(loadLevel(level), options);
    if (options.arena == ArenaMode::Dynablaster)
        return Session(loadLevel(binary / "Lego_Level999.dat"), options);
    std::vector<Level> levels;
    std::size_t startingIndex = 0;
    for (const auto& entry : arenaList) {
        if (!entry.enabled || (!options.teams && entry.number >= 500))
            continue;
        if (level.filename() == entry.file.filename())
            startingIndex = levels.size();
        levels.push_back(entry.level);
    }
    if (levels.empty())
        throw std::runtime_error("no enabled arenas in this mode");
    return Session(std::move(levels), startingIndex, options);
}

ViewResult view(const std::filesystem::path& root, const std::filesystem::path& spriteFile,
         const std::filesystem::path& levelFile, bool smoke, MatchOptions options, unsigned track,
         const std::vector<ArenaEntry>& arenaList, bool useMenu = false) {
    const auto binary = root / "binary";
    auto session = makeSession(binary, levelFile, options, arenaList);
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
    const Hud hud(spriteFile.parent_path());
    const PodiumArt podium(spriteFile.parent_path());
    if (smoke) {
        auto arenas = loadArenaList(binary);
        Menus menus(spriteFile.parent_path(), arenas);
        menus.render(15);
        menus.handle(MenuInput::Down);
        menus.handle(MenuInput::Fire);
        menus.render(15);
        menus.handle(MenuInput::Up);
        menus.handle(MenuInput::Fire);
        menus.render(15);
    }
    unsigned smokeFrame = 0;

    check(SDL_Init(SDL_INIT_VIDEO | SDL_INIT_GAMEPAD));
    Gamepads pads;
    const auto audio = root / "audio";
    SoundOutput sound(std::filesystem::is_directory(audio) ? audio : LEGOBLAST_AUDIO_PATH, track, smoke);
    SDL_Window* windowRaw{};
    SDL_Renderer* rendererRaw{};
    check(SDL_CreateWindowAndRenderer("LegoBlast", 3 * ScreenWidth, 3 * ScreenHeight,
                                     SDL_WINDOW_RESIZABLE, &windowRaw, &rendererRaw));
    Handle<SDL_Window, SDL_DestroyWindow> window(windowRaw, SDL_DestroyWindow);
    Handle<SDL_Renderer, SDL_DestroyRenderer> renderer(rendererRaw, SDL_DestroyRenderer);
    check(SDL_SetRenderLogicalPresentation(renderer.get(), ScreenWidth, ScreenHeight,
                                          SDL_LOGICAL_PRESENTATION_INTEGER_SCALE));
    check(SDL_SetWindowMinimumSize(window.get(), ScreenWidth, ScreenHeight));
    auto background = texture(renderer.get(), SDL_PIXELFORMAT_RGB24, BoardWidth, BoardHeight);
    auto bar = texture(renderer.get(), SDL_PIXELFORMAT_RGB24, Hud::Width, Hud::Height);
    auto wood = texture(renderer.get(), SDL_PIXELFORMAT_RGB24, ScreenWidth, Hud::Height);
    auto podiumTexture = texture(renderer.get(), SDL_PIXELFORMAT_RGB24, ScreenArt::Width, ScreenArt::Height);
    auto sprite = texture(renderer.get(), SDL_PIXELFORMAT_RGBA32, SpriteWidth, SpriteHeight);
    check(SDL_SetTextureBlendMode(sprite.get(), SDL_BLENDMODE_BLEND));

    auto previous = SDL_GetTicks();
    Uint64 elapsed = 0;
    bool running = true;
    while (running) {
        SDL_Event event{};
        while (SDL_PollEvent(&event)) {
            pads.update(event);
            if (useMenu && event.type == SDL_EVENT_KEY_DOWN && event.key.key == SDLK_ESCAPE)
                return ViewResult::MainMenu;
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
                const auto tick = session.elapsed() + 1;
                const bool join = tick <= 40;
                const bool acknowledge = session.phase() == RoundPhase::Result ||
                                         session.phase() == RoundPhase::MatchComplete;
                input[static_cast<std::size_t>(Control::Joy0)].fire =
                    join || tick == 425 || acknowledge;
                input[static_cast<std::size_t>(Control::Joy1)].fire = join;
            }
            const auto previousPhase = session.phase();
            session.tick(input);
            if (useMenu && previousPhase == RoundPhase::Statistics && session.phase() == RoundPhase::AwaitingPlayers)
                return ViewResult::MainMenu;
            sound.tick(session.sounds(), session.paused(),
                       session.phase() == RoundPhase::Result || session.phase() == RoundPhase::MatchComplete,
                       session.phase() == RoundPhase::Podium || session.phase() == RoundPhase::Statistics);
        }
        if (session.phase() == RoundPhase::Podium || session.phase() == RoundPhase::Statistics) {
            const auto picture = podium.render(session);
            check(SDL_UpdateTexture(podiumTexture.get(), nullptr, picture.data(), ScreenArt::Width * 3));
            check(SDL_RenderClear(renderer.get()));
            const SDL_FRect fullScreen{0, 0, ScreenArt::Width, ScreenArt::Height};
            check(SDL_RenderTexture(renderer.get(), podiumTexture.get(), nullptr, &fullScreen));
            if (session.phase() == RoundPhase::Statistics) {
                const SDL_FRect table{30, 59, 260, 66};
                check(SDL_SetRenderDrawColor(renderer.get(), 16, 16, 16, 255));
                check(SDL_RenderFillRect(renderer.get(), &table));
                check(SDL_SetRenderDrawColor(renderer.get(), 255, 255, 255, 255));
                check(SDL_RenderDebugText(renderer.get(), 38, 62, "JOUEUR  VICTOIRES  BOMBES"));
                float line = 72;
                for (const auto slot : podium.ranking(session)) {
                    const auto& player = session.players()[slot];
                    const auto wins = session.score()[session.isTeamMatch() ? slot % 2 : slot];
                    const auto label = std::to_string(slot + 1) + "       " + std::to_string(wins) +
                        "          " + std::to_string(player.bombsPlanted);
                    check(SDL_RenderDebugText(renderer.get(), 38, line, label.c_str()));
                    line += 8;
                }
            }
            check(SDL_RenderPresent(renderer.get()));
            if (smoke) {
                if (session.roundNumber() != 5 || session.score()[1] != 5 ||
                    session.players()[0].control != 0 || session.players()[1].control != 1)
                    throw std::runtime_error("match smoke test lost the score or controller");
                break;
            }
            SDL_Delay(2);
            continue;
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
        const SDL_FRect boardBox{BoardX, 0, BoardWidth, BoardHeight};
        check(SDL_RenderTexture(renderer.get(), background.get(), nullptr, &boardBox));
        const bool independentMode = std::ranges::count_if(session.players(), [](const auto& player) {
            return player.control >= 0;
        }) > 4;
        const SDL_FRect barBox{0, BoardHeight, ScreenWidth, Hud::Height};
        const auto barRgb = levelRgb(hud.render(session, independentMode), boardPalette);
        check(SDL_UpdateTexture(bar.get(), nullptr, barRgb.data(), Hud::Width * 3));
        std::string message;
        if (session.paused()) message = "PAUSE";
        else if (session.phase() == RoundPhase::AwaitingPlayers && session.retrying())
            message = session.survivorMode() ? "SURVIVOR" : "DON'T MOVE";
        if (message.empty()) {
            check(SDL_RenderTexture(renderer.get(), bar.get(), nullptr, &barBox));
        } else {
            const auto woodRgb = levelRgb(hud.wood(), boardPalette);
            check(SDL_UpdateTexture(wood.get(), nullptr, woodRgb.data(), ScreenWidth * 3));
            check(SDL_RenderTexture(renderer.get(), wood.get(), nullptr, &barBox));
            check(SDL_SetRenderDrawColor(renderer.get(), 255, 255, 255, 255));
            check(SDL_RenderDebugText(renderer.get(), (ScreenWidth - message.size() * SDL_DEBUG_TEXT_FONT_CHARACTER_SIZE) / 2.0f,
                                      BoardHeight + 5, message.c_str()));
        }
        std::vector<const Player*> visiblePlayers;
        for (const auto& player : session.players())
            if (player.visible && !session.paused())
                visiblePlayers.push_back(&player);
        std::stable_sort(visiblePlayers.begin(), visiblePlayers.end(), [](const auto* a, const auto* b) {
            return a->sprite.y < b->sprite.y;
        });
        for (const auto* player : visiblePlayers) {
            const auto frame = player->frame + player->imageOffset;
            const auto slot = static_cast<unsigned>(player - session.players().data());
            const auto image = independentMode ?
                independentSprite(independent, independentIndices, independentPalette, slot, frame) :
                attachedSprite(sprites, indices, palette, player->frameBase + frame);
            check(SDL_UpdateTexture(sprite.get(), nullptr, image.data(), SpriteWidth * 4));
            const auto point = player->center();
            const SDL_FRect box{float(BoardX + point.x - 7), float(point.y - 20), SpriteWidth, SpriteHeight};
            check(SDL_RenderTexture(renderer.get(), sprite.get(), nullptr, &box));
        }
        check(SDL_RenderPresent(renderer.get()));
        if (smoke && smokeFrame >= 6000)
            throw std::runtime_error("match smoke test did not reach the podium");
        if (!smoke)
            SDL_Delay(2);
    }
    return ViewResult::Closed;
}

MenuResult choose(Menus& menus, const std::filesystem::path& audio) {
    SDL_Window* windowRaw{};
    SDL_Renderer* rendererRaw{};
    check(SDL_CreateWindowAndRenderer("LegoBlast", 3 * ScreenArt::Width, 3 * ScreenArt::Height,
                                     SDL_WINDOW_RESIZABLE, &windowRaw, &rendererRaw));
    Handle<SDL_Window, SDL_DestroyWindow> window(windowRaw, SDL_DestroyWindow);
    Handle<SDL_Renderer, SDL_DestroyRenderer> renderer(rendererRaw, SDL_DestroyRenderer);
    check(SDL_SetRenderLogicalPresentation(renderer.get(), ScreenArt::Width, ScreenArt::Height,
                                          SDL_LOGICAL_PRESENTATION_INTEGER_SCALE));
    check(SDL_SetWindowMinimumSize(window.get(), ScreenArt::Width, ScreenArt::Height));
    auto screen = texture(renderer.get(), SDL_PIXELFORMAT_RGB24, ScreenArt::Width, ScreenArt::Height);
    SoundOutput soundtrack(audio, 9, false);
    Gamepads pads;
    Controls previous{};
    unsigned tick = 0;
    auto nextTick = SDL_GetTicks();
    while (true) {
        SDL_Event event{};
        while (SDL_PollEvent(&event)) {
            pads.update(event);
            if (event.type == SDL_EVENT_QUIT)
                return MenuResult::Exit;
            if (event.type != SDL_EVENT_KEY_DOWN)
                continue;
            auto result = MenuResult::Continue;
            switch (event.key.key) {
            case SDLK_UP: result = menus.handle(MenuInput::Up); break;
            case SDLK_DOWN: result = menus.handle(MenuInput::Down); break;
            case SDLK_LEFT: result = menus.handle(MenuInput::Left); break;
            case SDLK_RIGHT: result = menus.handle(MenuInput::Right); break;
            case SDLK_ESCAPE: result = menus.handle(MenuInput::Back); break;
            case SDLK_RETURN:
            case SDLK_KP_ENTER:
            case SDLK_RALT:
                if (!event.key.repeat)
                    result = menus.handle(MenuInput::Fire);
                break;
            default: break;
            }
            if (result != MenuResult::Continue)
                return result;
        }
        Controls input{};
        pads.read(input);
        for (std::size_t i = 0; i < 4; ++i) {
            for (const auto& [button, action] : std::array{
                    std::pair{&Buttons::up, MenuInput::Up}, std::pair{&Buttons::down, MenuInput::Down},
                    std::pair{&Buttons::left, MenuInput::Left}, std::pair{&Buttons::right, MenuInput::Right},
                    std::pair{&Buttons::fire, MenuInput::Fire}}) {
                if (input[i].*button && !(previous[i].*button)) {
                    const auto result = menus.handle(action);
                    if (result != MenuResult::Continue)
                        return result;
                }
            }
        }
        previous = input;
        const auto now = SDL_GetTicks();
        if (now >= nextTick) {
            nextTick = now + 20;
            const auto picture = menus.render(++tick);
            soundtrack.tick({}, false, false);
            check(SDL_UpdateTexture(screen.get(), nullptr, picture.data(), ScreenArt::Width * 3));
            check(SDL_RenderClear(renderer.get()));
            check(SDL_RenderTexture(renderer.get(), screen.get(), nullptr, nullptr));
            check(SDL_RenderPresent(renderer.get()));
        }
        SDL_Delay(2);
    }
}

int launch(const std::filesystem::path& root, const std::filesystem::path& sprites,
           const std::filesystem::path& level, bool smoke, MatchOptions options, unsigned track, bool useMenu) {
    if (!useMenu) {
        const auto arenas = options.arena == ArenaMode::Sequential || options.arena == ArenaMode::Random ?
            loadArenaList(root / "binary") : std::vector<ArenaEntry>{};
        view(root, sprites, level, smoke, options, track, arenas);
        return 0;
    }
    check(SDL_Init(SDL_INIT_VIDEO | SDL_INIT_GAMEPAD));
    auto arenas = loadArenaList(root / "binary");
    Menus menus(sprites.parent_path(), arenas);
    const auto audio = root / "audio";
    while (choose(menus, std::filesystem::is_directory(audio) ? audio : LEGOBLAST_AUDIO_PATH) == MenuResult::Start)
        if (view(root, sprites, menus.levelFile(), false, menus.options(), track, arenas, true) == ViewResult::Closed)
            break;
    return 0;
}
}

int main(int argc, char* argv[]) {
    struct Quit { ~Quit() { SDL_Quit(); } } quit;
    try {
        MatchOptions options;
        bool smoke = false;
        bool useMenu = argc == 1;
        unsigned track = 1;
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
            else if (arg == "--menu") useMenu = true;
            else if (arg.starts_with("--music=")) {
                const auto value = arg.substr(8);
                if (value.size() != 1 || value[0] < '0' || value[0] > '4')
                    throw std::runtime_error("expected --music=0 through --music=4");
                track = value[0] - '0';
            }
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
            return launch(root, root / "binary/LEGO_SPRITES.DAT",
                          root / "binary" / ("Lego_Level" + std::string(number) + ".dat"),
                          smoke, options, track, useMenu && !smoke);
        }
        if (paths.size() != 3)
            throw std::runtime_error("usage: legoblast_players [LEVEL | AMIGA_SRC SPRITES LEVEL.dat] "
                                     "[--free] [--teams | --survivor] [--sequential | --random | --dyna]");
        return launch(paths[0], paths[1], paths[2], smoke, options, track, useMenu && !smoke);
    } catch (const std::exception& error) {
        std::cerr << error.what() << '\n';
        return 1;
    }
}

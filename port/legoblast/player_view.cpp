#include "hud.hpp"
#include "screens.hpp"
#include "sound_output.hpp"
#include "sprite.hpp"

#include <SDL3/SDL.h>
#include <SDL3/SDL_main.h>

#include <algorithm>
#include <iostream>
#include <memory>
#include <optional>
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

class Keyboard {
public:
    void update(const SDL_Event& event) {
        if (event.type == SDL_EVENT_WINDOW_FOCUS_LOST) {
            held_.fill(false);
            pressed_.fill(false);
        }
        if (event.type != SDL_EVENT_KEY_DOWN && event.type != SDL_EVENT_KEY_UP)
            return;
        const auto code = event.key.scancode;
        if (code <= SDL_SCANCODE_UNKNOWN || code >= SDL_SCANCODE_COUNT)
            return;
        held_[code] = event.type == SDL_EVENT_KEY_DOWN;
        if (held_[code] && !event.key.repeat)
            pressed_[code] = true;
    }

    Controls read(const Session& session, bool preferShared) {
        const auto down = [&](SDL_Scancode key) { return held_[key] || pressed_[key]; };
        const auto assigned = [&](Control control) {
            return std::ranges::any_of(session.players(), [control](const Player& player) {
                return player.control == static_cast<int>(control);
            });
        };
        const bool singleFire = down(SDL_SCANCODE_RALT) || down(SDL_SCANCODE_RETURN);
        const bool shared = assigned(Control::Keyboard2) || assigned(Control::Keyboard3) ||
            (!assigned(Control::Keyboard1) && (preferShared || (!singleFire && down(SDL_SCANCODE_SPACE))));
        Controls input{};
        input[static_cast<std::size_t>(Control::Keyboard1)] = {
            down(SDL_SCANCODE_LEFT), down(SDL_SCANCODE_RIGHT), down(SDL_SCANCODE_UP),
            down(SDL_SCANCODE_DOWN), !shared && singleFire};
        input[static_cast<std::size_t>(Control::Keyboard2)] = {
            down(SDL_SCANCODE_W), down(SDL_SCANCODE_R), down(SDL_SCANCODE_3) || down(SDL_SCANCODE_4),
            down(SDL_SCANCODE_E), shared && down(SDL_SCANCODE_SPACE)};
        // On the Amiga this keyboard shares the right arrow as Fire. Reserve it
        // only after choosing shared play so a movement key cannot claim a slot.
        input[static_cast<std::size_t>(Control::Keyboard3)] = {
            down(SDL_SCANCODE_KP_7), down(SDL_SCANCODE_KP_9),
            down(SDL_SCANCODE_KP_5) || down(SDL_SCANCODE_KP_RIGHTBRACE) || down(SDL_SCANCODE_RIGHTBRACKET),
            down(SDL_SCANCODE_KP_8), shared && down(SDL_SCANCODE_RIGHT)};
        input[static_cast<std::size_t>(Control::Micro)].fire = down(SDL_SCANCODE_BACKSPACE);
        pressed_.fill(false);
        return input;
    }

private:
    std::array<bool, SDL_SCANCODE_COUNT> held_{}, pressed_{};
};

void verifyKeyboardMapping(const Session& session) {
    Keyboard keyboard;
    SDL_Event key{};
    key.type = SDL_EVENT_KEY_DOWN;
    key.key.scancode = SDL_SCANCODE_RIGHT;
    keyboard.update(key);
    const auto arrow = keyboard.read(session, false);
    if (!arrow[static_cast<std::size_t>(Control::Keyboard1)].right ||
        arrow[static_cast<std::size_t>(Control::Keyboard3)].fire)
        throw std::runtime_error("right arrow prematurely reserved the shared keyboard");
    if (!keyboard.read(session, true)[static_cast<std::size_t>(Control::Keyboard3)].fire)
        throw std::runtime_error("shared keyboard lost the original Fire key");
    key.type = SDL_EVENT_KEY_UP;
    keyboard.update(key);
    key.type = SDL_EVENT_KEY_DOWN;
    key.key.scancode = SDL_SCANCODE_UP;
    keyboard.update(key);
    key.type = SDL_EVENT_KEY_UP;
    keyboard.update(key);
    if (!keyboard.read(session, false)[static_cast<std::size_t>(Control::Keyboard1)].up ||
        keyboard.read(session, false)[static_cast<std::size_t>(Control::Keyboard1)].up)
        throw std::runtime_error("short arrow press was lost or repeated");
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
    if (options.arena == ArenaMode::Dynablaster)
        return Session(loadLevel(binary / "Lego_Level999.dat"), options);
    std::vector<Level> levels;
    std::size_t startingIndex = 0;
    bool found = false;
    for (const auto& entry : arenaList) {
        const bool selected = level.filename() == entry.file.filename();
        if (!entry.enabled && !(selected && options.arena == ArenaMode::Fixed))
            continue;
        if (options.arena != ArenaMode::Fixed && !options.teams && entry.number >= 500)
            continue;
        if (selected) {
            startingIndex = levels.size();
            found = true;
        }
        levels.push_back(selected && options.arena == ArenaMode::Fixed ? loadLevel(level) : entry.level);
    }
    if (!found && options.arena == ArenaMode::Fixed)
        return Session(loadLevel(level), options);
    if (levels.empty())
        throw std::runtime_error("no enabled arenas in this mode");
    return Session(std::move(levels), startingIndex, options);
}

ViewResult view(const std::filesystem::path& root, const std::filesystem::path& spriteFile,
         const std::filesystem::path& levelFile, bool smoke, MatchOptions options, Preferences& prefs, SoundOutput& sound,
         const std::vector<ArenaEntry>& arenaList, bool useMenu = false, bool sharedKeyboard = false) {
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
    const ReadyPanel ready(spriteFile.parent_path());
    if (smoke) {
        verifyKeyboardMapping(session);
        ExtraScreens extra(spriteFile.parent_path(), prefs.gradient);
        extra.intro(240);
        extra.slideshow(1, 50);
        extra.slideshow(2, 200);
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

    Gamepads pads;
    Keyboard keyboard;
    sound.selectTrack(prefs.music);
    if (smoke) {
        sound.verifyWithoutGameTicks();
        if (!sound.selectTrack(9))
            throw std::runtime_error("menu music unavailable");
        sound.setMenuVoices(2);
        if (!sound.selectTrack(3) || !sound.selectTrack(0) || !sound.selectTrack(prefs.music))
            throw std::runtime_error("music shortcut could not switch tracks");
        sound.verifyWithoutGameTicks();
    }
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
    Uint64 messageUntil = 0;
    std::string shortcutMessage;
    bool running = true;
    while (running) {
        SDL_Event event{};
        while (SDL_PollEvent(&event)) {
            pads.update(event);
            keyboard.update(event);
            if (event.type == SDL_EVENT_KEY_DOWN && event.key.key == SDLK_ESCAPE && !event.key.repeat) {
                if (session.phase() == RoundPhase::Podium) {
                    session.skipPodium();
                    continue;
                }
                if (useMenu)
                    return ViewResult::MainMenu;
            }
            if (event.type == SDL_EVENT_QUIT ||
                (event.type == SDL_EVENT_KEY_DOWN && event.key.key == SDLK_ESCAPE && !event.key.repeat))
                running = false;
            if (event.type == SDL_EVENT_KEY_DOWN && !event.key.repeat) {
                const auto key = event.key.scancode;
                switch (key) {
                case SDL_SCANCODE_F1: session.previousArena(); break;
                case SDL_SCANCODE_F2: session.nextArena(); break;
                case SDL_SCANCODE_HOME:
                case SDL_SCANCODE_HELP: session.replayArena(); break;
                case SDL_SCANCODE_P: session.togglePause(); break;
                case SDL_SCANCODE_BACKSLASH:
                case SDL_SCANCODE_NONUSBACKSLASH:
                    if (session.reviewPodium())
                        sound.tick(session.sounds(), false, false, true);
                    break;
                default: break;
                }
                if (key >= SDL_SCANCODE_F3 && key <= SDL_SCANCODE_F10 &&
                    !session.paused() && session.phase() != RoundPhase::Podium &&
                    session.phase() != RoundPhase::Statistics) {
                    const unsigned requested = key == SDL_SCANCODE_F10 ? 0 : key - SDL_SCANCODE_F3 + 1;
                    const bool available = sound.selectTrack(requested);
                    prefs.music = available ? requested : 0;
                    shortcutMessage = requested == 0 ? "MUSIC OFF" : "MUSIC " + std::to_string(requested);
                    if (!available)
                        shortcutMessage += " UNAVAILABLE";
                    messageUntil = SDL_GetTicks() + 2000;
                }
            }
            if (event.type == SDL_EVENT_KEY_DOWN && session.phase() != RoundPhase::Podium &&
                session.phase() != RoundPhase::Statistics) {
                auto music = static_cast<int>(prefs.musicVolume);
                auto effects = static_cast<int>(prefs.effectsVolume);
                switch (event.key.scancode) {
                case SDL_SCANCODE_MINUS:
                case SDL_SCANCODE_KP_MINUS: --music; break;
                case SDL_SCANCODE_EQUALS:
                case SDL_SCANCODE_KP_PLUS: ++music; break;
                case SDL_SCANCODE_KP_DIVIDE: --effects; break;
                case SDL_SCANCODE_KP_MULTIPLY: ++effects; break;
                default: break;
                }
                if (music != static_cast<int>(prefs.musicVolume) ||
                    effects != static_cast<int>(prefs.effectsVolume)) {
                    prefs.musicVolume = std::clamp(music, 0, 64);
                    prefs.effectsVolume = std::clamp(effects, 0, 64);
                    sound.setVolumes(prefs.musicVolume, prefs.effectsVolume);
                    shortcutMessage = "MUSIC " + std::to_string(prefs.musicVolume) +
                        "  SOUND " + std::to_string(prefs.effectsVolume);
                    messageUntil = SDL_GetTicks() + 2000;
                }
            }
        }
        const auto now = SDL_GetTicks();
        elapsed += smoke ? 20 : std::min<Uint64>(now - previous, 100);
        previous = now;
        for (; elapsed >= 20; elapsed -= 20) {
            auto input = keyboard.read(session, sharedKeyboard);
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
            const auto reviewing = session.reviewing();
            session.tick(input);
            if (useMenu && !reviewing && previousPhase == RoundPhase::Statistics &&
                session.phase() == RoundPhase::AwaitingPlayers)
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
            check(SDL_RenderPresent(renderer.get()));
            if (smoke) {
                if (session.roundNumber() != 5 || session.score()[1] != 5 ||
                    session.players()[0].control != 0 || session.players()[1].control != 1)
                    throw std::runtime_error("match smoke test lost the score or controller");
                session.skipPodium();
                podium.render(session);
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
        const auto rgb = session.showReady() ? ready.render(std::move(frame), level, bank, boardPalette) :
            levelRgb(frame, boardPalette);
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
        else if (now < messageUntil)
            message = shortcutMessage;
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

MenuResult choose(Menus& menus, const ExtraScreens& extra, SoundOutput& soundtrack, bool showIntro) {
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
    auto intro = texture(renderer.get(), SDL_PIXELFORMAT_RGB24, 640, ScreenArt::Height);
    soundtrack.selectTrack(9);
    soundtrack.tick({}, false, false);
    Gamepads pads;
    Controls previous{};
    unsigned tick = 0;
    unsigned introTick = showIntro ? 0 : 290;
    unsigned slide = 0, slideTick = 0, idle = 0;
    const auto nextSlide = [&] {
        slide = (slide + 1) % 3;
        slideTick = idle = 0;
    };
    auto nextTick = SDL_GetTicks();
    while (true) {
        SDL_Event event{};
        while (SDL_PollEvent(&event)) {
            pads.update(event);
            if (event.type == SDL_EVENT_QUIT)
                return MenuResult::Exit;
            if (event.type != SDL_EVENT_KEY_DOWN)
                continue;
            idle = 0;
            if (introTick < 290) {
                introTick = 290;
                continue;
            }
            if (event.key.key == SDLK_SPACE && !event.key.repeat && menus.mainPage()) {
                nextSlide();
                continue;
            }
            if (slide) {
                slide = 0;
                continue;
            }
            if (menus.mainPage() && event.key.scancode >= SDL_SCANCODE_F1 &&
                event.key.scancode <= SDL_SCANCODE_F4) {
                soundtrack.setMenuVoices(event.key.scancode - SDL_SCANCODE_F1 + 1);
                continue;
            }
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
                    idle = 0;
                    if (introTick < 290 || slide) {
                        introTick = 290;
                        slide = 0;
                        continue;
                    }
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
            const bool opening = introTick < 290;
            if (!opening && !slide && menus.mainPage() && ++idle >= 1000)
                nextSlide();
            if (slide && slideTick >= 1000)
                nextSlide();
            const auto picture = opening ? extra.intro(++introTick) :
                slide ? extra.slideshow(slide, ++slideTick) : menus.render(++tick);
            auto* texture = opening ? intro.get() : screen.get();
            check(SDL_UpdateTexture(texture, nullptr, picture.data(), (opening ? 640 : ScreenArt::Width) * 3));
            check(SDL_RenderClear(renderer.get()));
            check(SDL_RenderTexture(renderer.get(), texture, nullptr, nullptr));
            check(SDL_RenderPresent(renderer.get()));
        }
        SDL_Delay(2);
    }
}

int launch(const std::filesystem::path& root, const std::filesystem::path& sprites,
           const std::filesystem::path& level, bool smoke, MatchOptions options, std::optional<unsigned> track, bool useMenu) {
    check(SDL_Init(SDL_INIT_VIDEO | SDL_INIT_GAMEPAD));
    auto arenas = loadArenaList(root / "binary");
    const auto audio = root / "audio";
    std::filesystem::path settings;
    Preferences prefs;
    if (useMenu) {
        std::unique_ptr<char, decltype(&SDL_free)> folder(SDL_GetPrefPath("Gogo", "LegoBlast"), SDL_free);
        if (folder) {
            settings = std::filesystem::path(reinterpret_cast<const char8_t*>(folder.get())) / "LegoBlast.Prefs";
            prefs = readPreferences(settings);
        }
    }
    if (track)
        prefs.music = *track;
    SoundOutput sound(std::filesystem::is_directory(audio) ? audio : LEGOBLAST_AUDIO_PATH,
                      useMenu ? 9 : prefs.music, smoke);
    sound.setVolumes(prefs.musicVolume, prefs.effectsVolume);
    if (!useMenu) {
        view(root, sprites, level, smoke, options, prefs, sound, arenas);
        return 0;
    }
    Menus menus(sprites.parent_path(), arenas, prefs);
    const ExtraScreens extra(sprites.parent_path(), prefs.gradient);
    bool intro = true;
    while (choose(menus, extra, sound, std::exchange(intro, false)) == MenuResult::Start)
        if (view(root, sprites, menus.levelFile(), false, menus.options(), prefs, sound, arenas, true,
                 menus.sharedKeyboard()) == ViewResult::Closed)
            break;
    if (!settings.empty()) {
        menus.saveOptions(prefs);
        try {
            writePreferences(settings, prefs);
        } catch (const std::exception& error) {
            SDL_Log("LegoBlast preferences: %s", error.what());
        }
    }
    return 0;
}
}

int main(int argc, char* argv[]) {
    struct Quit { ~Quit() { SDL_Quit(); } } quit;
    try {
        MatchOptions options;
        bool smoke = false;
        bool useMenu = argc == 1;
        std::optional<unsigned> track;
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

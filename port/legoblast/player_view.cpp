#include "hud.hpp"
#include "lia.hpp"
#include "presentation.hpp"
#include "network_panel.hpp"
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
enum class ViewResult { Closed, MainMenu, Network };

void check(bool success) {
    if (!success)
        throw std::runtime_error(SDL_GetError());
}

class Keyboard {
public:
    void update(const SDL_Event& event) {
        if (event.type == SDL_EVENT_WINDOW_FOCUS_LOST || event.type == SDL_EVENT_WILL_ENTER_BACKGROUND) {
            held_.fill(false);
            pressed_.fill(false);
            liaRequests_ = 0;
        }
        if (event.type != SDL_EVENT_KEY_DOWN && event.type != SDL_EVENT_KEY_UP)
            return;
        const auto code = event.key.scancode;
        if (code <= SDL_SCANCODE_UNKNOWN || code >= SDL_SCANCODE_COUNT)
            return;
        if (code == SDL_SCANCODE_L && event.type == SDL_EVENT_KEY_DOWN &&
            !held_[code] && !event.key.repeat)
            liaRequests_ = std::min(liaRequests_ + 1, static_cast<unsigned>(PlayerCount));
        held_[code] = event.type == SDL_EVENT_KEY_DOWN;
        if (held_[code] && code >= TouchKeys[0] && code <= TouchKeys[3])
            lastTouchDirection_ = code;
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
#ifdef SDL_PLATFORM_ANDROID
        const auto movementKeys = std::span(TouchKeys).first<4>();
        const auto hasHeldDirection = std::ranges::any_of(movementKeys, [&](auto key) { return held_[key]; });
        const auto direction = [&](SDL_Scancode key) {
            return held_[key] || (!hasHeldDirection && pressed_[key] && lastTouchDirection_ == key);
        };
        input[static_cast<std::size_t>(Control::Touch)] = {
            direction(TouchKeys[0]), direction(TouchKeys[1]),
            direction(TouchKeys[2]), direction(TouchKeys[3]), down(TouchKeys[4])};
#endif
        pressed_.fill(false);
        return input;
    }

    unsigned takeLiaRequests() { return std::exchange(liaRequests_, 0); }

private:
    std::array<bool, SDL_SCANCODE_COUNT> held_{}, pressed_{};
    SDL_Scancode lastTouchDirection_{SDL_SCANCODE_UNKNOWN};
    unsigned liaRequests_{};
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
    key.type = SDL_EVENT_KEY_DOWN;
    key.key.scancode = SDL_SCANCODE_L;
    keyboard.update(key);
    if (keyboard.takeLiaRequests() != 1)
        throw std::runtime_error("Lia lost its separate join key");
    key.key.repeat = true;
    keyboard.update(key);
    if (keyboard.takeLiaRequests())
        throw std::runtime_error("a held key summoned another Lia");
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

std::string_view matchShortcut(SDL_Scancode key) {
    constexpr std::array music{"M1", "M2", "M3", "M4", "M5", "M6", "M7", "M0"};
    if (key >= SDL_SCANCODE_F3 && key <= SDL_SCANCODE_F10)
        return music[key - SDL_SCANCODE_F3];
    switch (key) {
    case SDL_SCANCODE_F1: return "PREV";
    case SDL_SCANCODE_F2: return "NEXT";
    case SDL_SCANCODE_HOME:
    case SDL_SCANCODE_HELP: return "REPLAY";
    case SDL_SCANCODE_P: return "PAUSE";
    case SDL_SCANCODE_BACKSLASH:
    case SDL_SCANCODE_NONUSBACKSLASH: return "PODIUM";
    default: return {};
    }
}

bool adjustVolume(SDL_Scancode key, Preferences& prefs, SoundOutput& sound, std::string& message) {
    auto music = static_cast<int>(prefs.musicVolume);
    auto effects = static_cast<int>(prefs.effectsVolume);
    switch (key) {
    case SDL_SCANCODE_MINUS:
    case SDL_SCANCODE_KP_MINUS: --music; break;
    case SDL_SCANCODE_EQUALS:
    case SDL_SCANCODE_KP_PLUS: ++music; break;
    case SDL_SCANCODE_KP_DIVIDE: --effects; break;
    case SDL_SCANCODE_KP_MULTIPLY: ++effects; break;
    default: return false;
    }
    prefs.musicVolume = std::clamp(music, 0, 64);
    prefs.effectsVolume = std::clamp(effects, 0, 64);
    sound.setVolumes(prefs.musicVolume, prefs.effectsVolume);
    message = "MUSIC " + std::to_string(prefs.musicVolume) + "  SOUND " + std::to_string(prefs.effectsVolume);
    return true;
}

Buttons networkInput(const Controls& inputs) {
    unsigned buttons = 0;
    for (auto control : {Control::Joy0, Control::Joy1, Control::Joy3, Control::Joy4, Control::Keyboard1, Control::Touch})
        buttons |= packInput(inputs[static_cast<std::size_t>(control)]);
    return unpackInput(buttons);
}

void copyNetworkBoard(Bytes& destination, const Bytes& board, const Bytes& bar) {
    destination.assign(NetPixels, 0);
    for (int y = 0; y < BoardHeight; ++y)
        std::copy_n(board.data() + y * BoardWidth * 3, BoardWidth * 3,
                    destination.data() + (y * NetWidth + BoardX) * 3);
    const auto sourceWidth = bar.size() / (Hud::Height * 3);
    for (int y = 0; y < Hud::Height; ++y)
        for (int x = 0; x < NetWidth; ++x)
            std::copy_n(bar.data() + (y * sourceWidth + x * sourceWidth / NetWidth) * 3, 3,
                        destination.data() + ((BoardHeight + y) * NetWidth + x) * 3);
}

void copyNetworkSprite(Bytes& destination, const Bytes& sprite, Point center) {
    for (int sy = 0; sy < SpriteHeight; ++sy)
        for (int sx = 0; sx < SpriteWidth; ++sx) {
            const auto x = BoardX + center.x - 7 + sx, y = center.y - 20 + sy;
            const auto pixel = (sy * SpriteWidth + sx) * 4;
            if (x >= 0 && x < NetWidth && y >= 0 && y < NetHeight && sprite[pixel + 3])
                std::copy_n(sprite.data() + pixel, 3, destination.data() + (y * NetWidth + x) * 3);
        }
}

ViewResult view(const std::filesystem::path& root, const std::filesystem::path& spriteFile,
         const std::filesystem::path& levelFile, bool smoke, MatchOptions options, Preferences& prefs, SoundOutput& sound,
         const std::vector<ArenaEntry>& arenaList, const LiaModel* liaModel, Presentation& display,
         bool useMenu = false, bool sharedKeyboard = false, NetworkPanel* online = nullptr, bool hosting = false) {
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
    LiaGroup lias;
    std::array<Lia, NetworkPlaces> networkLias{};
    std::array<unsigned, NetworkPlaces> botAction{};
    unsigned botTick{}, botRound{};
    unsigned microMask = 0;
    NetFrame networkFrame;
    networkFrame.track = prefs.music;
    networkFrame.trackRevision = 1;
    std::uint64_t musicStart = SDL_GetTicks();
    std::uint64_t nextBroadcast = 0;
    bool wasModal = false;
    if (hosting) {
        online->link.beginMatch();
        for (unsigned i = 0; i < NetworkPlaces; ++i)
            if (online->link.room->roster[i] == 'M') microMask |= 1u << i;
    }

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
    display.configure(ScreenWidth, ScreenHeight, true);
    auto* renderer = display.renderer();
    auto background = texture(renderer, SDL_PIXELFORMAT_RGB24, BoardWidth, BoardHeight);
    auto bar = texture(renderer, SDL_PIXELFORMAT_RGB24, Hud::Width, Hud::Height);
    auto wood = texture(renderer, SDL_PIXELFORMAT_RGB24, ScreenWidth, Hud::Height);
    auto podiumTexture = texture(renderer, SDL_PIXELFORMAT_RGB24, ScreenArt::Width, ScreenArt::Height);
    auto sprite = texture(renderer, SDL_PIXELFORMAT_RGBA32, SpriteWidth, SpriteHeight);
    check(SDL_SetTextureBlendMode(sprite.get(), SDL_BLENDMODE_BLEND));

    auto previous = SDL_GetTicks();
    Uint64 elapsed = 0;
    Uint64 messageUntil = 0;
    std::string shortcutMessage;
    const auto apply = [&](std::string_view command) {
        if (command == "PREV") session.previousArena();
        else if (command == "NEXT") session.nextArena();
        else if (command == "REPLAY") session.replayArena();
        else if (command == "PAUSE") session.togglePause();
        else if (command == "SKIP" && session.phase() == RoundPhase::Podium) session.skipPodium();
        else if (command == "PODIUM") {
            if (session.reviewPodium()) {
                sound.tick(session.sounds(), false, false, true);
                if (hosting) networkFrame.sounds.insert(networkFrame.sounds.end(), session.sounds().begin(), session.sounds().end());
            }
        } else if (command.size() == 2 && command[0] == 'M' && command[1] >= '0' && command[1] <= '7' &&
            !session.paused() && session.phase() != RoundPhase::Podium && session.phase() != RoundPhase::Statistics) {
            const unsigned requested = command[1] - '0';
            const bool available = sound.selectTrack(requested);
            if (hosting) {
                if (networkFrame.track != requested) {
                    networkFrame.track = requested;
                    ++networkFrame.trackRevision;
                    musicStart = SDL_GetTicks();
                }
            } else {
                prefs.music = available ? requested : 0;
            }
            shortcutMessage = requested ? "MUSIC " + std::to_string(requested) : "MUSIC OFF";
            if (!available) shortcutMessage += " UNAVAILABLE";
            messageUntil = SDL_GetTicks() + 2000;
        }
    };
    const auto broadcast = [&] {
        networkFrame.flags = unsigned(session.paused()) |
            unsigned(session.phase() == RoundPhase::Result || session.phase() == RoundPhase::MatchComplete) << 1 |
            unsigned(session.phase() == RoundPhase::Podium || session.phase() == RoundPhase::Statistics) << 2;
        networkFrame.status = SDL_GetTicks() < messageUntil ? shortcutMessage : "";
        networkFrame.musicMs = static_cast<std::uint32_t>(SDL_GetTicks() - musicStart);
        online->link.sendFrame(networkFrame);
        networkFrame.sounds.clear();
        nextBroadcast = SDL_GetTicks() + 40;
    };
    bool running = true;
    while (running) {
        if (online) {
            online->link.poll(SDL_GetTicks());
            if (hosting && !online->link.room) return ViewResult::MainMenu;
            if (!hosting && online->link.room && online->link.room->started) return ViewResult::Network;
            const bool modal = online->modal();
            if (modal && !wasModal) display.releaseControls();
            wasModal = modal;
            while (hosting && !online->link.commands.empty()) {
                apply(online->link.commands.front());
                online->link.commands.pop_front();
            }
        }
        SDL_Event event{};
        while (SDL_PollEvent(&event)) {
            if (event.type != SDL_EVENT_KEY_DOWN) keyboard.update(event);
            if (online && online->handle(event, renderer, true)) continue;
            if (display.handle(event))
                continue;
            pads.update(event);
            if (event.type == SDL_EVENT_KEY_DOWN) keyboard.update(event);
            if (event.type == SDL_EVENT_KEY_DOWN && (event.key.key == SDLK_ESCAPE || event.key.key == SDLK_AC_BACK) && !event.key.repeat) {
                if (session.phase() == RoundPhase::Podium) {
                    session.skipPodium();
                    continue;
                }
                if (useMenu)
                    return ViewResult::MainMenu;
            }
            if (event.type == SDL_EVENT_QUIT ||
                (event.type == SDL_EVENT_KEY_DOWN && (event.key.key == SDLK_ESCAPE || event.key.key == SDLK_AC_BACK) && !event.key.repeat))
                running = false;
            if (event.type == SDL_EVENT_KEY_DOWN) {
                if (!event.key.repeat) apply(matchShortcut(event.key.scancode));
                if (session.phase() != RoundPhase::Podium && session.phase() != RoundPhase::Statistics &&
                    adjustVolume(event.key.scancode, prefs, sound, shortcutMessage))
                    messageUntil = SDL_GetTicks() + 2000;
            }
        }
        const auto now = SDL_GetTicks();
        elapsed += smoke ? 20 : std::min<Uint64>(now - previous, 100);
        previous = now;
        for (; elapsed >= 20; elapsed -= 20) {
            auto input = keyboard.read(session, sharedKeyboard);
            pads.read(input);
            const auto summon = keyboard.takeLiaRequests();
            if (online && online->modal()) input = {};
            if (hosting) {
                input = online->link.humanInputs(networkInput(input));
                const auto tick = session.elapsed();
                if (tick < botTick || botRound != session.roundNumber()) {
                    for (auto& bot : networkLias) bot.reset();
                    botAction.fill(0);
                }
                botRound = session.roundNumber();
                botTick = tick;
                if (liaPlaying(session) && !session.paused()) {
                    for (unsigned i = 0; i < NetworkPlaces; ++i) {
                        const auto& player = session.players()[i];
                        if (!player.dead && player.activation == Activation::Hidden) {
                            input[i].fire = true;
                        } else if (online->link.room->roster[i] == 'L' && liaAlive(player)) {
                            const auto step = (tick + LiaActionTicks - i) % LiaActionTicks;
                            if (!step) botAction[i] = networkLias[i].choose(session, i, liaModel);
                            input[i] = liaButtons(botAction[i], step);
                        }
                    }
                }
            } else if ((!online || !online->modal()) && lias.read(session, input, summon, liaModel)) {
                shortcutMessage = "LIA";
                messageUntil = SDL_GetTicks() + 2000;
            }
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
            if (!hosting || online->link.connected) session.tick(input, true, microMask);
            if (hosting && online->link.connected && networkFrame.sounds.size() < 32)
                networkFrame.sounds.insert(networkFrame.sounds.end(), session.sounds().begin(), session.sounds().end());
            if (useMenu && !hosting && !reviewing && previousPhase == RoundPhase::Statistics &&
                session.phase() == RoundPhase::AwaitingPlayers)
                return ViewResult::MainMenu;
            sound.tick(session.sounds(), session.paused(),
                       session.phase() == RoundPhase::Result || session.phase() == RoundPhase::MatchComplete,
                       session.phase() == RoundPhase::Podium || session.phase() == RoundPhase::Statistics);
        }
        if (session.phase() == RoundPhase::Podium || session.phase() == RoundPhase::Statistics) {
            const auto picture = podium.render(session);
            check(SDL_UpdateTexture(podiumTexture.get(), nullptr, picture.data(), ScreenArt::Width * 3));
            display.beginFrame();
            const SDL_FRect fullScreen{0, 0, ScreenArt::Width, ScreenArt::Height};
            check(SDL_RenderTexture(renderer, podiumTexture.get(), nullptr, &fullScreen));
            if (hosting && now >= nextBroadcast) {
                networkFrame.pixels = picture;
                networkFrame.pixels.resize(NetPixels);
                broadcast();
            }
            display.present({}, online, true);
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
        display.beginFrame();
        const SDL_FRect boardBox{BoardX, 0, BoardWidth, BoardHeight};
        check(SDL_RenderTexture(renderer, background.get(), nullptr, &boardBox));
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
        const bool capture = hosting && now >= nextBroadcast;
        if (message.empty()) {
            check(SDL_RenderTexture(renderer, bar.get(), nullptr, &barBox));
            if (capture) copyNetworkBoard(networkFrame.pixels, rgb, barRgb);
        } else {
            const auto woodRgb = levelRgb(hud.wood(), boardPalette);
            if (capture) copyNetworkBoard(networkFrame.pixels, rgb, woodRgb);
            check(SDL_UpdateTexture(wood.get(), nullptr, woodRgb.data(), ScreenWidth * 3));
            check(SDL_RenderTexture(renderer, wood.get(), nullptr, &barBox));
            check(SDL_SetRenderDrawColor(renderer, 255, 255, 255, 255));
            check(SDL_RenderDebugText(renderer, (ScreenWidth - message.size() * SDL_DEBUG_TEXT_FONT_CHARACTER_SIZE) / 2.0f,
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
            if (capture) copyNetworkSprite(networkFrame.pixels, image, point);
            const SDL_FRect box{float(BoardX + point.x - 7), float(point.y - 20), SpriteWidth, SpriteHeight};
            check(SDL_RenderTexture(renderer, sprite.get(), nullptr, &box));
        }
        if (capture) {
            broadcast();
        }
        display.present(now < messageUntil ? std::string_view(shortcutMessage) : std::string_view{}, online, true);
        if (smoke && smokeFrame >= 6000)
            throw std::runtime_error("match smoke test did not reach the podium");
        if (!smoke)
            SDL_Delay(2);
    }
    return ViewResult::Closed;
}

ViewResult viewGuest(const Level& level, Preferences& prefs, SoundOutput& sound,
                     Presentation& display, NetworkPanel& online) {
    // The guest uses a Session only for the existing keyboard mapping. It never advances it.
    const Session controllerLayout(level);
    display.configure(NetWidth, NetHeight, true);
    auto* renderer = display.renderer();
    const auto screen = texture(renderer, SDL_PIXELFORMAT_RGB24, NetWidth, NetHeight);
    Keyboard keyboard;
    Gamepads pads;
    std::uint32_t trackRevision = 0;
    bool wasModal = false;
    auto nextInput = SDL_GetTicks();

    while (true) {
        const auto now = SDL_GetTicks();
        online.link.poll(now);
        if (!online.link.room) return ViewResult::MainMenu;
        if (!online.link.connected) trackRevision = 0;
        const bool modal = online.modal();
        if (modal && !wasModal) display.releaseControls();
        wasModal = modal;

        SDL_Event event{};
        while (SDL_PollEvent(&event)) {
            if (event.type != SDL_EVENT_KEY_DOWN) keyboard.update(event);
            if (online.handle(event, renderer, true) || display.handle(event)) continue;
            pads.update(event);
            if (event.type == SDL_EVENT_QUIT) return ViewResult::Closed;
            if (event.type != SDL_EVENT_KEY_DOWN) continue;
            keyboard.update(event);
            if (event.key.key == SDLK_ESCAPE || event.key.key == SDLK_AC_BACK) {
                if (online.link.frames.image().flags & 4) {
                    online.link.send("C SKIP");
                    continue;
                }
                return ViewResult::MainMenu;
            }
            const auto command = matchShortcut(event.key.scancode);
            if (!event.key.repeat && !command.empty())
                online.link.send("C " + std::string(command));
            std::string localVolume;
            adjustVolume(event.key.scancode, prefs, sound, localVolume);
        }
        if (now >= nextInput) {
            auto controls = keyboard.read(controllerLayout, false);
            keyboard.takeLiaRequests();
            pads.read(controls);
            online.link.sendInput(modal ? Buttons{} : networkInput(controls));
            nextInput = now + 20;
        }

        const auto& frame = online.link.frames.image();
        if (online.link.connected && frame.trackRevision != trackRevision) {
            trackRevision = frame.trackRevision;
            if (sound.selectTrack(frame.track)) sound.seekTrack(frame.musicMs);
        }
        sound.tick(online.link.frames.takeSounds(), frame.flags & 1, frame.flags & 2, frame.flags & 4);
        display.beginFrame();
        if (frame.pixels.size() == NetPixels) {
            check(SDL_UpdateTexture(screen.get(), nullptr, frame.pixels.data(), NetWidth * 3));
            const SDL_FRect target{0, 0, NetWidth, NetHeight};
            check(SDL_RenderTexture(renderer, screen.get(), nullptr, &target));
        }
        const auto status = !online.link.connected ? "RECONNEXION..." : frame.pixels.empty() ? "EN ATTENTE DE L'HOTE" :
            (frame.flags & 1) ? "PAUSE" : frame.status.c_str();
        if (*status) {
            check(SDL_SetRenderDrawColor(renderer, 255, 255, 255, 255));
            check(SDL_RenderDebugText(renderer, (NetWidth - 8.f * SDL_strlen(status)) / 2, BoardHeight + 5, status));
        }
        display.present(status, &online, true);
        SDL_Delay(8);
    }
}

MenuResult choose(Menus& menus, const ExtraScreens& extra, SoundOutput& soundtrack, bool showIntro,
                  Presentation& display, NetworkPanel& online) {
    display.configure(ScreenArt::Width, ScreenArt::Height, false);
    auto* renderer = display.renderer();
    auto screen = texture(renderer, SDL_PIXELFORMAT_RGB24, ScreenArt::Width, ScreenArt::Height);
    auto intro = texture(renderer, SDL_PIXELFORMAT_RGB24, 640, ScreenArt::Height);
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
        online.link.poll(SDL_GetTicks());
        if (online.link.room && online.link.room->started) return MenuResult::Network;
        SDL_Event event{};
        while (SDL_PollEvent(&event)) {
            if (online.handle(event, renderer, false) || display.handle(event))
                continue;
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
            case SDLK_AC_BACK:
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
        if (!online.modal()) pads.read(input);
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
            display.beginFrame();
            const SDL_FRect content{0, 0, ScreenArt::Width, ScreenArt::Height};
            check(SDL_RenderTexture(renderer, texture, nullptr, &content));
            display.present({}, &online);
        }
        SDL_Delay(2);
    }
}

int launch(const std::filesystem::path& root, const std::filesystem::path& sprites,
           const std::filesystem::path& level, bool smoke, MatchOptions options, std::optional<unsigned> track, bool useMenu, const LiaModel* liaModel, std::string url) {
    check(SDL_Init(SDL_INIT_VIDEO | SDL_INIT_GAMEPAD));
    Presentation display(ScreenWidth, useMenu ? ScreenArt::Height : ScreenHeight);
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
        view(root, sprites, level, smoke, options, prefs, sound, arenas, liaModel, display);
        return 0;
    }
    Menus menus(sprites.parent_path(), arenas, prefs);
    const ExtraScreens extra(sprites.parent_path(), prefs.gradient);
    NetworkPanel online(std::move(url), settings.empty() ? std::filesystem::path{} : settings.parent_path() / "Network.enabled");
    bool intro = true;
    bool closed = false;
    while (!closed) {
        const auto action = choose(menus, extra, sound, std::exchange(intro, false), display, online);
        if (action == MenuResult::Exit) break;
        auto result = ViewResult::Network;
        if (action == MenuResult::Start)
            result = view(root, sprites, menus.levelFile(), false, menus.options(), prefs, sound, arenas, liaModel, display,
                          true, menus.sharedKeyboard(), &online);
        if (result == ViewResult::Network && online.link.room) {
            online.started();
            if (online.link.room->host)
                result = view(root, sprites, menus.levelFile(), false, menus.options(), prefs, sound, arenas, liaModel,
                              display, true, menus.sharedKeyboard(), &online, true);
            else
                result = viewGuest(loadLevel(level), prefs, sound, display, online);
            online.link.leave();
        }
        closed = result == ViewResult::Closed;
    }
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
        std::optional<LiaModel> liaModel;
        std::string url = "wss://legoblast.elom75.workers.dev/v1/socket";
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
            else if (arg.starts_with("--network-url="))
                url = std::string(arg.substr(14));
            else if (arg.starts_with("--lia-model="))
                liaModel.emplace(std::filesystem::path(arg.substr(12)));
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
#ifdef SDL_PLATFORM_ANDROID
            const char* base = SDL_GetAndroidInternalStoragePath();
#else
            const char* base = SDL_GetBasePath();
#endif
            if (!base)
                throw std::runtime_error(SDL_GetError());
            const std::filesystem::path root = std::filesystem::path(reinterpret_cast<const char8_t*>(base)) / "data";
            return launch(root, root / "binary/LEGO_SPRITES.DAT",
                          root / "binary" / ("Lego_Level" + std::string(number) + ".dat"),
                          smoke, options, track, useMenu && !smoke, liaModel ? &*liaModel : nullptr, url);
        }
        if (paths.size() != 3)
            throw std::runtime_error("usage: legoblast_players [LEVEL | AMIGA_SRC SPRITES LEVEL.dat] "
                                     "[--free] [--teams | --survivor] [--sequential | --random | --dyna] [--lia-model=FILE]");
        return launch(paths[0], paths[1], paths[2], smoke, options, track, useMenu && !smoke, liaModel ? &*liaModel : nullptr, url);
    } catch (const std::exception& error) {
        SDL_LogError(SDL_LOG_CATEGORY_APPLICATION, "%s", error.what());
        std::cerr << error.what() << '\n';
        return 1;
    }
}

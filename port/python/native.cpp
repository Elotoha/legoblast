#include "match_art.hpp"
#include "network_match.hpp"

#include <cstring>
#include <fstream>
#include <optional>
#include <stdexcept>

using namespace legoblast;

#ifdef _WIN32
#define LB_API extern "C" __declspec(dllexport)
#else
#define LB_API extern "C" __attribute__((visibility("default")))
#endif

namespace {
enum Mode : unsigned { Menu, Local, Host, Guest };

struct State {
    std::uint32_t mode, phase, arena, round, elapsed, players, bombs;
    std::uint32_t track, revision, musicMs, musicVolume, effectsVolume, voices, flags;
    std::uint32_t networkEnabled, connected, seat, sharedKeyboard, mainPage;
    char room[8], roster[8], offer[8], notice[64], message[64];
};

thread_local std::string error;

template<class F, class Result>
auto guarded(F&& function, Result fallback) -> decltype(function()) {
    try {
        return function();
    } catch (const std::exception& failure) {
        error = failure.what();
        return fallback;
    }
}

std::filesystem::path fromUtf8(const char* path) {
    return std::filesystem::path(reinterpret_cast<const char8_t*>(path));
}

template<std::size_t Size>
void text(char (&destination)[Size], std::string_view source) {
    const auto count = std::min(Size - 1, source.size());
    if (count) std::memcpy(destination, source.data(), count);
    destination[count] = '\0';
}

class Runtime {
public:
    Runtime(std::filesystem::path root, std::filesystem::path settings, std::string endpoint)
        : root_(std::move(root)), settings_(std::move(settings)), binary_(root_ / "binary"),
          prefs_(readPreferences(settings_ / "LegoBlast.Prefs")), arenas_(loadArenaList(binary_)),
          menus_(binary_, arenas_, prefs_), extra_(binary_, prefs_.gradient),
          art_(root_, binary_ / "LEGO_SPRITES.DAT"), network_(std::move(endpoint)) {
        network_.enable(std::ifstream(settings_ / "Network.enabled").get() == '1');
    }

    void save() {
        menus_.saveOptions(prefs_);
        writePreferences(settings_ / "LegoBlast.Prefs", prefs_);
        std::ofstream(settings_ / "Network.enabled") << (network_.enabled ? '1' : '0');
    }

    void start(unsigned arena, Mode mode = Local) {
        auto options = menus_.options();
        auto path = menus_.levelFile();
        if (arena) {
            const auto found = std::ranges::find(arenas_, arena, &ArenaEntry::number);
            if (found == arenas_.end()) throw std::runtime_error("Arène absente des ressources");
            path = found->file;
            options = {};
        }
        session_.emplace(makeSession(binary_, path, options, arenas_));
        lias_ = {};
        bots_ = {};
        mode_ = mode;
        message_.clear();
        effects_.clear();
        networkEffects_.clear();
        network_.beginMatch();
        selectTrack(prefs_.music, true);
        nextBroadcast_ = 0;
    }

    bool menuKey(unsigned key) {
        if (mode_ != Menu || key > static_cast<unsigned>(MenuInput::Back)) return false;
        switch (menus_.handle(static_cast<MenuInput>(key))) {
        case MenuResult::Start: start(0); return false;
        case MenuResult::Exit: return true;
        default: return false;
        }
    }

    void menuVoices(unsigned count) { voices_ = std::clamp(count, 1u, 4u); }

    void poll(std::uint64_t now) {
        now_ = now;
        network_.poll(now);
        const bool remoteMatch = mode_ == Host || mode_ == Guest;
        if (remoteMatch && !network_.room) menu();
        if (!remoteMatch && network_.room && network_.room->started) {
            if (network_.room->host) {
                start(0, Host);
            } else {
                mode_ = Guest;
                effects_.clear();
                session_.reset();
                message_.clear();
            }
        }
        while (mode_ == Host && !network_.commands.empty()) {
            matchKey(network_.commands.front());
            network_.commands.pop_front();
        }
        if (mode_ == Guest)
            collect(network_.frames.takeSounds(), effects_);
    }

    void tick(const std::uint8_t* buttons, unsigned summons) {
        Controls input{};
        for (std::size_t i = 0; i < input.size(); ++i) input[i] = unpackInput(buttons[i]);
        unsigned packed = 0;
        for (auto control : {Control::Joy0, Control::Joy1, Control::Joy3, Control::Joy4, Control::Keyboard1})
            packed |= packInput(input[static_cast<std::size_t>(control)]);
        const auto player = unpackInput(packed);
        if (mode_ == Guest) {
            network_.sendInput(player);
            return;
        }
        if (!session_ || (mode_ == Host && !network_.connected)) return;
        unsigned micros = 0;
        if (mode_ == Host) {
            input = network_.humanInputs(player);
            bots_.fill(*session_, input, network_.room->roster);
            micros = NetworkBots::microMask(network_.room->roster);
        } else if (lias_.read(*session_, input, summons)) {
            notify("LIA");
        }
        const bool wasStatistics = session_->phase() == RoundPhase::Statistics && !session_->reviewing();
        session_->tick(input, true, micros);
        cues();
        if (mode_ == Local && wasStatistics && session_->phase() == RoundPhase::AwaitingPlayers)
            menu();
    }

    void command(std::string_view command) {
        if (mode_ == Guest) {
            if (command == "BACK" && !(network_.frames.image().flags & 4)) leave();
            else network_.send("C " + std::string(command == "BACK" ? "SKIP" : command));
        } else if (command == "BACK" && session_) {
            if (session_->phase() == RoundPhase::Podium) session_->skipPodium();
            else if (mode_ == Host) leave();
            else menu();
        } else {
            matchKey(command);
        }
    }

    void online(std::string_view command) {
        if (command == "TOGGLE") {
            network_.enable(!network_.enabled);
            std::ofstream(settings_ / "Network.enabled") << (network_.enabled ? '1' : '0');
        } else if (command == "JOIN" && !network_.offer.empty()) {
            network_.send("JOIN " + network_.offer);
            network_.decline();
        } else if (command == "DECLINE") {
            network_.decline();
        } else if (command == "LEAVE") {
            leave();
        } else if (command == "CREATE" || command == "ADD L" || command == "ADD M" || command == "REMOVE") {
            network_.send(command);
        }
    }

    void volume(bool effects, int delta) {
        auto& value = effects ? prefs_.effectsVolume : prefs_.musicVolume;
        value = std::clamp(static_cast<int>(value) + std::clamp(delta, -64, 64), 0, 64);
    }

    const Bytes& render(unsigned scene, unsigned tick, int& width, int& height) {
        width = ScreenArt::Width;
        height = ScreenArt::Height;
        if (mode_ == Guest) {
            height = ScreenHeight;
            const auto& frame = network_.frames.image();
            if (!frame.pixels.empty()) return frame.pixels;
            pixels_.assign(ScreenBytes, 0);
        } else if (session_) {
            height = ScreenHeight;
            pixels_ = art_.frame(*session_, !statusText().empty());
            if (mode_ == Host && now_ >= nextBroadcast_ && network_.connected) {
                NetFrame frame;
                frame.pixels = pixels_;
                frame.status = std::string(statusText());
                frame.flags = audioFlags();
                frame.track = track_;
                frame.trackRevision = trackRevision_;
                frame.musicMs = static_cast<std::uint32_t>(now_ - musicStart_);
                frame.sounds.swap(networkEffects_);
                network_.sendFrame(frame);
                nextBroadcast_ = now_ + 40;
            }
        } else if (scene == 1) {
            width = 640;
            pixels_ = extra_.intro(tick);
        } else if (scene == 2 || scene == 3) {
            pixels_ = extra_.slideshow(scene - 1, tick);
        } else {
            pixels_ = menus_.render(tick);
        }
        return pixels_;
    }

    State state() const {
        State result{};
        result.mode = mode_;
        if (session_) {
            result.phase = static_cast<unsigned>(session_->phase());
            result.arena = session_->arena().number;
            result.round = session_->roundNumber();
            result.elapsed = session_->elapsed();
            result.players = std::ranges::count_if(session_->players(), liaAlive);
            result.bombs = std::ranges::count_if(session_->bombs().bombs(), &Bomb::active);
        }
        result.track = track_;
        result.revision = trackRevision_;
        if (mode_ == Guest) {
            const auto& frame = network_.frames.image();
            result.track = frame.track;
            result.revision = frame.trackRevision;
            result.musicMs = frame.musicMs;
        }
        result.musicVolume = prefs_.musicVolume;
        result.effectsVolume = prefs_.effectsVolume;
        result.voices = voices_;
        result.flags = audioFlags();
        result.networkEnabled = network_.enabled;
        result.connected = network_.connected;
        result.sharedKeyboard = menus_.sharedKeyboard();
        result.mainPage = menus_.mainPage();
        if (network_.room) {
            text(result.room, network_.room->code);
            text(result.roster, network_.room->roster);
            result.seat = network_.room->seat;
        }
        text(result.offer, network_.offer);
        text(result.notice, network_.notice);
        text(result.message, statusText());
        return result;
    }

    unsigned readSounds(int* triples, unsigned limit) {
        const auto count = static_cast<unsigned>(std::min<std::size_t>(limit, effects_.size()));
        for (unsigned i = 0; i < count; ++i) {
            triples[3 * i] = static_cast<int>(effects_[i].cue);
            triples[3 * i + 1] = effects_[i].priority;
            triples[3 * i + 2] = effects_[i].repetitions;
        }
        effects_.erase(effects_.begin(), effects_.begin() + count);
        return count;
    }

private:
    void menu() {
        session_.reset();
        mode_ = Menu;
        message_.clear();
        effects_.clear();
        selectTrack(9, true);
    }

    void leave() {
        network_.leave();
        if (mode_ == Host || mode_ == Guest) menu();
    }

    unsigned audioFlags() const {
        if (mode_ == Guest) return network_.frames.image().flags;
        if (!session_) return 0;
        const auto phase = session_->phase();
        return unsigned(session_->paused()) |
            unsigned(phase == RoundPhase::Result || phase == RoundPhase::MatchComplete) << 1 |
            unsigned(phase == RoundPhase::Podium || phase == RoundPhase::Statistics) << 2;
    }

    void selectTrack(unsigned track, bool reload = false) {
        if (reload || track_ != track) {
            track_ = track;
            ++trackRevision_;
            musicStart_ = now_;
        }
    }

    void matchKey(std::string_view command) {
        if (!session_) return;
        if (command == "PODIUM") {
            if (session_->reviewPodium()) cues();
        } else if (command.size() == 2 && command[0] == 'M' && command[1] >= '0' && command[1] <= '7' &&
                   !(audioFlags() & 5)) {
            const unsigned track = command[1] - '0';
            const bool available = track == 0 || std::filesystem::is_regular_file(
                root_ / "audio" / ("Mod_Game" + std::to_string(track) + ".flac"));
            selectTrack(track);
            if (mode_ == Local) prefs_.music = available ? track : 0;
            notify(track ? "MUSIC " + std::to_string(track) + (available ? "" : " UNAVAILABLE") : "MUSIC OFF");
        } else {
            applyMatchCommand(*session_, command);
        }
    }

    void notify(std::string message) {
        message_ = std::move(message);
        messageUntil_ = now_ + 2000;
    }

    std::string_view statusText() const {
        if (mode_ == Guest) {
            if (!network_.connected) return "RECONNEXION...";
            const auto& frame = network_.frames.image();
            if (frame.pixels.empty()) return "EN ATTENTE DE L'HOTE";
            return frame.status;
        }
        if (mode_ == Host && !network_.connected) return "RECONNEXION...";
        if (session_ && session_->paused()) return "PAUSE";
        if (session_ && session_->phase() == RoundPhase::AwaitingPlayers && session_->retrying())
            return session_->survivorMode() ? "SURVIVOR" : "DON'T MOVE";
        return now_ < messageUntil_ ? std::string_view(message_) : std::string_view{};
    }

    static void collect(std::span<const SoundRequest> source, std::vector<SoundRequest>& output) {
        const auto count = std::min(source.size(), 32 - output.size());
        output.insert(output.end(), source.begin(), source.begin() + count);
    }

    void cues() {
        collect(session_->sounds(), effects_);
        if (mode_ == Host) collect(session_->sounds(), networkEffects_);
    }

    std::filesystem::path root_, settings_, binary_;
    Preferences prefs_;
    std::vector<ArenaEntry> arenas_;
    Menus menus_;
    ExtraScreens extra_;
    MatchArt art_;
    Network network_;
    std::optional<Session> session_;
    LiaGroup lias_;
    NetworkBots bots_;
    Mode mode_{Menu};
    unsigned track_{9}, trackRevision_{1}, voices_{4};
    std::uint64_t now_{}, nextBroadcast_{}, musicStart_{}, messageUntil_{};
    std::string message_;
    Bytes pixels_;
    std::vector<SoundRequest> effects_, networkEffects_;
};
}

LB_API unsigned lb_abi() { return 1; }
LB_API unsigned lb_controls() { return static_cast<unsigned>(Control::Count); }
LB_API const char* lb_error() { return error.c_str(); }
LB_API Runtime* lb_open(const char* root, const char* settings, const char* endpoint) {
    return guarded([&] { return new Runtime(fromUtf8(root), fromUtf8(settings), endpoint); }, nullptr);
}
LB_API void lb_close(Runtime* game) { delete game; }
LB_API int lb_save(Runtime* game) { return guarded([&] { game->save(); return 0; }, -1); }
LB_API int lb_start(Runtime* game, unsigned arena) { return guarded([&] { game->start(arena); return 0; }, -1); }
LB_API int lb_menu(Runtime* game, unsigned key) { return guarded([&] { return int(game->menuKey(key)); }, -1); }
LB_API void lb_voices(Runtime* game, unsigned count) { game->menuVoices(count); }
LB_API int lb_poll(Runtime* game, std::uint64_t now) { return guarded([&] { game->poll(now); return 0; }, -1); }
LB_API int lb_tick(Runtime* game, const std::uint8_t* buttons, unsigned summons) {
    return guarded([&] { game->tick(buttons, summons); return 0; }, -1);
}
LB_API int lb_command(Runtime* game, const char* command) {
    return guarded([&] { game->command(command); return 0; }, -1);
}
LB_API int lb_network(Runtime* game, const char* command) {
    return guarded([&] { game->online(command); return 0; }, -1);
}
LB_API void lb_volume(Runtime* game, int effects, int delta) { game->volume(effects, delta); }
LB_API unsigned lb_sounds(Runtime* game, int* triples, unsigned limit) { return game->readSounds(triples, limit); }
LB_API void lb_state(Runtime* game, State* state) { *state = game->state(); }
LB_API const std::uint8_t* lb_picture(Runtime* game, unsigned scene, unsigned tick, int* width, int* height) {
    return guarded([&] { return game->render(scene, tick, *width, *height).data(); }, nullptr);
}

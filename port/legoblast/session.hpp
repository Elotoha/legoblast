#pragma once

#include "bombs.hpp"
#include "players.hpp"

namespace legoblast {
enum class RoundPhase { AwaitingPlayers, Running, Draining, Result, MatchComplete, Podium, Statistics };
enum class ArenaMode { Fixed, Sequential, Random, Dynablaster };
struct MatchOptions {
    bool fiveWins{true};
    bool teams{};
    bool survivor{};
    ArenaMode arena{ArenaMode::Fixed};
};
struct ClosingFrame {
    Point tile;
    unsigned image;
};

class Session {
public:
    explicit Session(Level level, MatchOptions options = {});
    Session(std::vector<Level> levels, std::size_t startingArena, MatchOptions options);
    void tick(const Controls& input);
    void resetMatch();
    void togglePause();

    const auto& players() const { return players_.slots(); }
    const auto& bumpers() const { return players_.bumpers(); }
    const auto& bombs() const { return bombs_; }
    const auto& map() const { return map_; }
    const auto& score() const { return score_; }
    const auto& winners() const { return winners_; }
    const auto& closingFrames() const { return closingFrames_; }
    RoundPhase phase() const { return phase_; }
    unsigned remaining() const { return remaining_; }
    unsigned elapsed() const { return timing_.autoCounter; }
    unsigned roundNumber() const { return roundNumber_; }
    unsigned podiumTime() const { return podiumTime_; }
    bool paused() const { return paused_; }
    bool alert() const { return alert_; }
    bool isTeamMatch() const { return options_.teams; }
    bool fiveWinMatch() const { return options_.fiveWins; }
    bool survivorMode() const { return options_.survivor; }
    bool retrying() const { return retrying_; }
    const Level& arena() const { return level_; }
    std::size_t arenaIndex() const { return arenaIndex_; }
    bool arenasFinished() const { return arenasFinished_; }
    std::span<const SoundRequest> sounds() const { return sounds_; }

private:
    void startRound(RandomState random, bool newRound = true);
    void tickClock();
    void tickClosing();
    void endRound();
    void advanceArena();
    void closeEntries();
    static std::vector<Point> fillOrder(const Level& level);

    std::vector<Level> arenas_;
    std::size_t firstArena_{}, arenaIndex_{};
    Level level_;
    MatchOptions options_;
    PlayerMap map_;
    BombField bombs_;
    Players players_;
    PlayerTick timing_{};
    std::array<unsigned, PlayerCount> score_{};
    std::array<bool, PlayerCount> winners_{};
    std::vector<Point> closingOrder_;
    std::vector<ClosingFrame> closingFrames_;
    std::vector<SoundRequest> sounds_;
    std::size_t nextClosing_{};
    unsigned closingDelay_{}, warning_{}, remaining_{}, resultDelay_{}, appeared_{}, roundNumber_{};
    unsigned winnerAnimation_{}, drawAnimation_{};
    unsigned podiumTime_{}, cameraTime_{};
    bool awaitingRelease_{};
    bool paused_{}, alert_{}, entriesClosed_{}, retrying_{};
    bool arenasFinished_{};
    RoundPhase phase_{RoundPhase::AwaitingPlayers};
};
}

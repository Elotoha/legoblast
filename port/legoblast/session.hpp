#pragma once

#include "bombs.hpp"
#include "players.hpp"

namespace legoblast {
enum class RoundPhase { AwaitingPlayers, Running, Draining, Result, MatchComplete };
struct MatchOptions {
    bool fiveWins{true};
    bool teams{};
};
struct ClosingFrame {
    Point tile;
    unsigned image;
};

class Session {
public:
    explicit Session(Level level, MatchOptions options = {});
    void tick(const Controls& input);
    void resetMatch();
    void togglePause();

    const auto& players() const { return players_.slots(); }
    const auto& bombs() const { return bombs_; }
    const auto& map() const { return map_; }
    const auto& score() const { return score_; }
    const auto& winners() const { return winners_; }
    const auto& closingFrames() const { return closingFrames_; }
    RoundPhase phase() const { return phase_; }
    unsigned remaining() const { return remaining_; }
    unsigned elapsed() const { return timing_.autoCounter; }
    unsigned roundNumber() const { return roundNumber_; }
    bool paused() const { return paused_; }
    bool alert() const { return alert_; }
    bool isTeamMatch() const { return options_.teams; }

private:
    void startRound();
    void tickClock();
    void tickClosing();
    void endRound();
    void closeEntries();
    static std::vector<Point> fillOrder(const Level& level);

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
    std::size_t nextClosing_{};
    unsigned closingDelay_{}, warning_{}, remaining_{}, resultDelay_{}, appeared_{}, roundNumber_{};
    bool paused_{}, alert_{}, entriesClosed_{};
    RoundPhase phase_{RoundPhase::AwaitingPlayers};
};
}

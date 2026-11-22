#include "session.hpp"

#include <algorithm>
#include <limits>
#include <utility>

namespace legoblast {
namespace {
constexpr unsigned TicksPerSecond = 50;
constexpr unsigned Wins = 5;
constexpr unsigned ResultDelay = 10;
constexpr unsigned FillImages = 5;
constexpr unsigned FillFrameDelay = 3;
constexpr unsigned FillBlockIndex = 19;

bool hasFire(const Controls& input) { return std::ranges::any_of(input, &Buttons::fire); }
bool appeared(const Player& player) { return player.activation != Activation::Hidden; }
bool surviving(const Player& player) { return appeared(player) && !player.dead && !player.deathFrame; }

unsigned clockTime(std::uint32_t value) {
    return value > std::numeric_limits<unsigned>::max() - 49 ? value : value + 49;
}
}

Session::Session(Level level, MatchOptions options)
    : level_(std::move(level)), options_(options), map_(level_), bombs_(level_),
      closingOrder_(fillOrder(level_)) {
    startRound();
}

void Session::startRound() {
    ++roundNumber_;
    map_ = PlayerMap(level_);
    bombs_ = BombField(level_);
    players_.prepare(level_, true, false);
    timing_ = {};
    timing_.teams = options_.teams;
    timing_.fiveWinMatch = options_.fiveWins;
    timing_.levelInfoState = 0;
    remaining_ = clockTime(level_.totalTime);
    warning_ = level_.totalTime > level_.warningTime ? clockTime(level_.warningTime) : 0;
    winners_.fill(false);
    closingFrames_.clear();
    nextClosing_ = closingDelay_ = resultDelay_ = appeared_ = 0;
    paused_ = alert_ = entriesClosed_ = false;
    phase_ = RoundPhase::AwaitingPlayers;
}

void Session::resetMatch() {
    players_ = Players{};
    score_.fill(0);
    roundNumber_ = 0;
    startRound();
}

void Session::togglePause() {
    if (phase_ == RoundPhase::AwaitingPlayers || phase_ == RoundPhase::Running ||
        phase_ == RoundPhase::Draining)
        paused_ = !paused_;
}

void Session::closeEntries() {
    entriesClosed_ = true;
    players_.eliminateAbsent();
}

void Session::tickClock() {
    if (remaining_ && --remaining_ == 0) {
        timing_.gameOver = true;
        closeEntries();
        bombs_.detonateAll();
        phase_ = RoundPhase::Draining;
        return;
    }
    alert_ = warning_ && warning_ <= 10 * TicksPerSecond;
    if (warning_) {
        if (warning_ == 10 * TicksPerSecond)
            closeEntries();
        --warning_;
    }
    if (!warning_ && level_.totalTime > level_.warningTime)
        tickClosing();
}

void Session::tick(const Controls& input) {
    if (paused_)
        return;
    if (phase_ == RoundPhase::Result || phase_ == RoundPhase::MatchComplete) {
        if (resultDelay_)
            --resultDelay_;
        if (!resultDelay_ && hasFire(input)) {
            if (phase_ == RoundPhase::MatchComplete)
                resetMatch();
            else
                startRound();
        }
        return;
    }

    ++timing_.autoCounter;
    // TestLevelEnd displays the start banner before the 5-win join delay elapses.
    if (timing_.autoCounter == 15 && !timing_.levelInfoState)
        timing_.levelInfoState = -1;
    if (timing_.levelTimerRunning && remaining_)
        tickClock();

    players_.tick(input, timing_, map_, &bombs_);
    if (timing_.levelTimerRunning && phase_ == RoundPhase::AwaitingPlayers)
        phase_ = RoundPhase::Running;

    const auto& slots = players_.slots();
    appeared_ = std::max(appeared_, static_cast<unsigned>(std::ranges::count_if(slots, appeared)));
    if (!entriesClosed_ && std::ranges::any_of(slots, [](const auto& p) { return p.deathFrame != 0; }))
        closeEntries();

    std::array<unsigned, 2> survivors{};
    for (std::size_t i = 0; i < slots.size(); ++i)
        if (surviving(slots[i]))
            ++survivors[i % 2];
    if (entriesClosed_ && (survivors[0] + survivors[1] <= 1 ||
                           (options_.teams && (!survivors[0] || !survivors[1])))) {
        timing_.gameOver = true;
        bombs_.thaw();
        phase_ = RoundPhase::Draining;
    }

    bombs_.tick(map_);
    if (phase_ == RoundPhase::Draining && bombs_.settled() &&
        std::ranges::none_of(slots, [](const auto& p) {
            return appeared(p) && !p.dead && (p.deathFrame || p.teleportPhase);
        }))
        endRound();
}

void Session::endRound() {
    const auto& slots = players_.slots();
    const auto total = std::ranges::count_if(slots, surviving);
    std::array<bool, 2> teamSurvives{};
    for (std::size_t i = 0; i < slots.size(); ++i)
        if (surviving(slots[i]))
            teamSurvives[i % 2] = true;
    const bool winner = appeared_ >= 2 &&
        (options_.teams ? teamSurvives[0] != teamSurvives[1] : total == 1);
    if (winner) {
        for (std::size_t i = 0; i < slots.size(); ++i)
            if (surviving(slots[i])) {
                winners_[i] = true;
                if (!options_.teams)
                    ++score_[i];
            }
        if (options_.teams)
            ++score_[teamSurvives[0] ? 0 : 1];
    }
    const bool matchComplete = options_.fiveWins && std::ranges::any_of(score_, [](auto score) { return score >= Wins; });
    phase_ = matchComplete ? RoundPhase::MatchComplete : RoundPhase::Result;
    resultDelay_ = ResultDelay;
}

// Int_VBL.i: start just left of the upper bound, move right, and shrink each
// edge only when the spiral turns. One complete loop is charged on moving up.
std::vector<Point> Session::fillOrder(const Level& level) {
    int left = level.minX, top = level.minY + 1, right = level.maxX, bottom = level.maxY;
    int x = left - 1, y = level.minY, dx = 1, dy = 0, rings = level.fillCount;
    std::vector<Point> path;
    for (int iteration = 0; iteration < Width * Height && rings > 0; ++iteration) {
        if (x == left && dx < 0) { dx = 0; dy = -1; ++left; }
        if (y == top && dy < 0) { dx = 1; dy = 0; ++top; if (--rings == 0) break; }
        if (x == right && dx > 0) { dx = 0; dy = 1; --right; }
        if (y == bottom && dy > 0) { dx = -1; dy = 0; --bottom; }
        if (left - 1 > right || top - 1 > bottom)
            break;
        x += dx;
        y += dy;
        if (x < 0 || x >= Width || y < 0 || y >= Height)
            break;
        path.push_back({short(x), short(y)});
    }
    return path;
}

void Session::tickClosing() {
    if (closingDelay_) {
        --closingDelay_;
        if (closingDelay_ && closingDelay_ % FillFrameDelay == 0)
            ++closingFrames_.back().image;
        return;
    }
    if (nextClosing_ == closingOrder_.size())
        return;
    const auto tile = closingOrder_[nextClosing_++];
    bombs_.placeClosingBlock(tile, map_);
    closingFrames_.push_back({tile, level_.blocks[FillBlockIndex]});
    closingDelay_ = FillImages * FillFrameDelay;
}
}

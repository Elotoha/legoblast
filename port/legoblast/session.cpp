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
constexpr unsigned DontMoveSeconds = 6;
constexpr unsigned PodiumFadeIn = 100;
constexpr unsigned PodiumToGrey = 100;

bool hasFire(const Controls& input) { return std::ranges::any_of(input, &Buttons::fire); }
bool appeared(const Player& player) { return player.activation != Activation::Hidden; }
bool surviving(const Player& player) { return appeared(player) && !player.dead && !player.deathFrame; }

unsigned clockTime(std::uint32_t value) {
    return value > std::numeric_limits<unsigned>::max() - 49 ? value : value + 49;
}
}

Session::Session(Level level, MatchOptions options)
    : Session(std::vector<Level>{std::move(level)}, 0, options) {}

Session::Session(std::vector<Level> levels, std::size_t startingArena, MatchOptions options)
    : arenas_(std::make_shared<const std::vector<Level>>(std::move(levels))), firstArena_(startingArena), arenaIndex_(startingArena),
      level_(arenas_->at(startingArena)), options_(options), map_(level_), bombs_(level_) {
    resetMatch();
}

void Session::startRound(RandomState random, bool newRound) {
    const bool dyna = options_.arena == ArenaMode::Dynablaster;
    if (newRound || dyna)
        level_ = (*arenas_)[arenaIndex_];
    if (dyna)
        dynaInit(level_, random);
    if (newRound)
        ++roundNumber_;
    closingOrder_ = fillOrder(level_);
    map_ = PlayerMap(level_);
    bombs_ = BombField(level_, random);
    players_.prepare(level_, newRound, dyna);
    timing_ = {};
    timing_.teams = options_.teams;
    timing_.survivor = options_.survivor;
    timing_.fiveWinMatch = options_.fiveWins;
    timing_.levelInfoState = 0;
    remaining_ = clockTime(level_.totalTime);
    warning_ = level_.totalTime > level_.warningTime ? clockTime(level_.warningTime) : 0;
    winners_.fill(false);
    closingFrames_.clear();
    nextClosing_ = closingDelay_ = resultDelay_ = appeared_ = 0;
    retrying_ = !newRound;
    arenasFinished_ = false;
    reviewing_ = false;
    paused_ = alert_ = entriesClosed_ = false;
    phase_ = RoundPhase::AwaitingPlayers;
}

void Session::resetMatch(RandomState random) {
    players_ = Players{};
    sounds_.clear();
    score_.fill(0);
    roundNumber_ = 0;
    arenaIndex_ = firstArena_;
    previousArena_ = firstArena_;
    startRound(random);
}

void Session::togglePause() {
    if (phase_ == RoundPhase::AwaitingPlayers || phase_ == RoundPhase::Running ||
        phase_ == RoundPhase::Draining)
        paused_ = !paused_;
}

bool Session::canChangeArena() const {
    return !paused_ && phase_ != RoundPhase::Podium && phase_ != RoundPhase::Statistics;
}

void Session::startPodium() {
    phase_ = RoundPhase::Podium;
    podiumTime_ = cameraTime_ = 0;
    awaitingRelease_ = true;
    sounds_.push_back({SoundCue::MatchVictory, 41, 3});
    sounds_.push_back({SoundCue::Victory, 40});
}

bool Session::reviewPodium() {
    if (paused_ || (phase_ != RoundPhase::Result && phase_ != RoundPhase::AwaitingPlayers) ||
        std::ranges::none_of(players_.slots(), &Player::completedRounds))
        return false;
    reviewing_ = true;
    startPodium();
    return true;
}

void Session::skipPodium() {
    phase_ = RoundPhase::Statistics;
    podiumTime_ = std::max(podiumTime_, 100u);
    awaitingRelease_ = true;
}

void Session::replayArena() {
    if (canChangeArena())
        startRound(bombs_.randomState());
}

void Session::previousArena() {
    if (!canChangeArena() || options_.arena == ArenaMode::Dynablaster)
        return;
    if (options_.arena == ArenaMode::Random) {
        if (previousArena_ == arenaIndex_)
            return;
        arenaIndex_ = previousArena_;
    } else {
        if (!arenaIndex_)
            return;
        --arenaIndex_;
    }
    replayArena();
}

void Session::nextArena() {
    if (!canChangeArena() || options_.arena == ArenaMode::Dynablaster)
        return;
    if (options_.arena == ArenaMode::Random) {
        auto random = bombs_.randomState();
        drawRandomArena(random);
        startRound(random);
    } else if (arenaIndex_ + 1 < arenas_->size()) {
        ++arenaIndex_;
        replayArena();
    }
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
    if (warning_) {
        --warning_;
        if (warning_ == 10 * TicksPerSecond) {
            sounds_.push_back({SoundCue::Alarm, 33, 3});
            closeEntries();
        }
    }
    alert_ = warning_ && warning_ <= 10 * TicksPerSecond;
    if (!warning_ && level_.totalTime > level_.warningTime)
        tickClosing();
}

void Session::tick(const Controls& input, bool automaticMicro) {
    sounds_.clear();
    if (paused_)
        return;
    if (phase_ == RoundPhase::Podium || phase_ == RoundPhase::Statistics) {
        ++podiumTime_;
        if (!hasFire(input))
            awaitingRelease_ = false;
        if (phase_ == RoundPhase::Podium && cameraTime_ && podiumTime_ - cameraTime_ >= PodiumToGrey) {
            phase_ = RoundPhase::Statistics;
            awaitingRelease_ = true;
        } else if (!awaitingRelease_ && hasFire(input)) {
            if (phase_ == RoundPhase::Statistics) {
                if (reviewing_)
                    startRound(bombs_.randomState());
                else
                    resetMatch();
            }
            else if (!cameraTime_ && podiumTime_ >= PodiumFadeIn) {
                cameraTime_ = podiumTime_;
                sounds_.push_back({SoundCue::Camera, 42});
            }
        }
        return;
    }
    if (phase_ == RoundPhase::Result || phase_ == RoundPhase::MatchComplete) {
        players_.tickResult();
        if (resultDelay_)
            --resultDelay_;
        if (!resultDelay_ && hasFire(input)) {
            if (phase_ != RoundPhase::MatchComplete) {
                advanceArena();
            } else if (arenasFinished_) {
                resetMatch();
            } else {
                startPodium();
            }
        }
        return;
    }

    ++timing_.autoCounter;
    // TestLevelEnd displays the start banner before the 5-win join delay elapses.
    if (timing_.autoCounter == 15 && !timing_.levelInfoState)
        timing_.levelInfoState = -1;
    if (timing_.levelTimerRunning && remaining_)
        tickClock();

    if (timing_.autoCounter % 4 == 0)
        players_.tickBumpers(map_, sounds_);
    const auto previousSlots = players_.slots();
    timing_.sounds.clear();
    players_.tick(input, timing_, map_, &bombs_, automaticMicro);
    sounds_.insert(sounds_.end(), timing_.sounds.begin(), timing_.sounds.end());
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
    const auto timeUsed = level_.totalTime > remaining_ ? level_.totalTime - remaining_ : 0;
    const bool beforeClosing = warning_ || level_.totalTime <= level_.warningTime;
    const auto living = survivors[0] + survivors[1];
    for (std::size_t i = 0; i < slots.size(); ++i) {
        if (!previousSlots[i].deathFrame || previousSlots[i].dead || !slots[i].dead)
            continue;
        const bool retry = options_.survivor ? living > 1 :
            living && slots[i].noMoveDeaths <= 1 && beforeClosing && timeUsed / TicksPerSecond <= DontMoveSeconds;
        if (retry) {
            sounds_.push_back({SoundCue::DontMove, 34});
            startRound(bombs_.randomState(), false);
            return;
        }
    }
    std::array<unsigned, 2> alive{};
    for (std::size_t i = 0; i < slots.size(); ++i)
        if (!slots[i].dead)
            ++alive[i % 2];
    if (alive[0] + alive[1] <= 1 || (options_.teams && (!alive[0] || !alive[1]))) {
        timing_.gameOver = true;
        bombs_.thaw();
        phase_ = RoundPhase::Draining;
    }

    bombs_.tick(map_);
    auto& bombSounds = bombs_.sounds();
    sounds_.insert(sounds_.end(), bombSounds.begin(), bombSounds.end());
    bombSounds.clear();
    if (phase_ == RoundPhase::Draining && bombs_.settled() &&
        std::ranges::none_of(slots, [](const auto& p) {
            return appeared(p) && !p.dead && (p.deathFrame || p.teleportPhase);
        }))
        endRound();
}

void Session::advanceArena() {
    auto random = bombs_.randomState();
    if (options_.arena == ArenaMode::Sequential)
        ++arenaIndex_;
    if (options_.arena == ArenaMode::Random)
        drawRandomArena(random);
    startRound(random);
}

void Session::drawRandomArena(RandomState& random) {
    previousArena_ = arenaIndex_;
    arenaIndex_ = (random.next() & 0xfff) % arenas_->size();
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
    players_.startResult(winner, winner ? winnerAnimation_ : drawAnimation_);
    sounds_.push_back({winner ? SoundCue::Victory : SoundCue::Draw, 40});
    const bool matchComplete = (options_.teams || options_.fiveWins) &&
        std::ranges::any_of(score_, [](auto score) { return score >= Wins; });
    arenasFinished_ = !matchComplete && options_.arena == ArenaMode::Sequential && arenaIndex_ + 1 == arenas_->size();
    phase_ = matchComplete || arenasFinished_ ? RoundPhase::MatchComplete : RoundPhase::Result;
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
        if (--closingDelay_ == 0) {
            ++closingFrames_.back().image;
            if (closingFrames_.back().image - level_.blocks[FillBlockIndex] < FillImages - 1)
                closingDelay_ = FillFrameDelay;
        }
        return;
    }
    if (nextClosing_ == closingOrder_.size())
        return;
    const auto tile = closingOrder_[nextClosing_++];
    bombs_.placeClosingBlock(tile, map_);
    sounds_.push_back({SoundCue::ClosingBlock, -16});
    closingFrames_.push_back({tile, level_.blocks[FillBlockIndex]});
    closingDelay_ = 1;
}
}

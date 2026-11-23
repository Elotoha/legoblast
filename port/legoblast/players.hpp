#pragma once

#include "level.hpp"
#include "micro.hpp"
#include "sound_cues.hpp"

#include <array>

namespace legoblast {
class BombField;
inline constexpr std::size_t PlayerCount = 6;
// JoyList order in lego17.asm. Input is sampled before the VBL player update.
enum class Control : std::size_t { Joy0, Joy1, Joy3, Joy4, Keyboard1, Keyboard2, Keyboard3, Micro, Lia, Count };
struct Buttons {
    bool left{}, right{}, up{}, down{}, fire{};
};
using Controls = std::array<Buttons, static_cast<std::size_t>(Control::Count)>;

struct PlayerCell {
    std::uint8_t visible{}, slab{};
    Point teleporter{};
    int bomb{-1};
};

class PlayerMap {
public:
    explicit PlayerMap(const Level& level);
    const PlayerCell& at(int subX, int subY) const;
    PlayerCell& at(int subX, int subY);
    std::vector<Point> bombVelocities;
private:
    std::array<PlayerCell, 64 * 32> cells_{};
};

enum class Activation { Ready = -1, Hidden = 0, AwaitRelease = 1 };
struct Player {
    Point sprite{}, previousStep{}, bumper{}, teleportDestination{};
    int speed{}, frame{168}, frameBase{}, animationTicks{};
    int teleportFrame{168}, teleportPhase{-1}, teleportPermission{};
    int fireRequest{}, slowBumper{}, blockedTicks{}, repeatFire{}, deathFrame{};
    int bombCapacity{}, flameEnergy{}, fuse{}, loops{}, imageOffset{};
    unsigned lastBonus{};
    std::array<int, 9> effects{};
    int storedEnergy{}, storedFuse{}, storedLoops{}, storedSpeed{}, temporaryBombs{}, immunityFlash{};
    bool clock{};
    int recentCell{}, earlierCell{};
    int bumperCell{};
    int roundsPlayed{};
    unsigned completedRounds{}, deaths{}, victories{}, bombsPlanted{}, bonusesTaken{};
    int control{-1};
    Activation activation{Activation::Hidden};
    bool forceCenter{true}, autoFire{}, previousFire{}, fire{}, canPush{}, push{}, canBeBumped{};
    bool dead{};
    int noMoveDeaths{};
    bool visible{};
    Point center() const;
};

struct PlayerTick {
    std::uint32_t autoCounter;
    bool fiveWinMatch{};
    std::int16_t levelInfoState{};
    bool levelTimerRunning{}, gameOver{}, winnersPhase{};
    bool requestClearBar{};
    bool teams{};
    bool survivor{};
    std::vector<SoundRequest> sounds;
};

struct Bumper {
    Point cell, direction;
    std::array<Point, 2> probes;
    unsigned frame{}, imageOffset{};
    int state{-1};
};

class Players {
public:
    void prepare(const Level& level, bool newLevel, bool dynaLevel);
    void tick(const Controls& controls, PlayerTick& timing, PlayerMap& map, BombField* bombs = nullptr, bool automaticMicro = true);
    void eliminateAbsent();
    void tickBumpers(PlayerMap& map, std::vector<SoundRequest>& sounds);
    void startResult(bool victory, unsigned& animationIndex);
    void tickResult();
    const auto& slots() const { return players_; }
    const auto& bumpers() const { return bumpers_; }

private:
    void join(const Controls& controls);
    void show(Player& player, PlayerTick& timing);
    void applyBonus(Player& player, unsigned number, PlayerTick& timing, BombField& bombs, PlayerMap& map);
    std::array<Player, PlayerCount> players_{};
    Micro micro_;
    std::vector<Bumper> bumpers_;
    std::array<bool, static_cast<std::size_t>(Control::Count)> locked_{};
    bool someoneAppeared_{};
};
}

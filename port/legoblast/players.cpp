#include "players.hpp"

#include <algorithm>
#include <bit>
#include <stdexcept>
#include <utility>

namespace legoblast {
namespace {
constexpr int GridStride = 64;
constexpr int GridRows = 32;
constexpr int BaseX = 136 - 16 + 8; // SprBaseX, including XAff in ORCHESTRE.
constexpr int BaseY = 42 - 16;
constexpr int TeleFirst = 140;
constexpr int TeleLast = 168;
constexpr int BombTile = 29;
constexpr int FirstSlabEnd = 7;
constexpr int SecondSlabEnd = 16;

std::int16_t word(int value) {
    return std::bit_cast<std::int16_t>(static_cast<std::uint16_t>(value));
}

int subcell(int pixels) {
    return static_cast<std::uint16_t>(pixels) >> 3;
}

bool validCell(int x, int y) {
    return x >= 0 && x < GridStride && y >= 0 && y < GridRows;
}

Point movement(const Buttons& buttons, int speed) {
    return {word(buttons.left ? -speed : buttons.right ? speed : 0),
            word(buttons.up ? -speed : buttons.down ? speed : 0)};
}

int sign(int value) { return (value > 0) - (value < 0); }

// TestDir resolves a diagonal using the previous tick's horizontal movement.
void selectAxis(Point& step, Point last) {
    if (step.x && (last.x || !step.y))
        step.y = 0;
    if (step.y)
        step.x = 0;
}

void applyBumper(Player& player, Point& step) {
    player.slowBumper = player.slowBumper == 0 ? 3 : player.slowBumper - 1;
    auto brake = [&](std::int16_t& bump, int input) {
        if (input && sign(bump) != sign(input) && player.slowBumper == 0)
            bump = word(bump - sign(bump));
    };
    if (player.bumper.x) {
        brake(player.bumper.x, step.x);
        player.bumper.y = 0;
        step = {player.bumper.x, 0};
    } else if (player.bumper.y) {
        brake(player.bumper.y, step.y);
        step = {0, player.bumper.y};
    }
}

// CentreJ samples the old XScr/YScr. The one-pixel nudges affect the sprite directly.
void center(Player& player, Point screen, Point step, const PlayerMap& map) {
    if (step.x || step.y)
        player.forceCenter = false;
    else if (!player.forceCenter)
        return;
    const auto obstacle = [&](int x, int y) {
        const auto tile = map.at(subcell(x), subcell(y)).visible;
        return tile != 0 && tile != BombTile;
    };
    if (!step.x) {
        player.sprite.x = word(player.sprite.x - obstacle(screen.x + 6, screen.y));
        player.sprite.x = word(player.sprite.x + obstacle(screen.x - 6, screen.y));
    }
    if (!step.y) {
        player.sprite.y = word(player.sprite.y + obstacle(screen.x, screen.y - 4));
        player.sprite.y = word(player.sprite.y - obstacle(screen.x, screen.y + 6));
    }
}

// TestFleche runs after CentreJ and uses the saved screen coordinates.
void conveyor(Point& step, std::uint8_t slab) {
    switch (slab) {
    case 12: --step.y; break;
    case 13: ++step.x; break;
    case 14: ++step.y; break;
    case 15: --step.x; break;
    default: break;
    }
}

Point testWall(Player& player, Point screen, Point step, PlayerMap& map) {
    const Point current{word(subcell(screen.x)), word(subcell(screen.y))};
    const Point target{word(subcell(std::max(0, screen.x + (step.x < 0 ? -8 : step.x > 0 ? 10 : 0)))),
                       word(subcell(std::max(0, screen.y + (step.y < 0 ? -9 : step.y > 0 ? 8 : 0))))};
    const auto& view = std::as_const(map);
    const auto& cell = view.at(target.x, target.y);
    bool allowed = target.x == current.x && target.y == current.y;
    if (!allowed && cell.slab != 5 && cell.slab != 6) {
        allowed = cell.visible == 0 || cell.visible == 28 || cell.visible == 30;
        if (cell.visible == BombTile && cell.bomb >= 0 &&
            static_cast<std::size_t>(cell.bomb) < map.bombVelocities.size()) {
            auto& speed = map.bombVelocities[cell.bomb];
            const auto& before = view.at(current.x, current.y);
            if (before.visible == BombTile && before.bomb == cell.bomb) {
                // The original adds Bomb_VX to both D3 and D4.
                allowed = word(sign(step.x) + speed.x) != 0 ||
                    (!speed.x && (word(sign(step.y) + speed.x) != 0 || !speed.y));
            }
            if (!allowed && player.push && player.canPush) {
                player.canPush = false;
                speed = {word(sign(step.x)), word(sign(step.y))};
            }
        }
    }
    if (allowed) {
        player.canPush = true;
    } else {
        step = {};
        player.bumper = {};
        if (!player.teleportPermission)
            player.teleportPermission = 1;
        if (++player.blockedTicks < 100)
            return step;
    }
    player.blockedTicks = 0;
    player.earlierCell = std::exchange(player.recentCell, (target.y * GridStride + target.x) * 4);
    return step;
}

void animateTeleport(Player& player) {
    player.frame = player.teleportFrame += player.teleportPhase;
    if (player.frame == TeleFirst) {
        player.frame = 33;
        player.previousStep = {};
        player.teleportPhase = 0;
    } else if (player.frame == TeleLast) {
        player.teleportPhase = -1;
        player.sprite = player.teleportDestination;
        player.forceCenter = true;
    }
}

bool tryTeleport(Player& player, const PlayerMap& map, Point current, bool gameOver) {
    const auto destination = map.at(current.x, current.y).teleporter;
    if ((!destination.x && !destination.y) || gameOver) {
        player.teleportPermission = -1;
        return false;
    }
    if (player.teleportPermission < 0 && !player.bumper.x && !player.bumper.y &&
        !map.at(destination.x, destination.y).visible &&
        !map.at(destination.x + 1, destination.y).visible &&
        !map.at(destination.x, destination.y + 1).visible &&
        !map.at(destination.x + 1, destination.y + 1).visible) {
        player.teleportDestination = {word(BaseX + destination.x * 8), word(BaseY + destination.y * 8)};
        player.teleportFrame = TeleFirst;
        player.teleportPhase = 1;
        player.teleportPermission = 0;
        animateTeleport(player);
        return true;
    }
    if (player.teleportPermission > 0)
        player.teleportPermission = -1;
    return false;
}

void animateWalk(Player& player, Point step) {
    int speed = player.speed;
    if (player.bumper.x) speed = std::abs(player.bumper.x);
    if (player.bumper.y) speed = std::abs(player.bumper.y);
    if (!step.x && !step.y) {
        const auto facing = player.previousStep;
        if (facing.x)
            player.frame = facing.x == speed ? 32 : 34;
        else if (facing.y)
            player.frame = facing.y == speed ? 33 : 35;
    } else {
        const int base = step.x ? (step.x > 0 ? 0 : 16) : (step.y == speed ? 8 : 24);
        const bool same = step.x ? sign(step.x) == sign(player.previousStep.x) :
                                      step.y == player.previousStep.y;
        if (!same) {
            player.frame = base;
            player.animationTicks = 2;
        } else if (++player.animationTicks == 3) {
            player.animationTicks = 0;
            if (++player.frame == base + 8)
                player.frame = base;
        }
    }
    player.previousStep = step;
}
}

PlayerMap::PlayerMap(const Level& level) {
    for (int y = 0; y < Height; ++y) {
        for (int x = 0; x < Width; ++x) {
            const auto raw = level.tiles[y * Width + x];
            PlayerCell tile;
            if (raw & 64)
                tile.visible = 28;
            else if ((raw >= 4 && raw <= FirstSlabEnd) || (raw >= 12 && raw <= SecondSlabEnd))
                tile.slab = raw;
            else if (raw >= 8 && raw <= 11)
                tile.visible = 27;
            else
                tile.visible = raw;
            for (int dy = 0; dy < 2; ++dy)
                for (int dx = 0; dx < 2; ++dx)
                    at(x * 2 + dx, y * 2 + dy) = tile;
        }
    }
    for (const auto& teleport : level.teleporters)
        for (int dy = 0; dy < 2; ++dy)
            for (int dx = 0; dx < 2; ++dx)
                if (validCell(teleport.from.x + dx, teleport.from.y + dy))
                    at(teleport.from.x + dx, teleport.from.y + dy).teleporter = teleport.to;
}

const PlayerCell& PlayerMap::at(int subX, int subY) const {
    static const PlayerCell outside{255};
    return validCell(subX, subY) ? cells_[subY * GridStride + subX] : outside;
}

PlayerCell& PlayerMap::at(int subX, int subY) {
    if (!validCell(subX, subY))
        throw std::out_of_range("player map subcell");
    return cells_[subY * GridStride + subX];
}

Point Player::center() const {
    return {word(sprite.x - 128 + 7), word(sprite.y - 46 + 30)};
}

void Players::prepare(const Level& level, bool newLevel, bool dynaLevel) {
    someoneAppeared_ = false;
    for (std::size_t i = 0; i < players_.size(); ++i) {
        auto& player = players_[i];
        const auto old = player;
        player = {};
        player.control = old.control;
        player.roundsPlayed = old.roundsPlayed;
        player.animationTicks = old.animationTicks;
        player.canPush = old.canPush;
        player.noMoveDeaths = old.noMoveDeaths;
        player.dead = old.dead && old.noMoveDeaths > 1;
        player.sprite = {word(BaseX + level.starts[i].x * 16), word(BaseY + level.starts[i].y * 16)};
        player.speed = word(level.speed);
        player.fireRequest = newLevel ? 0 : 100;
        player.autoFire = !dynaLevel && level.autoFire != 0;
        player.push = level.push != 0;
        player.frameBase = static_cast<int>(i) * 225;
    }
}

void Players::join(const Controls& controls) {
    constexpr auto keyboard1 = static_cast<std::size_t>(Control::Keyboard1);
    constexpr auto keyboard2 = static_cast<std::size_t>(Control::Keyboard2);
    constexpr auto keyboard3 = static_cast<std::size_t>(Control::Keyboard3);
    for (std::size_t i = 0; i < controls.size(); ++i) {
        if (locked_[i] || !controls[i].fire)
            continue;
        auto free = std::ranges::find(players_, -1, &Player::control);
        if (free == players_.end())
            return;
        free->control = static_cast<int>(i);
        free->fireRequest = 1;
        locked_[i] = true;
        if (i == keyboard1)
            locked_[keyboard2] = locked_[keyboard3] = true;
        if (i == keyboard2 || i == keyboard3)
            locked_[keyboard1] = true;
    }
}

void Players::show(Player& player, PlayerTick& timing) {
    ++player.roundsPlayed;
    if (!someoneAppeared_ && !timing.levelTimerRunning) {
        timing.levelTimerRunning = true;
        timing.requestClearBar = true;
    }
    someoneAppeared_ = true;
    player.activation = Activation::AwaitRelease;
    player.visible = true;
}

void Players::tick(const Controls& controls, PlayerTick& timing, PlayerMap& map) {
    join(controls);
    for (auto& player : players_) {
        player.visible = false;
        if (player.dead || timing.winnersPhase ||
            (timing.fiveWinMatch && (timing.levelInfoState == 0 || timing.autoCounter < 40)))
            continue;
        if (player.control < 0)
            continue;
        const auto& input = controls[player.control];
        if (player.activation == Activation::Hidden) {
            const bool request = player.fireRequest > 0 && --player.fireRequest == 0;
            if (input.fire || request)
                show(player, timing);
            continue;
        }
        if (timing.levelInfoState == 0) timing.levelInfoState = 1;
        if (timing.levelInfoState < 0) timing.levelInfoState = 3;
        player.visible = true;
        if (player.teleportPhase) {
            animateTeleport(player);
            continue;
        }

        auto step = movement(input, player.speed);
        player.fire = input.fire && (player.autoFire || !player.previousFire);
        player.previousFire = !player.autoFire && input.fire;
        applyBumper(player, step);
        if (player.activation == Activation::AwaitRelease) {
            if (player.fire)
                player.fire = false;
            else
                player.activation = Activation::Ready;
        }
        selectAxis(step, player.previousStep);
        const auto screen = player.center();
        center(player, screen, step, std::as_const(map));
        const auto desired = step;
        const Point current{word(subcell(screen.x)), word(subcell(screen.y))};
        conveyor(step, std::as_const(map).at(current.x, current.y).slab);
        step = testWall(player, screen, step, map);
        if (tryTeleport(player, std::as_const(map), current, timing.gameOver))
            continue;
        player.sprite.x = word(player.sprite.x + step.x);
        player.sprite.y = word(player.sprite.y + step.y);
        animateWalk(player, desired);
    }
}
}

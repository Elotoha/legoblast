#include "players.hpp"
#include "bombs.hpp"

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
constexpr int DiseaseTime = 1500;
constexpr int ExtraBombs = 10;
constexpr unsigned BumperStart = 231, BumperHit = 233, BumperEnd = 238;
constexpr unsigned BumperTile = 27;

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
    player.bumperCell = (current.y & ~1) * GridStride + (current.x & ~1);
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
        player.imageOffset = 0;
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
        player.imageOffset = 0;
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
                tile.visible = BumperTile;
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
    bumpers_.clear();
    constexpr std::array<Point, 4> directions{{{0, -1}, {0, 1}, {-1, 0}, {1, 0}}};
    constexpr std::array<unsigned, 4> offsets{0, 16, 24, 8};
    for (int i = 0; i < Width * Height; ++i) {
        const auto tile = level.tiles[i];
        if (tile < 8 || tile > 11)
            continue;
        const Point cell{word(2 * (i % Width)), word(2 * (i / Width))};
        const auto direction = directions[tile - 8];
        const Point first{word(cell.x + direction.x + (direction.x > 0)),
                          word(cell.y + direction.y + (direction.y > 0))};
        const Point second{word(cell.x + (direction.x == 0)), word(cell.y + (direction.x != 0))};
        bumpers_.push_back({cell, direction, {first, second}, BumperStart, offsets[tile - 8]});
    }
    for (std::size_t i = 0; i < players_.size(); ++i) {
        auto& player = players_[i];
        const auto old = player;
        player = {};
        player.control = old.control;
        player.roundsPlayed = old.roundsPlayed;
        player.animationTicks = old.animationTicks;
        player.repeatFire = old.repeatFire;
        player.canPush = old.canPush;
        player.noMoveDeaths = newLevel ? 0 : old.noMoveDeaths;
        player.dead = !newLevel && old.dead && old.noMoveDeaths > 1;
        player.sprite = {word(BaseX + level.starts[i].x * 16), word(BaseY + level.starts[i].y * 16)};
        player.speed = word(level.speed);
        player.bombCapacity = level.bombs;
        player.flameEnergy = player.storedEnergy = level.reach;
        player.fuse = 5 * level.bombTime + 16;
        player.loops = level.bombTime;
        player.fireRequest = newLevel ? 0 : 100;
        player.autoFire = !dynaLevel && level.autoFire != 0;
        player.push = level.push != 0;
        player.frameBase = static_cast<int>(i) * 225;
    }
}

void Players::tickBumpers(PlayerMap& map) {
    const auto& visible = std::as_const(map);
    for (auto& bumper : bumpers_) {
        if (visible.at(bumper.cell.x, bumper.cell.y).visible != BumperTile)
            continue;
        const auto bombAt = [&](Point probe) { return visible.at(probe.x, probe.y).bomb; };
        const auto playerInFront = [&](const Player& player) {
            return player.canBeBumped && std::ranges::any_of(bumper.probes, [&](Point probe) {
                const int y = probe.y - (bumper.direction.y < 0);
                return player.bumperCell == y * GridStride + (probe.x & ~1);
            });
        };
        const int first = bombAt(bumper.probes[0]);
        const int second = bombAt(bumper.probes[1]);
        if (bumper.state < 0) {
            bumper.state = 0;
        } else if (bumper.state == 0) {
            // TestMov reads Off1 even if Test2 detected the bomb.
            const auto index = static_cast<std::size_t>(std::max(first, 0));
            const bool stoppedBomb = (first >= 0 || second >= 0) && index < map.bombVelocities.size() &&
                !map.bombVelocities[index].x && !map.bombVelocities[index].y;
            if (stoppedBomb || std::ranges::any_of(players_, playerInFront))
                bumper.state = 1;
        } else {
            if (bumper.frame == BumperHit) {
                for (const auto index : {first, second})
                    if (index >= 0)
                        map.bombVelocities.at(index) = bumper.direction;
                for (auto& player : players_)
                    if (playerInFront(player))
                        player.bumper = {word(6 * bumper.direction.x), word(6 * bumper.direction.y)};
            }
            if (bumper.frame == BumperEnd) {
                bumper.frame = BumperStart;
                bumper.state = 0;
            } else {
                ++bumper.frame;
            }
        }
    }
}

void Players::join(const Controls& controls) {
    constexpr auto keyboard1 = static_cast<std::size_t>(Control::Keyboard1);
    constexpr auto keyboard2 = static_cast<std::size_t>(Control::Keyboard2);
    constexpr auto keyboard3 = static_cast<std::size_t>(Control::Keyboard3);
    for (std::size_t i = 0; i < controls.size(); ++i) {
        if (locked_[i] || !controls[i].fire)
            continue;
        auto free = std::ranges::find_if(players_, [](const auto& player) {
            return player.control < 0 && !player.dead;
        });
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

void Players::eliminateAbsent() {
    for (auto& player : players_)
        if (player.activation == Activation::Hidden) {
            player.dead = true;
            player.noMoveDeaths = 20;
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

namespace {
bool canShareDisease(const Player& player) {
    return player.activation == Activation::Ready && !player.dead &&
        !player.deathFrame && !player.teleportPhase;
}

// FileMal copies the remaining time and halves the donor's time. Speed is
// refreshed in full and only replaces another speed disease if faster.
void shareDisease(Player& donor, Player& recipient) {
    for (std::size_t i = 0; i < donor.effects.size(); ++i) {
        auto& time = donor.effects[i];
        if (!time || (recipient.effects[i] && (i != 3 || donor.speed <= recipient.speed)))
            continue;
        recipient.effects[i] = time;
        if (i != 3)
            time /= 2;
        switch (i) {
        case 1:
            recipient.storedEnergy = recipient.flameEnergy;
            recipient.flameEnergy = donor.flameEnergy;
            break;
        case 2:
            recipient.storedFuse = donor.storedFuse;
            recipient.storedLoops = donor.storedLoops;
            recipient.fuse = donor.fuse;
            recipient.loops = donor.loops;
            break;
        case 3:
            recipient.storedSpeed = recipient.speed;
            recipient.speed = donor.speed;
            recipient.effects[i] = DiseaseTime;
            break;
        case 5:
            recipient.bombCapacity += ExtraBombs;
            recipient.temporaryBombs += ExtraBombs;
            break;
        case 6: recipient.immunityFlash = 10; break;
        default: break;
        }
    }
}

void transferOnContact(std::array<Player, PlayerCount>& players) {
    for (auto it = players.begin(); it != players.end(); ++it) {
        if (!canShareDisease(*it))
            continue;
        const auto center = it->center();
        for (auto earlier = players.begin(); earlier != it; ++earlier) {
            if (!canShareDisease(*earlier))
                continue;
            const auto other = earlier->center();
            if (subcell(center.x) / 2 == subcell(other.x) / 2 &&
                subcell(center.y) / 2 == subcell(other.y) / 2) {
                shareDisease(*it, *earlier);
                shareDisease(*earlier, *it);
            }
        }
    }
}

// TestMalad processes M1 through M9 and defers subsequent timers if one expires.
void tickEffects(Player& player) {
    for (std::size_t i = 0; i < player.effects.size(); ++i) {
        auto& time = player.effects[i];
        if (!time || --time > 0)
            continue;
        switch (i) {
        case 1: player.flameEnergy = player.storedEnergy; break;
        case 2: player.fuse = player.storedFuse; player.loops = player.storedLoops; break;
        case 3: player.speed = player.storedSpeed; break;
        case 5:
            player.bombCapacity -= player.temporaryBombs;
            player.temporaryBombs = 0;
            break;
        case 6: player.imageOffset = 0; break;
        default: break;
        }
        break;
    }
}
}

// TestMort's bonus table in Sprites.i, without the Amiga HUD and sound calls.
void Players::applyBonus(Player& player, unsigned number, PlayerTick& timing, BombField& bombs, PlayerMap& map) {
    constexpr int longTime = DiseaseTime, shortTime = 750;
    auto& effects = player.effects;
    switch (number) {
    case 1:
    case 21: player.flameEnergy += number == 1 ? 1 : 10; player.storedEnergy = player.flameEnergy; break;
    case 2:
    case 20: player.bombCapacity += number == 2 ? 1 : 5; break;
    case 3: player.push = !player.push; break;
    case 4: effects[0] = longTime; break;
    case 5:
    case 12: player.storedEnergy = player.flameEnergy; player.flameEnergy = number == 5 ? 3 : 50;
             effects[1] = longTime; break;
    case 6:
    case 9:
        if (!effects[2]) {
            player.storedFuse = player.fuse;
            player.storedLoops = player.loops;
        }
        player.loops = number == 6 ? 8 : 30;
        player.fuse = 5 * player.loops + 16;
        effects[2] = longTime;
        break;
    case 7:
    case 8:
        if (!effects[3])
            player.storedSpeed = player.speed;
        player.speed = number == 7 ? 1 : 4;
        effects[3] = longTime;
        break;
    case 10: bombs.detonateAll(); break;
    case 11: bombs.freeze(); break;
    case 13: effects[4] = shortTime; break;
    case 14:
        if (!effects[5])
            player.temporaryBombs = 0;
        effects[4] = 0;
        effects[5] = longTime;
        player.temporaryBombs += ExtraBombs;
        player.bombCapacity += ExtraBombs;
        break;
    case 15: effects[6] = shortTime; player.immunityFlash = 10; break;
    case 16:
        player.imageOffset = 0;
        for (auto& time : effects)
            if (time)
                time = 1;
        break;
    case 17:
        bombs.releaseClock(static_cast<unsigned>(&player - players_.data()));
        player.clock = !player.clock;
        break;
    case 18: effects[7] = longTime; break;
    case 19: bombs.scatter(map); break;
    case 22:
        for (auto& receiver : players_)
            if (&receiver != &player && (!timing.teams || ((&receiver - &player) % 2 != 0))) {
                receiver.effects[6] = shortTime;
                receiver.immunityFlash = 10;
            }
        break;
    case 23: effects[8] = longTime; effects[4] = 0; break;
    default: break;
    }
}

void Players::tick(const Controls& controls, PlayerTick& timing, PlayerMap& map, BombField* bombs) {
    if (!timing.winnersPhase)
        transferOnContact(players_);
    join(controls);
    for (auto& player : players_) {
        player.visible = false;
        player.canBeBumped = false;
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
        if (player.deathFrame) {
            player.frame = ++player.deathFrame;
            if (player.deathFrame == 139)
                player.dead = true;
            continue;
        }
        if (player.teleportPhase) {
            animateTeleport(player);
            continue;
        }

        player.canBeBumped = true;
        auto step = movement(input, player.speed);
        const unsigned owner = static_cast<unsigned>(&player - players_.data());
        const bool heldFire = player.autoFire || player.effects[0] || player.clock;
        player.fire = input.fire && (heldFire || !player.previousFire);
        player.previousFire = !heldFire && input.fire;
        applyBumper(player, step);
        const bool awaitingFire = player.activation == Activation::AwaitRelease && player.fire;
        if (awaitingFire) {
            player.fire = false;
        } else {
            player.activation = Activation::Ready;
            if (player.effects[4])
                player.fire = false;
            if (player.effects[8])
                player.fire = true;
            if (player.effects[0]) {
                player.fire = !player.fire;
                if (!player.bumper.x && !player.bumper.y)
                    step = {word(-step.x), word(-step.y)};
            }
        }
        selectAxis(step, player.previousStep);
        const auto screen = player.center();
        if (!player.fire) {
            player.repeatFire = -1;
            if (bombs && player.clock)
                bombs->releaseClock(owner);
        } else {
            player.repeatFire = (player.repeatFire + 1) & 3;
            if (!player.repeatFire && !timing.gameOver && bombs)
                bombs->plant(owner, screen, map, {player.bombCapacity, player.clock ? 26 : player.fuse,
                    player.clock ? 2 : player.loops, player.flameEnergy, player.effects[7] != 0, player.clock});
        }
        center(player, screen, step, std::as_const(map));
        const auto desired = step;
        const Point current{word(subcell(screen.x)), word(subcell(screen.y))};
        conveyor(step, std::as_const(map).at(current.x, current.y).slab);
        step = testWall(player, screen, step, map);
        tickEffects(player);
        const auto visible = std::as_const(map).at(current.x, current.y).visible;
        const bool crushed = visible == 1 || visible == 2 || visible == 3 || visible == 30 || visible == 31;
        if (bombs && ((bombs->flameMask(current.x, current.y) && !player.effects[6]) || crushed)) {
            bombs->releaseClock(owner);
            player.noMoveDeaths = timing.survivor ? 20 : player.noMoveDeaths + 1;
            player.deathFrame = 72 + 1; // TestMort enters AnimMort in the same VBL.
            player.frame = player.deathFrame;
            continue;
        }
        if (bombs && visible == 28)
            applyBonus(player, bombs->collectBonus(current, map), timing, *bombs, map);
        if (tryTeleport(player, std::as_const(map), current, timing.gameOver))
            continue;
        player.sprite.x = word(player.sprite.x + step.x);
        player.sprite.y = word(player.sprite.y + step.y);
        animateWalk(player, desired);
        if (player.effects[6]) {
            player.imageOffset = 0;
            if (--player.immunityFlash < 0) {
                player.imageOffset = 36;
                player.immunityFlash = 10;
            }
        }
    }
}
}

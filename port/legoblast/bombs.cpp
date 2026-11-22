#include "bombs.hpp"
#include "players.hpp"

#include <algorithm>
#include <bit>
#include <utility>

namespace legoblast {
namespace {
constexpr unsigned MaxBombs = 300;
constexpr unsigned MaxFlames = MaxBombs * 4;
constexpr int BombTile = 29;
constexpr int Stride = Width * 2;

bool inside(Point p) {
    return p.x >= 0 && p.x < 2 * Width && p.y >= 0 && p.y < 2 * Height;
}
Point add(Point a, Point b) { return {short(a.x + b.x), short(a.y + b.y)}; }
Point wholeTile(Point p) { return {short(p.x & ~1), short(p.y & ~1)}; }
int tileIndex(Point p) { return p.y / 2 * Width + p.x / 2; }

std::array<Point, 4> footprint(Point p) {
    return {p, add(p, {1, 0}), add(p, {0, 1}), add(p, {1, 1})};
}

void markBomb(PlayerMap& map, Point p, int id) {
    for (auto sub : footprint(p)) {
        auto& cell = map.at(sub.x, sub.y);
        cell.visible = BombTile;
        cell.bomb = id;
    }
}

void clearBomb(PlayerMap& map, Point p, int id) {
    for (auto sub : footprint(p)) {
        auto& cell = map.at(sub.x, sub.y);
        if (cell.bomb == id && cell.visible == BombTile) {
            cell.visible = 0;
            cell.bomb = -1;
        }
    }
}
}

BombField::BombField(const Level& level, RandomState random) : level_(level), random_(random) {
    // The isolated test window does not have the Amiga's video-position seed.
    hiddenBonuses_ = initialLevelRandoms(level, random_).hiddenBonuses;
}

bool BombField::plant(unsigned owner, Point center, PlayerMap& map, bool rebounds) {
    return plant(owner, center, map,
                 {level_.bombs, 5 * level_.bombTime + 16, level_.bombTime, level_.reach, rebounds});
}

bool BombField::plant(unsigned owner, Point center, PlayerMap& map, const BombSettings& settings) {
    if (settings.held && std::ranges::any_of(bombs_, [owner](const Bomb& bomb) {
            return bomb.active && bomb.owner == owner && bomb.held;
        }))
        return false;
    const auto p = Point{short((std::uint16_t(center.x) >> 4) * 2),
                         short((std::uint16_t(center.y) >> 4) * 2)};
    for (auto sub : footprint(p))
        if (!inside(sub) || std::as_const(map).at(sub.x, sub.y).visible || flameMask(sub.x, sub.y))
            return false;
    if (std::ranges::count_if(bombs_, [owner](const auto& b) { return b.active && b.owner == owner; }) >= settings.capacity)
        return false;

    auto slot = std::ranges::find(bombs_, false, &Bomb::active);
    const auto id = static_cast<int>(slot - bombs_.begin());
    // PoseBombe receives Leg_BTime = (BombImT-BombImL+1)*Level_TimeB + BombImFin-BombImT.
    Bomb bomb{p, owner, settings.time, settings.loops, settings.energy};
    bomb.rebounds = settings.rebounds;
    bomb.held = settings.held;
    if (slot == bombs_.end()) {
        if (bombs_.size() == MaxBombs)
            return false;
        bombs_.push_back(bomb);
        map.bombVelocities.emplace_back();
    } else {
        *slot = bomb;
        map.bombVelocities[id] = {};
    }
    markBomb(map, p, id);
    sounds_.push_back({SoundCue::Plant, -15});
    return true;
}

void BombField::tick(PlayerMap& map) {
    if (frozenTicks_ && --frozenTicks_ == 0)
        for (auto& bomb : bombs_)
            bomb.frozen = false;
    if (bombPass_)
        tickBombs(map);
    else
        tickBlocks(map);
    bombPass_ = !bombPass_;
    tickFlames(map);
}

void BombField::tickBombs(PlayerMap& map) {
    for (std::size_t id = 0; id < bombs_.size(); ++id) {
        auto& bomb = bombs_[id];
        if (!bomb.active)
            continue;
        auto& movement = map.bombVelocities[id];
        if (!bomb.frozen && !bomb.held)
            --bomb.time;
        if (bomb.time <= 0 || ((bomb.frozen || bomb.held) && bomb.time == 1)) {
            bomb.active = false;
            movement = {};
            clearBomb(map, bomb.cell, static_cast<int>(id));
            if (flameSlots_ + 4 > MaxFlames)
                continue;
            Blast blast{std::vector<Arm>(4)};
            // NewFlam order: left, top, bottom (Y+1), right (X+1).
            blast.arms[0].front = blast.arms[1].front = bomb.cell;
            blast.arms[2].front = add(bomb.cell, {0, 1});
            blast.arms[3].front = add(bomb.cell, {1, 0});
            constexpr std::array<Point, 4> steps{{{-1, 0}, {0, -1}, {0, 1}, {1, 0}}};
            for (unsigned arm = 0; arm < steps.size(); ++arm) {
                blast.arms[arm].step = steps[arm];
                blast.arms[arm].remaining = bomb.energy;
            }
            blasts_.push_back(std::move(blast));
            flameSlots_ += 4;
            sounds_.push_back({SoundCue::Explosion, 0});
            continue;
        }

        if (bomb.frozen && !bomb.held)
            continue;
        if (!bomb.held && ++bomb.frame > 4 && --bomb.loops > 0)
            bomb.frame = 0;
        moveBomb(id, map);
    }
}

// Bombes.i: BombMouvX/Y and Test2CasesY/X look at the two leading subcells.
void BombField::moveBomb(std::size_t id, PlayerMap& map) {
    auto& bomb = bombs_[id];
    auto& velocity = map.bombVelocities[id];
    if (!velocity.x && !velocity.y) {
        bomb.moved = false;
        return;
    }
    const bool horizontal = velocity.x != 0;
    const Point step = horizontal ? Point{velocity.x, 0} : Point{0, velocity.y};
    const auto next = add(bomb.cell, step);
    const auto leading = add(next, {short(step.x > 0), short(step.y > 0)});
    const auto other = add(leading, horizontal ? Point{0, 1} : Point{1, 0});
    int firstHit = -1;
    bool blocked = false;
    bool bounce = false;
    for (auto point : {leading, other}) {
        if (!inside(point)) {
            blocked = true;
            continue;
        }
        const auto& cell = std::as_const(map).at(point.x, point.y);
        if (cell.slab == 7) {
            bomb.time = 0;
            continue; // Type_Explo bypasses the visible-tile test.
        }
        if (!cell.visible) {
            if (flameMask(point.x, point.y))
                bomb.time = 0;
            continue;
        }
        blocked = true;
        bounce |= bomb.moved && bomb.rebounds;
        if (cell.visible == BombTile && cell.bomb != firstHit && cell.bomb >= 0 &&
            static_cast<std::size_t>(cell.bomb) < bombs_.size()) {
            firstHit = cell.bomb;
            auto& received = map.bombVelocities[cell.bomb];
            auto& axis = horizontal ? received.x : received.y;
            auto& perpendicular = horizontal ? received.y : received.x;
            const auto incoming = horizontal ? step.x : step.y;
            if (perpendicular || !axis) {
                perpendicular = 0;
                axis = incoming;
            } else if (axis + incoming == 0) {
                axis = 0;
            }
        }
    }
    if (bounce) {
        velocity = {short(-velocity.x), short(-velocity.y)};
        sounds_.push_back({SoundCue::Rebound, -11});
        return;
    }
    if (blocked) {
        sounds_.push_back({SoundCue::BombImpact, -13});
        if (horizontal)
            velocity.x = 0;
        else
            velocity.y = 0;
        return;
    }

    bomb.moved = true;
    clearBomb(map, bomb.cell, static_cast<int>(id));
    bomb.cell = next;
    if (!(next.x & 1) && !(next.y & 1)) {
        const auto destination = map.at(next.x, next.y).teleporter;
        if ((destination.x || destination.y) &&
            std::ranges::all_of(footprint(destination), [&](Point point) {
                return inside(point) && !std::as_const(map).at(point.x, point.y).visible;
            }))
            bomb.cell = destination;
    }
    markBomb(map, bomb.cell, static_cast<int>(id));
}

unsigned BombField::collectBonus(Point cell, PlayerMap& map) {
    if (!inside(cell) || map.at(cell.x, cell.y).visible != 28)
        return 0;
    const auto index = tileIndex(cell);
    const auto raw = level_.tiles[index];
    if (raw <= 64 || raw > 87)
        return 0;
    level_.tiles[index] = 0;
    for (const auto point : footprint(wholeTile(cell)))
        map.at(point.x, point.y).visible = 0;
    return raw - 64;
}

bool BombField::settled() const {
    return std::ranges::none_of(bombs_, &Bomb::active) && blasts_.empty();
}

void BombField::thaw() {
    if (frozenTicks_)
        frozenTicks_ = 1;
}

void BombField::placeClosingBlock(Point tile, PlayerMap& map) {
    if (tile.x < 0 || tile.x >= Width || tile.y < 0 || tile.y >= Height)
        return;
    const Point sub{short(tile.x * 2), short(tile.y * 2)};
    std::erase_if(broken_, [sub](const BrokenBlock& block) {
        return block.cell.x == sub.x && block.cell.y == sub.y;
    });
    for (const auto point : footprint(sub)) {
        auto& cell = map.at(point.x, point.y);
        if (cell.visible == BombTile && cell.bomb >= 0 &&
            static_cast<std::size_t>(cell.bomb) < bombs_.size())
            bombs_[cell.bomb].time = 0;
        cell.visible = 1;
        cell.bomb = -1;
    }
    level_.tiles[tile.y * Width + tile.x] = 1;
}

void BombField::detonateAll() {
    for (auto& bomb : bombs_)
        if (bomb.active)
            bomb.time = 0;
}

void BombField::freeze() {
    frozenTicks_ = 500;
    for (auto& bomb : bombs_)
        if (bomb.active)
            bomb.frozen = true;
}

void BombField::releaseClock(unsigned owner) {
    for (auto& bomb : bombs_)
        if (bomb.active && bomb.held && bomb.owner == owner) {
            bomb.held = false;
            bomb.frame = 0;
        }
}

void BombField::scatter(PlayerMap& map) {
    if (bombs_.empty())
        return;
    // FolleList is seeded by MOVEM.W over the two halves of MemRnd1.
    const auto signExtend = [](std::uint32_t word) {
        return static_cast<std::uint32_t>(std::bit_cast<std::int16_t>(static_cast<std::uint16_t>(word)));
    };
    RandomState draw{signExtend(random_.d0 >> 16), signExtend(random_.d0)};
    int direction = static_cast<int>(draw.next() & 3);
    random_.d0 = draw.d0 << 16 | (draw.d1 & 0xffff);
    constexpr std::array<Point, 4> directions{{{-1, 0}, {0, 1}, {0, -1}, {1, 0}}};
    for (auto& velocity : map.bombVelocities) {
        direction = direction ? direction - 1 : 3;
        velocity = directions[direction];
    }
}

void BombField::breakBlock(Point cell, PlayerMap& map) {
    const auto type = map.at(cell.x, cell.y).visible;
    if (type != 2 && type != 28)
        return;
    cell = wholeTile(cell);
    const auto index = tileIndex(cell);
    const auto raw = level_.tiles[index];
    // InitLevel flags type -1 as bit 6; its image is blank, not a visible bonus.
    if (type == 28 && (raw < 64 || raw > 87))
        return;
    const unsigned image = type == 2 ? level_.blocks[2] : bonusImage(raw - 64);
    const auto replacement = type == 2 && hiddenBonuses_[index] ?
        static_cast<std::uint8_t>(64 + hiddenBonuses_[index]) : std::uint8_t{0};
    broken_.push_back({cell, image, image + 4, replacement});
    for (const auto point : footprint(cell))
        map.at(point.x, point.y).visible = type == 2 ? 31 : 30;
    level_.tiles[index] = 0;
}

void BombField::tickBlocks(PlayerMap& map) {
    std::erase_if(broken_, [&](auto& block) {
        if (++block.frame <= block.last)
            return false;
        level_.tiles[tileIndex(block.cell)] = block.replacement;
        for (const auto point : footprint(block.cell))
            map.at(point.x, point.y).visible = block.replacement ? 28 : 0;
        return true;
    });
}

// Flammes.i:TestToyoX and TestToyoY. An unaligned leading edge is already
// inside the pipe. At the outer edge, the entry and exit bits are independent.
bool BombField::passFlame(Arm& arm, Point point, PlayerMap& map) {
    if (!inside(point))
        return false;
    const auto& cell = std::as_const(map).at(point.x, point.y);
    const auto type = cell.visible;
    const bool fireproof = cell.slab == 4 || cell.slab == 6;
    if (!fireproof && !type)
        return true;
    if (!fireproof && type >= 32 && type <= 47) {
        constexpr unsigned left = 8, right = 4, up = 2, down = 1;
        const bool horizontal = arm.step.x != 0;
        const bool positive = arm.step.x > 0 || arm.step.y > 0;
        const int axis = horizontal ? point.x : point.y;
        if ((axis & 1) == static_cast<int>(positive))
            return true;
        const unsigned forward = horizontal ? (positive ? right : left) : (positive ? down : up);
        const unsigned entry = horizontal ? (positive ? left : right) : (positive ? up : down);
        if (!(type & entry))
            return false;
        if (type & forward)
            return true;
        const Point origin = positive ? point : add(point, arm.step);
        const auto turn = [&](unsigned port, Point step, Point offset) {
            if (!(type & port) || flameSlots_ == MaxFlames)
                return;
            Arm branch{};
            branch.front = add(origin, offset);
            branch.step = step;
            branch.remaining = arm.remaining - 1;
            // NewFlam marks each turn as a separate master, with no siblings.
            blasts_.push_back(Blast{{std::move(branch)}});
            ++flameSlots_;
        };
        if (horizontal) {
            turn(up, {0, -1}, {0, 1});
            turn(down, {0, 1}, {});
        } else {
            turn(left, {-1, 0}, {1, 0});
            turn(right, {1, 0}, {});
        }
        return false;
    }
    if (type == BombTile && cell.bomb >= 0 && static_cast<std::size_t>(cell.bomb) < bombs_.size()) {
        bombs_[cell.bomb].time = 0;
        map.bombVelocities[cell.bomb] = {};
    } else {
        breakBlock(point, map);
    }
    return false;
}

void BombField::tickFlames(PlayerMap& map) {
    // An appended branch can be visited later in this VBL. Indexing keeps
    // iteration valid when NewFlam adds a branch to the deque.
    for (std::size_t i = 0; i < blasts_.size(); ++i) {
        auto& blast = blasts_[i];
        if (blast.erasing) {
            for (auto& arm : blast.arms) {
                arm.tail = !arm.path.empty();
                if (arm.tail)
                    arm.path.erase(arm.path.begin());
                else
                    arm.tip = false;
            }
            continue;
        }
        // Master checks its siblings before they expand in this VBL.
        for (std::size_t a = 0; a < blast.arms.size(); ++a) {
            auto& arm = blast.arms[a];
            if (arm.expanding && --arm.remaining > 0) {
                arm.path.push_back(arm.front);
                const auto next = add(arm.front, arm.step);
                const bool horizontal = arm.step.x != 0;
                bool blocked = !passFlame(arm, next, map);
                if ((horizontal ? next.y : next.x) & 1) {
                    const auto other = add(next, horizontal ? Point{0, 1} : Point{1, 0});
                    blocked = !passFlame(arm, other, map) || blocked;
                }
                arm.tip = !blocked;
                if (blocked)
                    arm.expanding = false;
                else
                    arm.front = next;
            } else {
                arm.expanding = false;
            }
            if (a == 0 && std::ranges::none_of(blast.arms, &Arm::expanding)) {
                blast.erasing = true;
                arm.tail = !arm.path.empty();
                if (arm.tail)
                    arm.path.erase(arm.path.begin());
                else
                    arm.tip = false;
                for (std::size_t i = 1; i < blast.arms.size(); ++i) {
                    auto& sibling = blast.arms[i];
                    sibling.tail = !sibling.path.empty();
                    if (sibling.tail)
                        sibling.path.erase(sibling.path.begin());
                    else
                        sibling.tip = false;
                }
                break;
            }
        }
    }
    rebuildFlameMasks();
    std::erase_if(blasts_, [&](const auto& blast) {
        const bool finished = blast.erasing && std::ranges::all_of(blast.arms, [](const auto& arm) {
            return arm.path.empty() && !arm.tip && !arm.tail;
        });
        if (finished)
            flameSlots_ -= blast.arms.size();
        return finished;
    });
}

void BombField::rebuildFlameMasks() {
    masks_.fill(0);
    const auto set = [&](Point cell, unsigned bit) {
        if (inside(cell))
            masks_[cell.y * Stride + cell.x] |= static_cast<std::uint8_t>(1u << bit);
    };
    const auto drawTip = [&](Point p, Point step) {
        if (step.x) {
            set(p, step.x < 0 ? 7 : 6);
            set(add(p, {0, 1}), step.x < 0 ? 5 : 4);
        } else {
            set(p, step.y < 0 ? 7 : 5);
            set(add(p, {1, 0}), step.y < 0 ? 6 : 4);
        }
    };
    for (const auto& blast : blasts_) {
        for (const auto& arm : blast.arms) {
            for (const auto p : arm.path) {
                set(p, arm.step.x ? 3 : 1);
                set(add(p, arm.step.x ? Point{0, 1} : Point{1, 0}), arm.step.x ? 2 : 0);
            }
            if (arm.tip)
                drawTip(arm.front, arm.step);
            if (arm.tail) {
                const Point reverse{short(-arm.step.x), short(-arm.step.y)};
                const auto back = arm.path.empty() ? arm.front : arm.path.front();
                drawTip(add(back, reverse), reverse);
            }
        }
    }
}

std::uint8_t BombField::flameMask(int x, int y) const {
    return inside({short(x), short(y)}) ? masks_[y * Stride + x] : 0;
}
}

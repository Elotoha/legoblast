#include "bombs.hpp"
#include "players.hpp"

#include <iostream>
#include <stdexcept>

using namespace legoblast;

namespace {
void expect(bool ok, const char* message) {
    if (!ok)
        throw std::runtime_error(message);
}
Level fixture() {
    Level level{};
    level.bombs = 2;
    level.bombTime = 1;
    level.reach = 5;
    return level;
}

void fuseAndChain() {
    auto level = fixture();
    PlayerMap map(level);
    BombField bombs(level);
    expect(bombs.plant(0, {39, 42}, map), "first bomb");
    expect(!bombs.plant(0, {43, 42}, map), "same tile must reject a second bomb");
    expect(map.at(4, 4).visible == 29 && map.at(5, 5).bomb == 0, "the initial four subcells");
    for (int i = 0; i < 10; ++i)
        bombs.tick(map);
    expect(bombs.plant(0, {55, 42}, map), "second bomb");
    expect(!bombs.plant(0, {71, 42}, map), "player bomb capacity");
    for (int i = 10; i < 40; ++i)
        bombs.tick(map);
    expect(bombs.bombs()[0].active && bombs.bombs()[0].time == 1 &&
           bombs.bombs()[1].time > 1, "fuse follows alternating passes");
    bombs.tick(map);
    expect(!bombs.bombs()[0].active && bombs.bombs()[1].active && bombs.bombs()[1].time == 0,
           "flame queues the second bomb instead of exploding it in the current pass");
    expect(bombs.flameMask(4, 4) && !bombs.plant(1, {39, 42}, map), "flame prevents placement");
    bombs.tick(map);
    expect(bombs.bombs()[1].active, "wall pass cannot detonate a bomb");
    bombs.tick(map);
    expect(!bombs.bombs()[1].active, "second explosion at next bomb pass");
    for (int i = 0; i < 24; ++i)
        bombs.tick(map);
    expect(!bombs.flameMask(4, 4) && bombs.plant(0, {39, 42}, map),
           "flame cleared and bomb slot recovered");
}

void pushAndWall() {
    auto level = fixture();
    level.tiles[2 * Width + 4] = 2;
    level.blocks[2] = 90;
    PlayerMap map(level);
    BombField bombs(level);
    expect(bombs.plant(0, {39, 42}, map), "bomb placement");
    map.bombVelocities[0] = {1, 0};
    bombs.tick(map);
    expect(bombs.bombs()[0].cell.x == 5 && map.at(4, 4).visible == 0 &&
           map.at(6, 5).visible == 29, "pushed bomb moves one subcell and updates Dim2");
    for (int i = 0; i < 44; ++i)
        bombs.tick(map);
    expect(!bombs.brokenBlocks().empty() && map.at(8, 4).visible == 31 &&
           !bombs.flameMask(8, 4), "wall absorbs flame and enters destruction animation");
    for (int i = 0; i < 12; ++i)
        bombs.tick(map);
    expect(bombs.brokenBlocks().empty() && map.at(8, 4).visible == 0, "wall animation finishes");
}
void pipes() {
    // All these pipes stand at tile (3,2), immediately right of the bomb.
    const auto horizontal = [](std::uint8_t pipe, bool straight, bool up, bool down) {
        auto level = fixture();
        level.reach = 12;
        level.tiles[2 * Width + 3] = pipe;
        PlayerMap map(level);
        BombField bombs(level);
        expect(bombs.plant(0, {39, 42}, map), "pipe scenario bomb");
        bool beyond = false, above = false, below = false;
        for (int frame = 0; frame < 80; ++frame) {
            bombs.tick(map);
            beyond |= bombs.flameMask(8, 4) != 0;
            above |= bombs.flameMask(6, 3) != 0;
            below |= bombs.flameMask(6, 6) != 0;
        }
        expect(beyond == straight && above == up && below == down,
               "horizontal pipe ports, bends and straight-through priority");
        expect(!bombs.flameMask(6, 3) && !bombs.flameMask(6, 6), "turned arms erased");
    };
    horizontal(35, false, false, false); // No left opening.
    horizontal(44, true, false, false);
    horizontal(42, false, true, false);
    horizontal(43, false, true, true);
    horizontal(47, true, false, false); // A straight path suppresses both turns.

    {
        auto reverse = fixture();
        reverse.reach = 12;
        reverse.tiles[2 * Width + 3] = 38; // From the right, turns upward.
        PlayerMap map(reverse);
        BombField bombs(reverse);
        expect(bombs.plant(0, {71, 42}, map), "reverse entry bomb");
        bool above = false, beyond = false;
        for (int frame = 0; frame < 80; ++frame) {
            bombs.tick(map);
            above |= bombs.flameMask(6, 3) != 0;
            beyond |= bombs.flameMask(5, 4) != 0;
        }
        expect(above && !beyond, "reverse entry turns from the even subcell");
    }

    auto level = fixture();
    level.reach = 12;
    level.tiles[3 * Width + 2] = 46; // Entry from above, turns left and right.
    PlayerMap map(level);
    BombField bombs(level);
    expect(bombs.plant(0, {39, 42}, map), "vertical pipe scenario bomb");
    // Pick a delayed second bomb directly after the left turn.
    for (int frame = 0; frame < 20; ++frame)
        bombs.tick(map);
    expect(bombs.plant(1, {23, 58}, map), "bend exit bomb");
    for (int frame = 20; frame < 41; ++frame)
        bombs.tick(map);
    expect(bombs.bombs()[1].active && bombs.bombs()[1].time > 0,
           "left turn must traverse the second subcell of the pipe first");
    bombs.tick(map);
    expect(bombs.bombs()[1].active && bombs.bombs()[1].time == 0,
           "turned branch reaches a bomb during the flame pass");
    bombs.tick(map);
    expect(!bombs.bombs()[1].active, "chain exits the pipe");
}

void specialMovement() {
    auto level = fixture();
    level.tiles[2 * Width + 3] = 1;
    PlayerMap map(level);
    BombField bombs(level);
    expect(bombs.plant(0, {39, 42}, map, true), "rebound bomb");
    map.bombVelocities[0] = {1, 0};
    bombs.tick(map);
    expect(!map.bombVelocities[0].x && bombs.bombs()[0].cell.x == 4,
           "a bomb blocked on its first step must not bounce");
    map.bombVelocities[0] = {-1, 0};
    map.at(2, 4).visible = map.at(2, 5).visible = 1;
    bombs.tick(map);
    bombs.tick(map);
    expect(bombs.bombs()[0].cell.x == 3 && bombs.bombs()[0].moved, "previous successful step");
    bombs.tick(map);
    bombs.tick(map);
    expect(bombs.bombs()[0].cell.x == 3 && map.bombVelocities[0].x == 1,
           "bounce reverses velocity without moving that tick");

    for (bool blocked : {false, true}) {
        auto test = fixture();
        test.teleporters.push_back({{6, 4}, {18, 10}});
        PlayerMap teleportMap(test);
        BombField teleport(test);
        expect(teleport.plant(0, {39, 42}, teleportMap), "teleporter bomb");
        teleportMap.bombVelocities[0] = {1, 0};
        if (blocked)
            teleportMap.at(19, 11).visible = 2;
        teleport.tick(teleportMap);
        expect(teleport.bombs()[0].cell.x == 5, "unaligned bomb cannot teleport");
        teleport.tick(teleportMap);
        teleport.tick(teleportMap);
        expect(teleport.bombs()[0].cell.x == (blocked ? 6 : 18) &&
               teleport.bombs()[0].cell.y == (blocked ? 4 : 10) &&
               teleportMap.bombVelocities[0].x == 1, "teleport with four free cells and preserved velocity");
        const auto p = teleport.bombs()[0].cell;
        expect(teleportMap.at(5, 4).visible == 0 && teleportMap.at(p.x + 1, p.y + 1).bomb == 0,
               "teleport moves all four occupancy records");
    }
}

void bonusDestruction() {
    auto level = fixture();
    level.tiles[2 * Width + 3] = 2;
    level.bonusWeights[18] = 1;
    level.blocks[2] = 90;
    PlayerMap map(level);
    BombField bombs(level);
    expect(bombs.plant(0, {39, 42}, map), "hidden bonus bomb");
    for (int frame = 0; frame < 41; ++frame)
        bombs.tick(map);
    expect(map.at(6, 4).visible == 31 && bombs.collectBonus({6, 4}, map) == 0,
           "destruction animation blocks pickup");
    for (int frame = 0; frame < 20; ++frame)
        bombs.tick(map);
    expect(map.at(6, 5).visible == 28 && bombs.level().tiles[2 * Width + 3] == 82,
           "destructible shows its hidden bonus");
    expect(bombs.plant(0, {39, 42}, map), "visible bonus bomb");
    for (int frame = 0; frame < 42; ++frame)
        bombs.tick(map);
    expect(map.at(6, 5).visible == 30 && bombs.brokenBlocks()[0].frame >= 40 &&
           bombs.collectBonus({6, 4}, map) == 0, "visible bonus uses its destruction frames");
    for (int frame = 0; frame < 20; ++frame)
        bombs.tick(map);
    expect(map.at(6, 5).visible == 0 && bombs.level().tiles[2 * Width + 3] == 0,
           "a destroyed bonus does not reappear");
}

void clocksAndFreezing() {
    auto level = fixture();
    PlayerMap map(level);
    BombField bombs(level);
    expect(bombs.plant(0, {39, 42}, map, {2, 26, 2, 5, false, true}), "clock bomb");
    expect(!bombs.plant(0, {55, 42}, map, {2, 26, 2, 5, false, true}), "one held bomb per player");
    bombs.tick(map);
    expect(bombs.bombs()[0].time == 26, "clock pauses timer");
    bombs.releaseClock(0);
    bombs.freeze();
    for (int i = 0; i < 498; ++i)
        bombs.tick(map);
    expect(bombs.bombs()[0].time == 26 && bombs.bombs()[0].image() >= 210, "freeze persists");
    bombs.tick(map);
    bombs.tick(map);
    expect(bombs.bombs()[0].time == 25 && bombs.bombs()[0].image() < 210, "freeze expires");
    bombs.freeze();
    bombs.detonateAll();
    bombs.tick(map);
    bombs.tick(map);
    expect(!bombs.bombs()[0].active, "detonation overrides freeze");
}

}

int main() {
    try {
        fuseAndChain();
        pushAndWall();
        pipes();
        specialMovement();
        bonusDestruction();
        clocksAndFreezing();
        return 0;
    } catch (const std::exception& error) {
        std::cerr << error.what() << '\n';
        return 1;
    }
}

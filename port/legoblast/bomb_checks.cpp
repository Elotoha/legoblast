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

}

int main() {
    try {
        fuseAndChain();
        pushAndWall();
        pipes();
        return 0;
    } catch (const std::exception& error) {
        std::cerr << error.what() << '\n';
        return 1;
    }
}

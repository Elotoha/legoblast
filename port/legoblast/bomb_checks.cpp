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
}

int main() {
    try {
        fuseAndChain();
        pushAndWall();
        return 0;
    } catch (const std::exception& error) {
        std::cerr << error.what() << '\n';
        return 1;
    }
}

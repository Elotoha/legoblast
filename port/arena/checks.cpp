#include "rules.hpp"

#include <array>
#include <iostream>
#include <stdexcept>

using namespace ember;

void require(bool ok, const char* message) {
    if (!ok)
        throw std::runtime_error(message);
}

void idle(Arena& arena, int count) {
    for (int i = 0; i < count; ++i)
        arena.tick({});
}

void amber(Arena& arena, Point direction, bool plant = false) {
    arena.tick({Input{direction, plant}, Input{}});
}

void explosionChecks() {
    Layout layout{};
    layout[1 * Width + 3] = Tile::Crate;
    layout[2 * Width + 1] = Tile::Steel;
    Arena arena(layout);
    amber(arena, {-1, 0}); // Custom fixture has no border.
    require(arena.players()[0].cell == Point{0, 1}, "legal movement");
    idle(arena, 6);
    amber(arena, {-1, 0});
    require(arena.players()[0].cell == Point{0, 1}, "movement outside board");
    amber(arena, {1, 0});
    amber(arena, {}, true);
    idle(arena, FuseTicks - 2);
    require(arena.bombs().size() == 1 && arena.flameAt({1, 1}) == 0, "fuse expires too soon");
    idle(arena, 1);
    require(arena.bombs().empty() && arena.result() == Result::Cyan, "explosion or winner");
    require(arena.tileAt({3, 1}) == Tile::Floor && arena.flameAt({3, 1}) > 0 &&
            arena.flameAt({4, 1}) == 0 && arena.flameAt({1, 2}) == 0, "wall rules");
}

void chainChecks() {
    Arena arena(Layout{});
    amber(arena, {1, 0}, true);
    idle(arena, 7);
    amber(arena, {1, 0}, true);
    require(arena.bombs().size() == 2, "capacity or movement after planting");
    idle(arena, 6);
    amber(arena, {0, 1}, true);
    require(arena.bombs().size() == 2, "bomb capacity exceeded");
    idle(arena, FuseTicks - 17);
    require(arena.bombs().size() == 2, "chain begins too soon");
    idle(arena, 1);
    require(arena.bombs().empty() && arena.flameAt({4, 1}) > 0, "second blast did not chain");
}

void matchChecks() {
    Arena arena;
    require(arena.tileAt({0, 1}) == Tile::Steel && arena.tileAt({11, 7}) == Tile::Floor,
            "arena boundaries or spawn");
    arena.tick({Input{{}, true}, Input{{}, true}});
    idle(arena, FuseTicks - 1);
    require(arena.result() == Result::Draw && arena.players()[0].score == 0, "simultaneous deaths");
    arena.nextRound();
    idle(arena, RoundTicks);
    require(arena.result() == Result::Draw && arena.ticksLeft() == 0, "round timeout");
    arena.nextRound();
    for (int score = 1; score <= WinsNeeded; ++score) {
        amber(arena, {}, true);
        idle(arena, FuseTicks - 1);
        require(arena.players()[1].score == score, "score should persist across rounds");
        require(arena.matchComplete() == (score == WinsNeeded), "match point");
        arena.nextRound();
    }
    require(arena.players()[1].score == 0 && arena.result() == Result::Playing &&
            arena.bombs().empty() && arena.flameAt({1, 1}) == 0, "match reset");
}

int main() {
    try {
        explosionChecks();
        chainChecks();
        matchChecks();
        return 0;
    } catch (const std::exception& error) {
        std::cerr << error.what() << '\n';
        return 1;
    }
}

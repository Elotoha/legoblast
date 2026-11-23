#include "micro.hpp"
#include "bombs.hpp"
#include "players.hpp"

#include <algorithm>
#include <array>

namespace legoblast {
namespace {
constexpr int Safe = 255;
constexpr int SearchBudget = 45;
constexpr std::array<Point, 5> Direction{{{}, {0, -1}, {1, 0}, {0, 1}, {-1, 0}}};
constexpr std::array SearchOrder{2, 4, 1, 3};

int cellIndex(Point point) { return point.y * Width + point.x; }
bool inside(Point point) { return point.x >= 0 && point.y >= 0 && point.x < Width && point.y < Height; }

struct Route {
    bool visited{}, bent{};
    int from{}, along{}, distance{};
    int safety{Safe}, routeSafety{Safe}, points{1};
};

// Micro_BombAdd records the lowest fuse on an entire row or column unless
// walled in on both sides of that axis. Fuses decrease once per two VBLs.
struct Danger {
    std::array<int, Width> columns;
    std::array<int, Height> rows;
    Danger(const PlayerMap& map, const BombField& bombs) {
        columns.fill(Safe);
        rows.fill(Safe);
        const auto wall = [&](int x, int y) {
            const auto tile = map.at(x, y).visible;
            return tile >= 1 && tile <= 3;
        };
        for (const auto& bomb : bombs.bombs()) {
            if (!bomb.active)
                continue;
            const Point tile{short(bomb.cell.x / 2), short(bomb.cell.y / 2)};
            if (!inside(tile))
                continue;
            const auto x = tile.x * 2, y = tile.y * 2;
            if (!wall(x, y - 2) || !wall(x, y + 2))
                columns[tile.x] = std::min(columns[tile.x], std::max(0, bomb.time));
            if (!wall(x - 2, y) || !wall(x + 2, y))
                rows[tile.y] = std::min(rows[tile.y], std::max(0, bomb.time));
        }
    }
};
}

Buttons Micro::route(const Player& player, const PlayerMap& map, BombField& bombs) {
    const auto center = player.center();
    Point origin{short(center.x / TileSize), short(center.y / TileSize)};
    if (origin.x != previousCell_.x || origin.y != previousCell_.y) {
        previousCell_ = origin;
        alignmentTicks_ = 2;
    }
    if (alignmentTicks_) {
        --alignmentTicks_;
        const auto bias = [](int step) { return 4 * ((step < 0) - (step > 0)); };
        origin = {short((center.x + bias(player.previousStep.x)) / TileSize),
                  short((center.y + bias(player.previousStep.y)) / TileSize)};
    }
    if (!inside(origin))
        return {};

    const Danger danger(map, bombs);
    const bool bombAllowed = bombDelay_ == 0 && bombs.randomTest(30);
    if (bombDelay_)
        --bombDelay_;
    const auto perTile = 8 / std::max(1, player.speed);
    std::array<Route, Width * Height> cells{};
    std::array<Point, Width * Height> frontier{};
    cells[cellIndex(origin)].visited = true;
    frontier[0] = origin;
    std::size_t size = 1;
    Route best{};
    int chosen = -1;
    bool foundTarget = false, fire = false;

    // Micro_Routage_Step expands right, left, top, bottom. Later cells
    // inherit the first direction so the movement loop still handles walls.
    for (std::size_t i = 0; i < size && i < SearchBudget; ++i) {
        const auto current = frontier[i];
        const auto index = cellIndex(current);
        auto cell = cells[index];
        int children = 0;
        for (const auto direction : SearchOrder) {
            const auto step = Direction[direction];
            const Point next{short(current.x + step.x), short(current.y + step.y)};
            if (!inside(next) || (direction == 2 && next.x == Width - 1))
                continue;
            auto& route = cells[cellIndex(next)];
            const auto visible = map.at(2 * next.x, 2 * next.y).visible;
            if (route.visited || (visible != 0 && visible != 28))
                continue;
            const auto safe = std::min(danger.columns[next.x], danger.rows[next.y]);
            route.safety = safe == Safe ? Safe : std::max(0, safe - cell.distance * perTile);
            route.routeSafety = std::min(route.safety, cell.routeSafety);
            route.visited = true;
            route.from = cell.from ? cell.from : direction;
            route.along = direction;
            route.distance = cell.distance + 1;
            route.bent = cell.bent || (cell.along && cell.along != direction);
            if (visible == 28) {
                const auto tile = bombs.level().tiles[cellIndex(next)];
                route.points += tile == 66 ? 70 : tile == 65 ? 50 : 0;
            }
            frontier[size++] = next;
            ++children;
        }
        if (!cell.from)
            continue;
        const bool safer = cell.safety > best.safety ||
            (cell.safety == best.safety && cell.routeSafety > best.routeSafety);
        const bool worse = cell.safety < best.safety ||
            (cell.safety == best.safety && cell.routeSafety < best.routeSafety);
        if (chosen != -1 && (cell.routeSafety <= 3 || worse))
            continue;
        if (safer)
            foundTarget = false;
        if (index == target_)
            foundTarget = true;
        else if (chosen != -1 && !safer) {
            cell.points += cell.distance + 8 - 2 * children;
            if (previousDirection_ && ((previousDirection_ + 1) % 4) + 1 != cell.from)
                cell.points += 10;
            cell.points = std::min(cell.points, 255);
            if (cell.points < best.points + (foundTarget ? 60 : 0))
                continue;
        }
        chosen = index;
        best = cell;
        fire = bombAllowed && !alignmentTicks_ && cell.bent;
        if (fire)
            bombDelay_ = 20;
    }
    target_ = chosen;
    previousDirection_ = chosen >= 0 ? best.from : 0;
    const auto step = Direction[previousDirection_];
    return {.left = step.x < 0, .right = step.x > 0, .up = step.y < 0, .down = step.y > 0,
            .fire = fire && !player.previousFire};
}
}

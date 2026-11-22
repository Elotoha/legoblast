#include "rules.hpp"

#include <algorithm>
#include <string_view>

namespace ember {
namespace {
constexpr std::array<Point, 4> directions{{{1, 0}, {0, 1}, {-1, 0}, {0, -1}}};
constexpr std::array<Point, 2> spawns{{{1, 1}, {11, 7}}};
constexpr int MoveTicks = 7;

bool inside(Point cell) {
    return cell.x >= 0 && cell.x < Width && cell.y >= 0 && cell.y < Height;
}
int index(Point cell) { return cell.y * Width + cell.x; }
Point add(Point first, Point second) { return {first.x + second.x, first.y + second.y}; }
}

Layout defaultLayout() {
    constexpr std::array<std::string_view, Height> rows{
        "#############",
        "#...o..o..o.#",
        "#.#..#.#.#..#",
        "#o..o.o...#.#",
        "#..#o...o#..#",
        "#.#...o.o..o#",
        "#..#.#.#..#.#",
        "#.o..o..o...#",
        "#############",
    };
    Layout result{};
    for (int y = 0; y < Height; ++y)
        for (int x = 0; x < Width; ++x)
            result[index({x, y})] = rows[y][x] == '#' ? Tile::Steel :
                                    rows[y][x] == 'o' ? Tile::Crate : Tile::Floor;
    return result;
}

Arena::Arena(Layout layout) : layout_(layout) { restartMatch(); }

void Arena::restartMatch() {
    players_ = {};
    nextRound();
}

void Arena::nextRound() {
    if (matchComplete()) {
        restartMatch();
        return;
    }
    for (int i = 0; i < 2; ++i)
        players_[i] = Player{spawns[i], true, 0, players_[i].score};
    tiles_ = layout_;
    flames_.fill(0);
    bombs_.clear();
    ticksLeft_ = RoundTicks;
    result_ = Result::Playing;
}

bool Arena::matchComplete() const {
    return players_[0].score >= WinsNeeded || players_[1].score >= WinsNeeded;
}

Tile Arena::tileAt(Point cell) const {
    return inside(cell) ? tiles_[index(cell)] : Tile::Steel;
}

int Arena::flameAt(Point cell) const {
    return inside(cell) ? flames_[index(cell)] : 0;
}

bool Arena::hasBomb(Point cell) const {
    return std::ranges::any_of(bombs_, [&](const Bomb& bomb) { return bomb.cell == cell; });
}

void Arena::tick(const std::array<Input, 2>& input) {
    if (result_ != Result::Playing)
        return;
    for (auto& flame : flames_)
        if (flame > 0)
            --flame;

    for (int i = 0; i < 2; ++i) {
        auto& player = players_[i];
        if (input[i].plant && !hasBomb(player.cell) &&
            std::ranges::count_if(bombs_, [i](const Bomb& bomb) { return bomb.owner == i; }) < 2)
            bombs_.push_back({player.cell, i, FuseTicks});
    }
    std::array<Point, 2> destination{players_[0].cell, players_[1].cell};
    for (int i = 0; i < 2; ++i) {
        auto& player = players_[i];
        if (player.cooldown > 0)
            --player.cooldown;
        if (player.cooldown > 0 || std::ranges::find(directions, input[i].direction) == directions.end())
            continue;
        const auto target = add(player.cell, input[i].direction);
        if (tileAt(target) == Tile::Floor && !hasBomb(target))
            destination[i] = target;
    }
    if (destination[0] != destination[1] &&
        !(destination[0] == players_[1].cell && destination[1] == players_[0].cell)) {
        for (int i = 0; i < 2; ++i) {
            if (destination[i] != players_[i].cell) {
                players_[i].cell = destination[i];
                players_[i].cooldown = MoveTicks;
            }
        }
    }
    explode();
    for (auto& player : players_)
        player.alive = flameAt(player.cell) == 0;

    --ticksLeft_;
    if (!players_[0].alive || !players_[1].alive)
        finish(players_[0].alive ? Result::Amber : players_[1].alive ? Result::Cyan : Result::Draw);
    else if (ticksLeft_ == 0)
        finish(Result::Draw);
}

void Arena::explode() {
    const auto blocking = tiles_; // Simultaneous blasts see the same walls.
    std::vector<bool> fired(bombs_.size());
    for (auto& bomb : bombs_)
        --bomb.fuse;
    for (;;) {
        bool changed = false;
        for (std::size_t i = 0; i < bombs_.size(); ++i) {
            const auto& bomb = bombs_[i];
            if (fired[i] || (bomb.fuse > 0 && !flameAt(bomb.cell)))
                continue;
            fired[i] = changed = true;
            flames_[index(bomb.cell)] = FlameTicks;
            for (const auto direction : directions) {
                auto cell = bomb.cell;
                for (int range = 0; range < BlastRange; ++range) {
                    cell = add(cell, direction);
                    if (!inside(cell) || blocking[index(cell)] == Tile::Steel)
                        break;
                    flames_[index(cell)] = FlameTicks;
                    if (blocking[index(cell)] == Tile::Crate) {
                        tiles_[index(cell)] = Tile::Floor;
                        break;
                    }
                }
            }
        }
        if (!changed)
            break;
    }
    for (std::size_t i = bombs_.size(); i-- > 0;)
        if (fired[i])
            bombs_.erase(bombs_.begin() + i);
}

void Arena::finish(Result result) {
    result_ = result;
    if (result == Result::Amber || result == Result::Cyan)
        ++players_[result == Result::Amber ? 0 : 1].score;
}
}

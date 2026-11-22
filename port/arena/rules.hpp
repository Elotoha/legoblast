#pragma once

#include <array>
#include <vector>

namespace ember {
constexpr int Width = 13;
constexpr int Height = 9;
constexpr int TickMs = 20;
constexpr int FuseTicks = 90;
constexpr int FlameTicks = 21;
constexpr int RoundTicks = 75 * 1000 / TickMs;
constexpr int WinsNeeded = 3;
constexpr int BlastRange = 2;

struct Point {
    int x{};
    int y{};
    bool operator==(const Point&) const = default;
};
enum class Tile { Floor, Steel, Crate };
enum class Result { Playing, Amber, Cyan, Draw };
using Layout = std::array<Tile, Width * Height>;

struct Input {
    Point direction{};
    bool plant{};
};
struct Player {
    Point cell;
    bool alive{true};
    int cooldown{};
    int score{};
};
struct Bomb {
    Point cell;
    int owner;
    int fuse;
};

Layout defaultLayout();

class Arena {
public:
    explicit Arena(Layout layout = defaultLayout());

    void tick(const std::array<Input, 2>& input);
    void nextRound();
    void restartMatch();
    Tile tileAt(Point cell) const;
    int flameAt(Point cell) const;

    const auto& players() const { return players_; }
    const auto& bombs() const { return bombs_; }
    Result result() const { return result_; }
    int ticksLeft() const { return ticksLeft_; }
    bool matchComplete() const;

private:
    void explode();
    void finish(Result result);
    bool hasBomb(Point cell) const;

    Layout layout_;
    Layout tiles_;
    std::array<int, Width * Height> flames_{};
    std::array<Player, 2> players_;
    std::vector<Bomb> bombs_;
    int ticksLeft_{RoundTicks};
    Result result_{Result::Playing};
};
}

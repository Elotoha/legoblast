#pragma once

#include "level.hpp"

#include <deque>

namespace legoblast {
class PlayerMap;

struct Bomb {
    Point cell; // Upper-left 8 px subcell of the 16 px bomb.
    unsigned owner;
    int time, loops, energy, frame{};
    bool active{true};
    bool rebounds{}, moved{}, frozen{}, held{};
    int image() const { return frame + ((frozen || held) ? 210 : 0); }
};

struct BombSettings {
    int capacity, time, loops, energy;
    bool rebounds{}, held{};
};

struct BrokenBlock {
    Point cell;
    unsigned frame;
    unsigned last;
    std::uint8_t replacement;
};

class BombField {
public:
    explicit BombField(const Level& level);
    bool plant(unsigned owner, Point center, PlayerMap& map, bool rebounds = false);
    bool plant(unsigned owner, Point center, PlayerMap& map, const BombSettings& settings);
    unsigned collectBonus(Point cell, PlayerMap& map);
    void detonateAll();
    void freeze();
    void releaseClock(unsigned owner);
    void scatter(PlayerMap& map);
    void tick(PlayerMap& map);
    const auto& bombs() const { return bombs_; }
    const auto& brokenBlocks() const { return broken_; }
    const Level& level() const { return level_; }
    std::uint8_t flameMask(int x, int y) const;

private:
    struct Arm {
        Point front, step;
        std::vector<Point> path;
        int remaining{};
        bool expanding{true}, tip{}, tail{};
    };
    struct Blast {
        std::vector<Arm> arms;
        bool erasing{};
    };
    void tickBombs(PlayerMap& map);
    void moveBomb(std::size_t id, PlayerMap& map);
    void tickFlames(PlayerMap& map);
    bool passFlame(Arm& arm, Point point, PlayerMap& map);
    void breakBlock(Point cell, PlayerMap& map);
    void tickBlocks(PlayerMap& map);
    void rebuildFlameMasks();
    Level level_;
    std::array<std::uint8_t, Width * Height> hiddenBonuses_{};
    std::vector<Bomb> bombs_;
    std::deque<Blast> blasts_;
    std::size_t flameSlots_{};
    std::vector<BrokenBlock> broken_;
    std::array<std::uint8_t, 2 * Width * 2 * Height> masks_{};
    bool bombPass_{true};
    int frozenTicks_{};
    RandomState random_{};
};
}

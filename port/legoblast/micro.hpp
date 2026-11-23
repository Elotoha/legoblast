#pragma once

#include "level.hpp"

namespace legoblast {
class BombField;
class PlayerMap;
struct Buttons;
struct Player;

class Micro {
public:
    Buttons route(const Player& player, const PlayerMap& map, BombField& bombs);

private:
    Point previousCell_{-1, -1};
    int target_{-1};
    int previousDirection_{};
    unsigned alignmentTicks_{}, bombDelay_{};
};
}

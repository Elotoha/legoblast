#include "lia.hpp"

#include <cmath>
#include <iostream>
#include <stdexcept>

using namespace legoblast;

namespace {
void require(bool condition, const char* message) {
    if (!condition)
        throw std::runtime_error(message);
}

void shortFuse() {
    Level level{};
    level.speed = 2;
    level.bombs = 1;
    level.reach = 10;
    level.bombTime = 1;
    level.totalTime = level.warningTime = 1500;
    level.starts[0] = {4, 4};
    level.starts[1] = {7, 4};
    Session game(level, {.fiveWins = false});
    constexpr auto seat = static_cast<std::size_t>(Control::Lia);
    Controls join{};
    join[seat].fire = true;
    game.tick(join);
    join = {};
    join[0].fire = true;
    game.tick(join);
    for (int i = 0; i < 350; ++i)
        game.tick({});
    require(game.players()[0].control == static_cast<int>(Control::Lia),
            "Lia could not claim a player slot");

    Controls plant{};
    plant[0].fire = true;
    game.tick(plant);
    require(!game.bombs().settled() && game.bombs().bombs().front().owner == 1,
            "the opponent failed to plant the test bomb");

    Lia lia;
    bool sawFlame = false;
    for (unsigned decision = 0; decision < 12 && liaPlaying(game); ++decision) {
        const auto before = game.elapsed();
        const auto time = game.bombs().bombs().front().time;
        const auto action = lia.choose(game, 0);
        require(action < LiaActionCount && game.elapsed() == before &&
                game.bombs().bombs().front().time == time, "planning changed the live game");
        for (unsigned tick = 0; tick < LiaActionTicks && liaPlaying(game); ++tick) {
            Controls input{};
            input[seat] = liaButtons(action, tick);
            game.tick(input);
            sawFlame |= game.bombs().flameMask(14, 8) != 0;
            require(liaAlive(game.players()[0]), "Lia stayed in the short-fuse blast");
        }
    }
    const auto obs = liaObservation(game, 0);
    require(sawFlame && std::ranges::all_of(obs, [](float value) { return std::isfinite(value); }),
            "no flame observed or invalid neural input");
}
void multipleLias() {
    Level level{};
    level.speed = 2;
    level.totalTime = level.warningTime = 1000;
    Session game(level);
    LiaGroup lias;
    Controls input{};
    input[0].fire = true;
    game.tick(input);
    for (std::size_t i = 0; i < PlayerCount - 1; ++i) {
        input = {};
        require(lias.read(game, input, 1) == 1 && input[FirstLiaControl + i].fire,
                "summon did not use the next free Lia controller");
        game.tick(input);
        require(game.players()[0].control == 0 &&
                game.players()[i + 1].control == static_cast<int>(FirstLiaControl + i),
                "summon displaced a player or claimed multiple slots");
    }
    input = {};
    require(lias.read(game, input, 1) == 0, "Lia joined a full match");
    game.replayArena();
    for (unsigned i = 0; i < 45; ++i) {
        input = {};
        lias.read(game, input, 0);
        game.tick(input);
    }
    for (std::size_t i = 1; i < PlayerCount; ++i)
        require(liaAlive(game.players()[i]), "a Lia did not respawn on the next round");
}

}

int main() {
    try {
        shortFuse();
        multipleLias();
    } catch (const std::exception& error) {
        std::cerr << error.what() << '\n';
        return 1;
    }
}

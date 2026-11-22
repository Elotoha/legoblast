#include "players.hpp"
#include "bombs.hpp"

#include <iostream>
#include <stdexcept>

using namespace legoblast;

namespace {
void expect(bool condition, const char* message) {
    if (!condition)
        throw std::runtime_error(message);
}

Buttons& keyboard(Controls& controls, Control control = Control::Keyboard1) {
    return controls[static_cast<std::size_t>(control)];
}

struct Fixture {
    Level level{};
    Players players;
    Controls controls{};
    PlayerTick timing{};

    Fixture() {
        level.speed = 2;
        level.starts.fill({2, 2});
        players.prepare(level, true, false);
    }

    void tick(PlayerMap& map, int times = 1) {
        for (int i = 0; i < times; ++i) {
            ++timing.autoCounter;
            players.tick(controls, timing, map);
        }
    }

    void appear(PlayerMap& map) {
        keyboard(controls).fire = true;
        tick(map);
        keyboard(controls).fire = false;
        tick(map, 29);
    }

    const Player& player() const { return players.slots()[0]; }
};

void appearance() {
    Fixture f;
    PlayerMap map(f.level);
    f.timing.fiveWinMatch = true;
    keyboard(f.controls).fire = true;
    keyboard(f.controls, Control::Keyboard2).fire = true;
    f.tick(map);
    expect(f.player().activation == Activation::Hidden && f.player().fireRequest == 1 &&
           f.players.slots()[1].control == -1, "JoyList reservation and keyboard exclusion");
    f.controls = {};
    f.timing.levelInfoState = -1;
    f.tick(map, 38);
    expect(f.player().activation == Activation::Hidden, "wait before VBL 40");
    f.tick(map);
    expect(f.player().sprite.x == 160 && f.player().sprite.y == 58 &&
           f.player().frame == 168 && f.player().activation == Activation::AwaitRelease &&
           f.timing.levelTimerRunning && f.timing.requestClearBar, "PrepPos and first appearance");
    keyboard(f.controls).right = true;
    f.tick(map, 27);
    expect(f.player().frame == 141 && f.player().center().x == 39 &&
           f.timing.levelInfoState == 3, "appearance animation and restore request");
    f.tick(map);
    expect(f.player().frame == 33 && f.player().teleportPhase == 0 &&
           f.player().center().x == 39, "last animation tick must not move");
    f.tick(map);
    expect(f.player().activation == Activation::Ready && f.player().center().x == 41 &&
           f.player().frame == 0, "first walking tick");
    f.players.prepare(f.level, false, false);
    f.timing = {};
    f.controls = {};
    f.tick(map, 99);
    expect(f.player().activation == Activation::Hidden, "DontMove timer early");
    f.tick(map);
    expect(f.player().activation == Activation::AwaitRelease && f.player().roundsPlayed == 2,
           "retained input and automatic appearance after 100 VBL");
}

void movement() {
    Fixture f;
    PlayerMap map(f.level);
    f.appear(map);
    keyboard(f.controls) = {.right = true, .down = true};
    f.tick(map);
    expect(f.player().center().x == 39 && f.player().center().y == 44 && f.player().frame == 8,
           "vertical diagonal priority from idle");
    keyboard(f.controls) = {.right = true};
    f.tick(map);
    map.at(6, 5).visible = 1;
    keyboard(f.controls).down = true;
    f.tick(map);
    expect(f.player().center().x == 41 && f.player().center().y == 44 &&
           f.player().previousStep.x == 2 && f.player().frame == 1,
           "wall uses forward probe while animation uses saved input");
    map.at(6, 5).visible = 0;
    map.at(6, 5).slab = 5;
    f.tick(map);
    expect(f.player().center().x == 41, "anti-player slab");
    map.at(6, 5).slab = 4;
    f.tick(map);
    expect(f.player().center().x == 43, "anti-fire slab leaves players free");
    map.at(5, 5).slab = 14;
    f.controls = {};
    f.tick(map);
    expect(f.player().center().y == 45 && f.player().frame == 32,
           "conveyor moves the player but must not select a walk cycle");
}

void bombCollision() {
    Fixture f;
    f.level.push = 1;
    f.players.prepare(f.level, true, false);
    PlayerMap map(f.level);
    f.appear(map);
    auto& target = map.at(6, 5);
    target.visible = 29;
    target.bomb = 0;
    map.bombVelocities.push_back({});
    keyboard(f.controls).right = true;
    f.tick(map);
    expect(f.player().center().x == 39 && map.bombVelocities[0].x == 1 && !f.player().canPush,
           "pushing sets bomb velocity and blocks the current step");
    auto& current = map.at(4, 5);
    current.visible = 29;
    current.bomb = 0;
    map.bombVelocities[0] = {};
    f.tick(map);
    expect(f.player().center().x == 41 && f.player().canPush, "transition inside the same bomb");
}

void teleporter() {
    Fixture f;
    f.level.teleporters.push_back({{4, 5}, {12, 10}});
    PlayerMap map(f.level);
    f.appear(map);
    expect(f.player().teleportPermission == 0, "spawn on active portal must be locked");
    auto& entry = map.at(4, 5);
    const auto destination = entry.teleporter;
    entry.teleporter = {};
    f.tick(map);
    entry.teleporter = destination;
    map.at(13, 11).visible = 2;
    f.tick(map);
    expect(f.player().teleportPhase == 0, "all four destination subcells must be free");
    map.at(13, 11).visible = 0;
    f.tick(map);
    expect(f.player().teleportPhase == 1 && f.player().frame == 141, "disappearance begins");
    f.tick(map, 27);
    expect(f.player().teleportPhase == -1 && f.player().center().x == 103 &&
           f.player().center().y == 90, "teleport moves coordinates on frame 168");
    f.tick(map, 28);
    expect(f.player().teleportPhase == 0 && f.player().frame == 33, "destination appearance");
}
void bonusEffects() {
    const auto collect = [](unsigned bonus) {
        Fixture f;
        f.level.tiles[2 * Width + 2] = static_cast<std::uint8_t>(64 + bonus);
        f.level.bombs = 3;
        f.level.bombTime = 15;
        f.level.reach = 5;
        f.players.prepare(f.level, true, false);
        PlayerMap map(f.level);
        BombField bombs(f.level);
        f.appear(map);
        f.players.tick(f.controls, f.timing, map, &bombs);
        expect(!bombs.collectBonus({4, 5}, map) && !map.at(5, 5).visible,
               "collected bonus must vanish from all four subcells");
        return f.player();
    };
    expect(collect(1).flameEnergy == 6 && collect(21).flameEnergy == 15, "flame upgrades");
    expect(collect(2).bombCapacity == 4 && collect(20).bombCapacity == 8, "capacity upgrades");
    expect(collect(3).push && collect(17).clock, "push and clock toggles");
    expect(collect(5).flameEnergy == 3 && collect(12).flameEnergy == 50, "temporary flame effects");
    expect(collect(6).fuse == 56 && collect(9).fuse == 166, "fast and slow fuse effects");
    expect(collect(7).speed == 1 && collect(8).speed == 4, "speed effects");
    expect(collect(4).effects[0] == 1500 && collect(13).effects[4] == 750 &&
           collect(14).bombCapacity == 13 && collect(15).effects[6] == 750 &&
           collect(18).effects[7] == 1500 && collect(23).effects[8] == 1500,
           "temporary bonus durations and extra capacity");
}

}

int main() {
    try {
        appearance();
        movement();
        bombCollision();
        teleporter();
        bonusEffects();
        return 0;
    } catch (const std::exception& error) {
        std::cerr << error.what() << '\n';
        return 1;
    }
}

#include "session.hpp"

#include <algorithm>
#include <iostream>
#include <stdexcept>

using namespace legoblast;

namespace {
void check(bool ok, const char* message) {
    if (!ok)
        throw std::runtime_error(message);
}

Level fixture() {
    Level level{};
    level.starts[0] = {2, 2};
    level.starts[1] = {11, 10};
    level.speed = 2;
    level.totalTime = 1000;
    level.warningTime = 1000;
    level.bombs = 1;
    level.bombTime = 1;
    level.reach = 5;
    return level;
}

void advance(Session& session, int ticks, const Controls& input = {}) {
    for (int i = 0; i < ticks; ++i)
        session.tick(input);
}

void join(Session& session, bool thirdPlayer = false) {
    Controls input{};
    input[0].fire = input[1].fire = true;
    input[2].fire = thirdPlayer;
    advance(session, 40, input);
    advance(session, 29);
    check(session.phase() == RoundPhase::Running, "first appearance must start the match clock");
}

void result(Session& session) {
    for (int i = 0; i < 1200 && session.phase() != RoundPhase::Result &&
                               session.phase() != RoundPhase::MatchComplete; ++i)
        session.tick({});
    check(session.phase() == RoundPhase::Result || session.phase() == RoundPhase::MatchComplete,
          "round did not finish");
}

void fiveWins() {
    Session session(fixture());
    const auto initial = session.remaining();
    advance(session, 10);
    check(session.remaining() == initial, "clock ran before a player appeared");
    Controls next{};
    next[0].fire = next[1].fire = true;
    Controls plant{};
    plant[0].fire = true;
    for (unsigned win = 1; win <= 5; ++win) {
        join(session);
        advance(session, 350);
        session.tick(plant);
        check(!session.bombs().settled(), "player did not plant");
        advance(session, 2);
        session.togglePause();
        const auto time = session.remaining();
        const auto fuse = session.bombs().bombs().front().time;
        advance(session, 10);
        check(session.remaining() == time && session.bombs().bombs().front().time == fuse,
              "pause changed time or bomb");
        session.togglePause();
        result(session);
        check(session.score()[1] == win && session.winners()[1] && session.bombs().settled(),
              "score and surviving player");
        check((session.phase() == RoundPhase::MatchComplete) == (win == 5), "wrong match target");
        advance(session, 10, next);
        if (win < 5)
            check(session.roundNumber() == win + 1 && session.players()[0].control == 0 &&
                  session.players()[1].control == 1, "next round lost controllers");
    }
    check(session.phase() == RoundPhase::Podium && session.score()[1] == 5, "fifth victory did not open the podium");
    advance(session, 100, next);
    check(session.phase() == RoundPhase::Podium, "held Fire skipped the podium");
    session.tick({});
    session.tick(next);
    advance(session, 100, next);
    check(session.phase() == RoundPhase::Statistics, "podium did not open the statistics");
    session.tick({});
    session.tick(next);
    check(session.score()[1] == 0 && session.roundNumber() == 1, "new match did not reset scores");
}

void timeoutAndSpiral() {
    auto level = fixture();
    level.totalTime = 45;
    level.warningTime = 10;
    level.minX = 4;
    level.minY = 4;
    level.maxX = 6;
    level.maxY = 6;
    level.fillCount = 1;
    level.blocks[19] = 143;
    level.bombTime = 40;
    Session session(level);
    join(session);
    Controls plant{};
    plant[0].fire = true;
    session.tick(plant);
    check(!session.bombs().settled(), "long fuse missing");
    advance(session, 33);
    check(session.closingFrames().size() == 1 &&
          session.closingFrames().front().tile.x == 4 && session.closingFrames().front().tile.y == 4,
          "spiral first tile");
    while (session.remaining())
        session.tick({});
    check(session.phase() == RoundPhase::Draining, "timeout must drain bombs and animations");
    result(session);
    check(session.score()[1] == 1 && session.bombs().settled(), "timeout bomb did not resolve");
}

void draw() {
    Session session(fixture());
    join(session);
    Controls fire{};
    fire[0].fire = fire[1].fire = true;
    session.tick(fire);
    result(session);
    check(std::ranges::all_of(session.score(), [](auto score) { return score == 0; }),
          "simultaneous elimination must not award a point");
}

void retries() {
    Controls plant{};
    plant[0].fire = true;
    Session session(fixture());
    join(session);
    session.tick(plant);
    for (int i = 0; i < 400 && !session.retrying(); ++i)
        session.tick({});
    check(session.retrying() && session.roundNumber() == 1 && session.score()[1] == 0,
          "early death did not replay the same round");
    Controls absent{};
    absent[2].fire = true;
    advance(session, 170, absent);
    check(session.players()[0].teleportPhase == 0 && session.players()[1].teleportPhase == 0 &&
          session.players()[2].control == -1, "retry must revive the two participants only");
    session.tick(plant);
    result(session);
    check(session.score()[1] == 1, "the same player retried twice");

    auto level = fixture();
    level.starts[2] = {15, 12};
    Session survivor(level, {.survivor = true});
    join(survivor, true);
    advance(survivor, 350);
    survivor.tick(plant);
    for (int i = 0; i < 400 && !survivor.retrying(); ++i)
        survivor.tick({});
    advance(survivor, 170);
    check(survivor.retrying() && survivor.players()[0].dead && survivor.players()[1].visible &&
          survivor.players()[2].visible, "survivor replay did not remove the defeated player");
    Controls second{};
    second[1].fire = true;
    survivor.tick(second);
    result(survivor);
    check(survivor.score()[2] == 1, "last survivor did not win");
}

void contactAndBumpers() {
    auto level = fixture();
    level.starts[1] = level.starts[0];
    level.tiles[2 * Width + 2] = 64 + 8; // Fast movement.
    Session contact(level);
    join(contact);
    advance(contact, 2);
    check(contact.players()[0].speed == 4 && contact.players()[1].speed == 4 &&
          contact.players()[0].effects[3] == contact.players()[1].effects[3],
          "same-tile contact did not transmit the speed disease");

    level = fixture();
    level.tiles[2 * Width + 1] = 11; // Right bumper.
    Session bump(level);
    join(bump);
    const auto start = bump.players()[0].center();
    for (int i = 0; i < 30 && !bump.players()[0].bumper.x; ++i)
        bump.tick({});
    check(bump.players()[0].bumper.x == 6 && bump.players()[0].center().x == start.x + 6,
          "bumper did not push the player at frame 233");
}

void modes() {
    auto level = fixture();
    level.starts[2] = {15, 12};
    Session teams(level, {.teams = true});
    join(teams, true);
    advance(teams, 350);
    Controls plant{};
    plant[1].fire = true;
    teams.tick(plant);
    result(teams);
    check(teams.score()[0] == 1 && teams.winners()[0] && teams.winners()[2] && !teams.winners()[1],
          "both surviving teammates must win");

    level.totalTime = level.warningTime = 1;
    level.name = "first";
    auto second = level;
    second.name = "second";
    auto confirm = Controls{};
    confirm[0].fire = true;
    Session sequence({level, second}, 0, {.fiveWins = false, .arena = ArenaMode::Sequential});
    sequence.tick(confirm);
    check(sequence.phase() == RoundPhase::Running, "Free Play waits for the 5 Win Match banner");
    result(sequence);
    advance(sequence, 10, confirm);
    check(sequence.arenaIndex() == 1 && sequence.arena().name == "second", "sequential arena index");
    sequence.tick(confirm);
    result(sequence);
    check(sequence.arenasFinished(), "sequential mode must stop at the last arena");

    Session random({level, second}, 0, {.fiveWins = false, .arena = ArenaMode::Random});
    random.tick(confirm);
    result(random);
    auto rng = random.bombs().randomState();
    const auto expected = (rng.next() & 0xfff) % 2;
    advance(random, 10, confirm);
    check(random.arenaIndex() == expected, "random mode must use the 68k RNG");

    level.starts[3] = {15, 2};
    level.starts[4] = {2, 12};
    level.starts[5] = {10, 5};
    Session dyna(level, {.fiveWins = false, .arena = ArenaMode::Dynablaster});
    const auto firstTiles = dyna.arena().tiles;
    dyna.tick(confirm);
    result(dyna);
    advance(dyna, 10, confirm);
    check(dyna.arena().tiles != firstTiles, "Dynablaster must generate a new maze");
}
}

int main() {
    try {
        fiveWins();
        timeoutAndSpiral();
        draw();
        retries();
        contactAndBumpers();
        modes();
        return 0;
    } catch (const std::exception& error) {
        std::cerr << error.what() << '\n';
        return 1;
    }
}

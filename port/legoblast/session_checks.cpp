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

void join(Session& session) {
    Controls input{};
    input[0].fire = input[1].fire = true;
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
}

int main() {
    try {
        fiveWins();
        timeoutAndSpiral();
        draw();
        return 0;
    } catch (const std::exception& error) {
        std::cerr << error.what() << '\n';
        return 1;
    }
}

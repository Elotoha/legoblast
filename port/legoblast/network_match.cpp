#include "network_match.hpp"

namespace legoblast {
void NetworkBots::fill(const Session& session, Controls& input, std::string_view roster, const LiaModel* model) {
    if (!liaPlaying(session) || session.paused()) return;
    const auto tick = session.elapsed();
    if (tick < previousTick_ || round_ != session.roundNumber()) {
        for (auto& bot : lias_) bot.reset();
        actions_.fill(0);
    }
    round_ = session.roundNumber();
    previousTick_ = tick;
    for (std::size_t i = 0; i < std::min(roster.size(), NetworkPlaces); ++i) {
        const auto& player = session.players()[i];
        if (!player.dead && player.activation == Activation::Hidden) {
            input[i].fire = true;
        } else if (roster[i] == 'L' && liaAlive(player)) {
            const auto step = (tick + LiaActionTicks - i) % LiaActionTicks;
            if (!step) actions_[i] = lias_[i].choose(session, i, model);
            input[i] = liaButtons(actions_[i], step);
        }
    }
}

unsigned NetworkBots::microMask(std::string_view roster) {
    unsigned mask = 0;
    for (std::size_t i = 0; i < std::min(roster.size(), NetworkPlaces); ++i)
        if (roster[i] == 'M') mask |= 1u << i;
    return mask;
}

void applyMatchCommand(Session& session, std::string_view command) {
    if (command == "PREV") session.previousArena();
    else if (command == "NEXT") session.nextArena();
    else if (command == "REPLAY") session.replayArena();
    else if (command == "PAUSE") session.togglePause();
    else if (command == "SKIP" && session.phase() == RoundPhase::Podium) session.skipPodium();
}
}

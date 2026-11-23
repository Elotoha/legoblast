#include "lia.hpp"

#include <charconv>
#include <cstdlib>
#include <iostream>
#include <optional>
#include <random>
#include <sstream>
#include <stdexcept>

using namespace legoblast;

namespace {
enum class Kind { External, Idle, Random, Micro, Lia, Neural };

struct Policy {
    Kind kind{Kind::External};
    std::optional<LiaModel> model;

    explicit Policy(std::string_view name) {
        if (name == "external") kind = Kind::External;
        else if (name == "idle") kind = Kind::Idle;
        else if (name == "random") kind = Kind::Random;
        else if (name == "micro") kind = Kind::Micro;
        else if (name == "lia" || name.starts_with("lia=")) kind = Kind::Lia;
        else if (name.starts_with("neural=")) kind = Kind::Neural;
        else throw std::runtime_error("unknown lab policy: " + std::string(name));
        if (const auto equal = name.find('='); equal != name.npos)
            model.emplace(std::filesystem::path(name.substr(equal + 1)));
    }
};

unsigned number(std::string_view raw) {
    unsigned value{};
    const auto [end, error] = std::from_chars(raw.data(), raw.data() + raw.size(), value);
    if (error != std::errc{} || end != raw.data() + raw.size())
        throw std::runtime_error("expected an unsigned integer");
    return value;
}

class Duel {
public:
    Duel(const Level& level, const Policy& first, const Policy& second, unsigned seed, unsigned maxTicks)
        : game_(level, {.fiveWins = false}), policies_{&first, &second}, maxTicks_(maxTicks), random_(seed) {
        if (maxTicks_ == 0 || (first.kind == Kind::Micro && second.kind == Kind::Micro))
            throw std::runtime_error("use a positive horizon and at most one Micro");
        RandomState initial{};
        initial.init(seed);
        game_.resetMatch(initial);
        // Join one at a time so Micro can occupy either starting slot.
        for (std::size_t seat = 0; seat < 2; ++seat) {
            Controls input{};
            controls_[seat] = policies_[seat]->kind == Kind::Micro ? static_cast<unsigned>(Control::Micro) : seat;
            input[controls_[seat]].fire = true;
            game_.tick(input);
        }
        game_.tick({});
    }

    void step(unsigned external = 0) {
        if (done() || external >= LiaActionCount)
            throw std::runtime_error("step outside live episode or invalid action");
        std::array<unsigned, 2> actions{};
        for (std::size_t seat = 0; seat < actions.size(); ++seat) {
            if (!liaAlive(game_.players()[seat]))
                continue;
            const auto& policy = *policies_[seat];
            switch (policy.kind) {
            case Kind::External: actions[seat] = external; break;
            case Kind::Random:
                actions[seat] = std::uniform_int_distribution<unsigned>(0, LiaActionCount - 1)(random_);
                break;
            case Kind::Lia:
                actions[seat] = bots_[seat].choose(game_, seat, policy.model ? &*policy.model : nullptr);
                break;
            case Kind::Neural: {
                const auto logits = policy.model->logits(liaObservation(game_, seat));
                actions[seat] = std::ranges::max_element(logits) - logits.begin();
                break;
            }
            default: break;
            }
        }
        for (unsigned tick = 0; tick < LiaActionTicks && !done(); ++tick) {
            Controls input{};
            for (std::size_t seat = 0; seat < actions.size(); ++seat)
                if (game_.players()[seat].activation == Activation::Hidden && !game_.players()[seat].dead)
                    input[controls_[seat]].fire = true;
                else
                    input[controls_[seat]] = liaButtons(actions[seat], tick);
            const auto before = game_.elapsed();
            game_.tick(input);
            ++ticks_;
            if (game_.elapsed() < before) {
                for (auto& bot : bots_)
                    bot.reset();
                break;
            }
        }
    }

    bool done() const { return terminal() || ticks_ >= maxTicks_; }
    bool terminal() const { return !liaPlaying(game_); }
    unsigned ticks() const { return ticks_; }
    bool won(std::size_t seat) const { return terminal() && game_.winners()[seat]; }
    auto observation(std::size_t seat) const { return liaObservation(game_, seat); }
    double progress(std::size_t seat) const {
        const auto& player = game_.players()[seat];
        return 0.025 * player.bonusesTaken - 0.002 * player.bombsPlanted -
               0.15 * player.deaths;
    }

private:
    Session game_;
    std::array<const Policy*, 2> policies_;
    std::array<unsigned, 2> controls_{};
    std::array<Lia, 2> bots_;
    unsigned maxTicks_, ticks_{};
    std::mt19937 random_;
};

void reply(const Duel& match, std::size_t seat, double reward) {
    std::cout << "{\"reward\":" << reward
              << ",\"terminated\":" << match.terminal()
              << ",\"truncated\":" << (match.done() && !match.terminal())
              << ",\"outcome\":" << (int(match.won(seat)) - int(match.won(1 - seat)))
              << ",\"observation\":[";
    const auto obs = match.observation(seat);
    for (std::size_t i = 0; i < obs.size(); ++i)
        std::cout << (i ? "," : "") << obs[i];
    std::cout << "]}" << std::endl;
}

void serve(int argc, char** argv) {
    const Policy player("external"), enemy(argv[2]);
    if (enemy.kind == Kind::External)
        throw std::runtime_error("the opponent must be autonomous");
    std::vector<Level> levels;
    for (int i = 3; i < argc; ++i)
        levels.push_back(loadLevel(argv[i]));
    std::optional<Duel> match;
    std::size_t seat{};
    std::string line;
    while (std::getline(std::cin, line)) {
        std::istringstream message(line);
        char command{};
        message >> command;
        if (command == 'R') {
            unsigned arena{}, seed{}, maxTicks{};
            if (!(message >> arena >> seat >> seed >> maxTicks) || seat > 1 || arena >= levels.size())
                throw std::runtime_error("expected R arena-index seat seed max-ticks");
            match.emplace(levels[arena], seat ? enemy : player, seat ? player : enemy, seed, maxTicks);
            reply(*match, seat, 0);
        } else if (command == 'S' && match) {
            unsigned action{};
            if (!(message >> action))
                throw std::runtime_error("expected S action");
            const auto before = match->progress(seat);
            match->step(action);
            const auto outcome = int(match->won(seat)) - int(match->won(1 - seat));
            reply(*match, seat, outcome + match->progress(seat) - before);
        } else {
            throw std::runtime_error("expected reset or step");
        }
    }
}

void tournament(int argc, char** argv) {
    const auto level = loadLevel(argv[2]);
    const Policy first(argv[3]), second(argv[4]);
    if (first.kind == Kind::External || second.kind == Kind::External)
        throw std::runtime_error("tournament policies must be autonomous");
    const auto pairs = number(argv[5]);
    const auto seed = argc > 6 ? number(argv[6]) : 1;
    const auto limit = argc > 7 ? number(argv[7]) : 4000;
    if (!pairs)
        throw std::runtime_error("expected at least one pair of rounds");
    unsigned wins{}, losses{}, draws{}, truncated{};
    for (unsigned i = 0; i < pairs; ++i)
        for (std::size_t seat = 0; seat < 2; ++seat) {
            Duel match(level, seat ? second : first, seat ? first : second, seed + i, limit);
            while (!match.done())
                match.step();
            const int outcome = int(match.won(seat)) - int(match.won(1 - seat));
            wins += outcome > 0;
            losses += outcome < 0;
            draws += outcome == 0 && match.terminal();
            truncated += !match.terminal();
            std::cout << "{\"seed\":" << seed + i << ",\"seat\":" << seat
                      << ",\"ticks\":" << match.ticks() << ",\"outcome\":" << outcome
                      << ",\"truncated\":" << !match.terminal() << "}" << std::endl;
        }
    std::cout << "{\"wins\":" << wins << ",\"losses\":" << losses
              << ",\"draws\":" << draws << ",\"truncated\":" << truncated << "}" << std::endl;
}
}

int main(int argc, char** argv) {
    try {
        if (argc >= 4 && std::string_view(argv[1]) == "serve")
            serve(argc, argv);
        else if (argc >= 6 && argc <= 8 && std::string_view(argv[1]) == "duel")
            tournament(argc, argv);
        else
            throw std::runtime_error("usage: legoblast_lab serve OPPONENT LEVEL...\n"
                                     "       legoblast_lab duel LEVEL POLICY_A POLICY_B PAIRS [SEED [MAX_TICKS]]");
        return EXIT_SUCCESS;
    } catch (const std::exception& error) {
        std::cerr << error.what() << '\n';
        return EXIT_FAILURE;
    }
}

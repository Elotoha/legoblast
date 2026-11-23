#include "lia.hpp"

#include <cmath>
#include <fstream>
#include <limits>
#include <queue>
#include <stdexcept>
#include <tuple>
#include <utility>

namespace legoblast {
namespace {
constexpr int Cells = Width * Height;
constexpr std::array<Point, 4> Directions{{{-1, 0}, {1, 0}, {0, -1}, {0, 1}}};
constexpr unsigned SearchDepth = 5;
constexpr unsigned PathsPerAction = 3;
// Freeze lasts 500 VBL. Allow time for a long fuse and for the flames to retract.
constexpr unsigned ForecastLimit = 900;

bool inside(Point tile) { return tile.x >= 0 && tile.x < Width && tile.y >= 0 && tile.y < Height; }
int index(Point tile) { return tile.y * Width + tile.x; }
Point tileAt(Point center) { return {short(center.x >> 4), short(center.y >> 4)}; }
Point tileOf(const Player& player) { return tileAt(player.center()); }
Point add(Point a, Point b) { return {short(a.x + b.x), short(a.y + b.y)}; }
bool canWalk(const PlayerCell& cell) { return !cell.visible || cell.visible == 28 || cell.visible == 30; }

bool rival(const Session& game, std::size_t self, std::size_t other) {
    return other != self && (!game.isTeamMatch() || other % 2 != self % 2) && liaAlive(game.players()[other]);
}

std::array<int, Cells> objectives(const Session& game, std::size_t self) {
    std::array<int, Cells> distance;
    distance.fill(50);
    using Entry = std::pair<int, int>;
    std::priority_queue<Entry, std::vector<Entry>, std::greater<>> frontier;
    const auto offer = [&](Point point, int cost) {
        if (inside(point) && cost < distance[index(point)]) {
            distance[index(point)] = cost;
            frontier.emplace(cost, index(point));
        }
    };
    std::array<std::vector<Point>, Cells> entrances;
    for (int y = 0; y < Height; ++y)
        for (int x = 0; x < Width; ++x) {
            const Point tile{short(x), short(y)};
            const auto& cell = game.map().at(2 * x, 2 * y);
            if (cell.teleporter.x || cell.teleporter.y) {
                const Point destination{short(cell.teleporter.x / 2), short(cell.teleporter.y / 2)};
                if (inside(destination))
                    entrances[index(destination)].push_back(tile);
            }
            if (!canWalk(cell))
                continue;
            if (cell.visible == 28 && game.bombs().level().tiles[index(tile)] >= 65)
                offer(tile, 0);
            for (const auto direction : Directions) {
                const auto near = add(tile, direction);
                if (inside(near) && game.map().at(near.x * 2, near.y * 2).visible == 2)
                    offer(tile, 5);
            }
        }
    for (std::size_t other = 0; other < PlayerCount; ++other)
        if (rival(game, self, other))
            offer(tileOf(game.players()[other]), 0);

    while (!frontier.empty()) {
        const auto [cost, cell] = frontier.top();
        frontier.pop();
        if (cost != distance[cell])
            continue;
        const Point tile{short(cell % Width), short(cell / Width)};
        for (const auto direction : Directions) {
            const auto next = add(tile, direction);
            if (inside(next) && canWalk(game.map().at(next.x * 2, next.y * 2)))
                offer(next, cost + 1);
        }
        for (const auto entry : entrances[cell])
            offer(entry, cost + 1);
    }
    return distance;
}

int walls(const Session& game) {
    return std::ranges::count(game.bombs().level().tiles, std::uint8_t{2});
}

int opponents(const Session& game, std::size_t player) {
    int count = 0;
    for (std::size_t other = 0; other < PlayerCount; ++other)
        count += rival(game, player, other);
    return count;
}

struct Candidate {
    Session game;
    unsigned first{};
    unsigned lived{};
    float score{};
};

void simulate(Candidate& candidate, std::size_t player, unsigned action, unsigned ticks) {
    Controls input{};
    const auto seat = candidate.game.players()[player].control;
    for (unsigned tick = 0; tick < ticks && liaPlaying(candidate.game); ++tick) {
        input[seat] = liaButtons(action, tick);
        candidate.game.tick(input, false);
        if (!liaAlive(candidate.game.players()[player]))
            return;
        ++candidate.lived;
    }
}

// Opponents can move after the decision. The stationary continuation is a
// useful check for a refuge, but a projected hit is only an opportunity.
float continuation(const Candidate& candidate, std::size_t player, int oldWalls, int oldOpponents) {
    Session future = candidate.game;
    unsigned survived = 0;
    while (survived < ForecastLimit && liaPlaying(future) && !future.bombs().settled()) {
        future.tick({}, false);
        if (!liaAlive(future.players()[player]))
            return -125.f + float(survived) / ForecastLimit;
        ++survived;
    }
    return 3.8f * std::max(0, oldWalls - walls(future)) +
           13.f * std::max(0, oldOpponents - opponents(future, player));
}
}

Buttons liaButtons(unsigned action, unsigned tick) {
    const auto move = action % 5;
    return {.left = move == 1, .right = move == 2, .up = move == 3, .down = move == 4,
            .fire = action >= 5 && tick == 0};
}

bool liaAlive(const Player& player) {
    return player.control >= 0 && player.activation != Activation::Hidden && !player.dead && !player.deathFrame;
}

bool liaPlaying(const Session& session) {
    const auto phase = session.phase();
    return phase == RoundPhase::AwaitingPlayers || phase == RoundPhase::Running || phase == RoundPhase::Draining;
}

void Lia::reset() { visits_.fill(0); }

unsigned Lia::choose(const Session& session, std::size_t self, const LiaModel* model) {
    const auto& player = session.players().at(self);
    const auto origin = tileOf(player);
    if (!liaAlive(player) || !inside(origin) || !liaPlaying(session))
        return 0;
    for (auto& visits : visits_)
        visits *= 0.97f;
    visits_[index(origin)] += 1.f;
    const auto distance = objectives(session, self);
    const auto oldWalls = walls(session);
    const auto oldOpponents = opponents(session, self);
    const auto prior = model ? model->logits(liaObservation(session, self)) : std::array<float, LiaActionCount>{};
    const auto evaluate = [&](Candidate& candidate) {
        const auto& result = candidate.game.players()[self];
        const auto tile = tileOf(result);
        if (!liaAlive(result) || !inside(tile)) {
            candidate.score = -1000.f + candidate.lived;
            return;
        }
        const auto bonus = result.bonusesTaken - player.bonusesTaken;
        const auto planted = result.bombsPlanted - player.bombsPlanted;
        candidate.score = 0.75f * (distance[index(origin)] - distance[index(tile)]) -
            0.7f * std::min(8.f, visits_[index(tile)]) +
            5.f * bonus + 2.f * (oldWalls - walls(candidate.game)) +
            22.f * (oldOpponents - opponents(candidate.game, self)) -
            0.35f * planted + 0.24f * std::clamp(prior[candidate.first], -4.f, 4.f);
        if (candidate.first < 5 && candidate.first != 0)
            candidate.score += 0.08f;
    };

    std::vector<Candidate> beam;
    for (unsigned action = 0; action < LiaActionCount; ++action) {
        Candidate initial{session, action};
        simulate(initial, self, action, LiaActionTicks);
        evaluate(initial);
        // An impossible bomb placement adds no alternative to its movement.
        if (action < 5 || initial.game.players()[self].bombsPlanted != player.bombsPlanted ||
            player.effects[0] || player.clock)
            beam.push_back(std::move(initial));
    }
    const auto better = [](const Candidate& a, const Candidate& b) { return a.score > b.score; };
    unsigned lastChance = std::ranges::max_element(beam, {}, &Candidate::score)->first;
    for (unsigned depth = 1; depth < SearchDepth; ++depth) {
        std::vector<Candidate> next;
        for (const auto& option : beam) {
            if (!liaAlive(option.game.players()[self]))
                continue;
            for (unsigned action = 0; action < 5; ++action) {
                auto extension = option;
                simulate(extension, self, action, LiaActionTicks);
                evaluate(extension);
                if (liaAlive(extension.game.players()[self]))
                    next.push_back(std::move(extension));
            }
        }
        if (next.empty())
            break;
        std::stable_sort(next.begin(), next.end(), better);
        beam.clear();
        std::vector<std::tuple<int, int, unsigned, unsigned>> seen;
        std::array<unsigned, LiaActionCount> retained{};
        for (auto& option : next) {
            if (retained[option.first] == PathsPerAction)
                continue;
            const auto& end = option.game.players()[self];
            const auto center = end.center();
            const auto key = std::tuple(int(center.x) / 4, int(center.y) / 4, option.first, end.bombsPlanted);
            if (std::ranges::find(seen, key) != seen.end())
                continue;
            seen.push_back(key);
            beam.push_back(std::move(option));
            ++retained[beam.back().first];
        }
        lastChance = beam.front().first;
    }
    float best = -std::numeric_limits<float>::infinity();
    for (const auto& candidate : beam) {
        if (!liaAlive(candidate.game.players()[self]))
            continue;
        const auto value = candidate.score + continuation(candidate, self, oldWalls, oldOpponents);
        if (value > best) {
            best = value;
            lastChance = candidate.first;
        }
    }
    return lastChance;
}

unsigned LiaGroup::read(const Session& session, Controls& input, unsigned requests, const LiaModel* model) {
    static_assert(static_cast<std::size_t>(Control::Lia6) - FirstLiaControl + 1 == PlayerCount);
    static_assert(PlayerCount <= LiaActionTicks);
    if (session.paused() || !liaPlaying(session))
        return 0;
    const auto tick = session.elapsed();
    if (round_ != session.roundNumber() || tick < lastTick_) {
        agents_ = {};
        round_ = session.roundNumber();
    }
    lastTick_ = tick;

    std::array<bool, PlayerCount> occupied{};
    const auto& players = session.players();
    unsigned seats = 0;
    for (std::size_t slot = 0; slot < players.size(); ++slot) {
        const auto& player = players[slot];
        seats += player.control < 0 && !player.dead;
        if (player.control < static_cast<int>(FirstLiaControl) ||
            player.control >= static_cast<int>(FirstLiaControl + PlayerCount))
            continue;
        const auto control = static_cast<std::size_t>(player.control);
        const auto index = control - FirstLiaControl;
        occupied[index] = true;

        if (player.activation == Activation::Hidden && !player.dead) {
            input[control].fire = true;
            continue;
        }
        if (!liaAlive(player))
            continue;
        auto& agent = agents_[index];
        // Replan at different VBL phases when several Lias are playing.
        if (tick % LiaActionTicks == index) {
            agent.action = agent.policy.choose(session, slot, model);
            agent.plannedAt = tick;
            agent.planned = true;
        }
        if (agent.planned)
            input[control] = liaButtons(agent.action, tick - agent.plannedAt);
    }

    unsigned joined = 0;
    for (std::size_t index = 0; index < occupied.size() && joined < std::min(requests, seats); ++index) {
        if (!occupied[index]) {
            input[FirstLiaControl + index].fire = true;
            ++joined;
        }
    }
    return joined;
}

std::array<float, LiaFeatures> liaObservation(const Session& session, std::size_t seat) {
    const auto& player = session.players().at(seat);
    const auto center = player.center();
    const auto tile = tileAt(center);
    std::array<float, LiaFeatures> result{};
    std::size_t offset = 0;
    const auto add = [&](float value) { result.at(offset++) = value; };
    for (const auto value : {center.x / float(Width * 16), center.y / float(Height * 16),
            player.speed / 8.f, player.bombCapacity / 8.f, player.flameEnergy / 16.f,
            player.fuse / 120.f, player.loops / 24.f, float(player.clock),
            float(player.push || player.canPush), session.remaining() / 15000.f})
        add(value);
    for (const auto effect : player.effects)
        add(std::clamp(effect / 500.f, 0.f, 2.f));
    Point nearest{};
    int best = Width + Height, enemies = 0;
    std::array<bool, Cells> occupied{};
    for (std::size_t other = 0; other < PlayerCount; ++other) {
        if (!rival(session, seat, other))
            continue;
        ++enemies;
        const auto target = tileOf(session.players()[other]);
        if (inside(target))
            occupied[index(target)] = true;
        const auto dx = target.x - tile.x, dy = target.y - tile.y;
        if (std::abs(dx) + std::abs(dy) < best) {
            best = std::abs(dx) + std::abs(dy);
            nearest = {short(dx), short(dy)};
        }
    }
    add(nearest.x / float(Width));
    add(nearest.y / float(Height));
    add(enemies / float(PlayerCount - 1));
    add(session.alert());
    add(player.teleportPhase != 0);
    for (int y = tile.y - 3; y <= tile.y + 3; ++y)
        for (int x = tile.x - 3; x <= tile.x + 3; ++x) {
            const Point local{short(x), short(y)};
            const bool valid = inside(local);
            const auto cell = valid ? session.map().at(2 * x, 2 * y) : PlayerCell{1};
            const auto raw = valid ? session.bombs().level().tiles[index(local)] : 1;
            const Bomb* bomb = nullptr;
            Point velocity{};
            bool flame = false;
            for (int dy = 0; valid && dy < 2; ++dy)
                for (int dx = 0; dx < 2; ++dx) {
                    flame |= session.bombs().flameMask(2 * x + dx, 2 * y + dy) != 0;
                    const auto id = session.map().at(2 * x + dx, 2 * y + dy).bomb;
                    if (id >= 0 && static_cast<std::size_t>(id) < session.bombs().bombs().size()) {
                        bomb = &session.bombs().bombs()[id];
                        velocity = session.map().bombVelocities[id];
                    }
                }
            add(raw / 88.f);
            add(cell.visible / 48.f);
            add(cell.slab / 16.f);
            add(flame);
            add(bomb ? (1 + std::max(0, bomb->time)) / 120.f : 0.f);
            add(bomb ? bomb->energy / 16.f : 0.f);
            add(velocity.x);
            add(velocity.y);
            add(bomb && bomb->frozen);
            add(bomb && bomb->held);
            add(bomb && bomb->owner == seat);
            add(cell.teleporter.x / float(Width * 2));
            add(cell.teleporter.y / float(Height * 2));
            add(valid && occupied[index(local)]);
        }
    return result;
}

LiaModel::LiaModel(const std::filesystem::path& path) {
    std::ifstream file(path);
    std::string magic;
    unsigned inputs{}, actions{};
    if (!(file >> magic >> inputs >> hidden_ >> actions) || magic != "LIA1" ||
        inputs != LiaFeatures || actions != LiaActionCount || hidden_ == 0 || hidden_ > 512)
        throw std::runtime_error("invalid Lia model header");
    const auto read = [&](std::vector<float>& values, std::size_t size) {
        values.resize(size);
        for (auto& value : values)
            if (!(file >> value) || !std::isfinite(value) || std::abs(value) > 100.f)
                throw std::runtime_error("invalid Lia model weights");
    };
    read(input_, hidden_ * LiaFeatures);
    read(bias_, hidden_);
    read(output_, LiaActionCount * hidden_);
    read(outputBias_, LiaActionCount);
    if (file >> magic)
        throw std::runtime_error("trailing data in Lia model");
}

std::array<float, LiaActionCount> LiaModel::logits(std::span<const float, LiaFeatures> observation) const {
    std::array<float, LiaActionCount> result{};
    std::ranges::copy(outputBias_, result.begin());
    for (unsigned unit = 0; unit < hidden_; ++unit) {
        float value = bias_[unit];
        for (unsigned feature = 0; feature < LiaFeatures; ++feature)
            value += input_[unit * LiaFeatures + feature] * observation[feature];
        const auto activation = std::tanh(value);
        for (unsigned action = 0; action < LiaActionCount; ++action)
            result[action] += output_[action * hidden_ + unit] * activation;
    }
    return result;
}
}

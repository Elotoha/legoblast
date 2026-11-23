#pragma once

#include "session.hpp"

namespace legoblast {

inline constexpr unsigned LiaActionCount = 10;
inline constexpr unsigned LiaActionTicks = 8;
inline constexpr auto FirstLiaControl = static_cast<std::size_t>(Control::Lia);
inline constexpr unsigned LiaFeatures = 24 + 7 * 7 * 14;

Buttons liaButtons(unsigned action, unsigned tick);
bool liaAlive(const Player& player);
bool liaPlaying(const Session& session);
std::array<float, LiaFeatures> liaObservation(const Session& session, std::size_t player);

class LiaModel {
public:
    explicit LiaModel(const std::filesystem::path& path);
    std::array<float, LiaActionCount> logits(std::span<const float, LiaFeatures> observation) const;

private:
    unsigned hidden_{};
    std::vector<float> input_, bias_, output_, outputBias_;
};

class Lia {
public:
    unsigned choose(const Session& session, std::size_t player, const LiaModel* model = nullptr);
    void reset();

private:
    std::array<float, Width * Height> visits_{};
};

// One independent tactical memory per summoned controller.
class LiaGroup {
public:
    unsigned read(const Session& session, Controls& input, unsigned requests, const LiaModel* model = nullptr);

private:
    struct Agent {
        Lia policy;
        unsigned action{};
        unsigned plannedAt{};
        bool planned{};
    };
    std::array<Agent, PlayerCount> agents_{};
    unsigned round_{}, lastTick_{};
};

}

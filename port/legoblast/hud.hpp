#pragma once

#include "session.hpp"

namespace legoblast {
class Hud {
public:
    static constexpr int Width = 640;
    static constexpr int Height = 18;

    explicit Hud(const std::filesystem::path& binary);
    Bytes render(const Session& session, bool independentSprites) const;
    const Bytes& wood() const { return wood_; }

private:
    std::array<Bytes, 4> bars_;
    Bytes portraits_, digits_, individualScores_, teamScores_, wood_;
};
}

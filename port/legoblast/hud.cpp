#include "hud.hpp"

#include <algorithm>
#include <stdexcept>

namespace legoblast {
namespace {
constexpr int Planes = 6;

Bytes decodePlanes(const Bytes& raw, int width, int height) {
    const int row = width / 8;
    if (raw.size() != static_cast<std::size_t>(height * row * Planes))
        throw std::runtime_error("invalid player bar size");
    Bytes result(width * height);
    for (int y = 0; y < height; ++y)
        for (int x = 0; x < width; ++x)
            for (int plane = 0; plane < Planes; ++plane) {
                const int source = (plane * height + y) * row + x / 8;
                result[y * width + x] |= ((raw[source] >> (7 - x % 8)) & 1) << plane;
            }
    return result;
}

// The portrait, timer and score banks interleave all six planes on each row.
void copyImage(Bytes& bar, const Bytes& bank, unsigned frame, int width, int height, int x, int y) {
    const int row = width / 8;
    const auto base = std::size_t(frame) * height * row * Planes;
    if (base + height * row * Planes > bank.size())
        throw std::runtime_error("invalid player bar frame");
    for (int py = 0; py < height; ++py)
        for (int px = 0; px < width; ++px) {
            unsigned color = 0;
            for (int plane = 0; plane < Planes; ++plane) {
                const auto source = base + (py * Planes + plane) * row + px / 8;
                color |= ((bank[source] >> (7 - px % 8)) & 1) << plane;
            }
            bar[(y + py) * Hud::Width + x + px] = static_cast<std::uint8_t>(color);
        }
}
}

Hud::Hud(const std::filesystem::path& binary)
    : portraits_(readBytes(binary / "bigbloc.dat")), digits_(readBytes(binary / "timer1.dat")),
      individualScores_(readBytes(binary / "Jauge.Dat")), teamScores_(readBytes(binary / "JaugeTeams.Dat")),
      wood_(decodePlanes(readBytes(binary / "bois.raw"), Width / 2, Height)) {
    constexpr std::array<const char*, 4> files{"barreJI4.raw", "barreJI6.raw", "barreJT4.raw", "barreJT6.raw"};
    for (std::size_t i = 0; i < files.size(); ++i)
        bars_[i] = decodePlanes(readBytes(binary / files[i]), Width, Height);
}

Bytes Hud::render(const Session& session, bool independentSprites) const {
    const unsigned mode = (session.isTeamMatch() ? 2 : 0) + independentSprites;
    auto bar = bars_[mode];
    constexpr std::array timerX{192, 4, 368, 292};
    const auto seconds = session.remaining() / 50;
    copyImage(bar, digits_, 1 + seconds / 60 % 10, 16, 12, timerX[mode], 2);
    copyImage(bar, digits_, 1 + seconds / 10 % 6, 16, 12, timerX[mode] + 24, 2);
    copyImage(bar, digits_, 1 + seconds % 10, 16, 12, timerX[mode] + 40, 2);

    constexpr std::array<std::array<int, 6>, 4> portraitX{{
        {264, 360, 456, 552}, {72, 168, 264, 360, 456, 552},
        {8, 456, 104, 552}, {8, 384, 96, 472, 184, 560},
    }};
    constexpr std::array portraitBase{84, 87, 90, 93, 96, 99};
    constexpr std::array bonuses{16, 6, 0, 5, 12, 13, 17, 3, 1, 18, 8, 9,
                                 19, 20, 21, 4, 7, 22, 25, 26, 28, 29, 11, 21};
    for (std::size_t i = 0; i < (independentSprites ? PlayerCount : 4); ++i) {
        const auto& player = session.players()[i];
        const bool hidden = player.activation == Activation::Hidden;
        const auto portrait = portraitBase[i] + (player.dead ? 2 : hidden ? 1 : 0) +
            (independentSprites && i < 3 ? 18 : 0);
        const auto x = portraitX[mode][i];
        const int icon = session.winners()[i] ? 24 :
            player.dead ? (hidden && session.retrying() ? 30 : 15) :
            hidden ? 14 : bonuses.at(player.lastBonus);
        copyImage(bar, portraits_, portrait, 32, 16, x, 1);
        copyImage(bar, portraits_, icon, 32, 16, x + (mode == 3 ? 40 : 48), 1);
        if (session.fiveWinMatch() && !session.isTeamMatch())
            copyImage(bar, individualScores_, std::min(session.score()[i], 5u), 8, Height, x - 8, 0);
    }
    if (session.fiveWinMatch() && session.isTeamMatch()) {
        const auto first = independentSprites ? 264 : 192;
        const auto second = independentSprites ? 360 : 432;
        copyImage(bar, teamScores_, std::min(session.score()[0], 5u), 16, Height, first, 0);
        copyImage(bar, teamScores_, std::min(session.score()[1], 5u), 16, Height, second, 0);
    }
    return bar;
}
}

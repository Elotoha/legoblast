#pragma once

#include "hud.hpp"
#include "screens.hpp"
#include "sprite.hpp"

namespace legoblast {

inline constexpr int BoardWidth = Width * TileSize;
inline constexpr int BoardHeight = Height * TileSize;
inline constexpr int ScreenWidth = Hud::Width / 2;
inline constexpr int ScreenHeight = BoardHeight + Hud::Height;
inline constexpr int BoardX = (ScreenWidth - BoardWidth) / 2;
inline constexpr std::size_t ScreenBytes = ScreenWidth * ScreenHeight * 3;

struct DrawnPlayer {
    Point topLeft;
    Bytes image;
};

class MatchArt {
public:
    MatchArt(const std::filesystem::path& root, const std::filesystem::path& sprites);
    Bytes board(const Session& session);
    Bytes bar(const Session& session, bool wood) const;
    Bytes podium(const Session& session) const { return podium_.render(session); }
    std::vector<DrawnPlayer> players(const Session& session) const;
    Bytes frame(const Session& session, bool wood);
private:
    static bool independent(const Session& session);

    std::filesystem::path root_;
    Bytes bank_, boardPalette_, flames_, terrain_;
    std::array<std::uint8_t, Width * Height> displayedTiles_{};
    std::array<std::uint16_t, 30> displayedBlocks_{};
    unsigned lastPalette_{~0u}, lastFlamePalette_{~0u};
    std::size_t lastArena_{~std::size_t{}};
    Bytes attached_, attachedIndex_, attachedColors_;
    Bytes independent_, independentIndex_, independentColors_;
    Hud hud_;
    PodiumArt podium_;
    ReadyPanel ready_;
};

void copyMatchBoard(Bytes& destination, const Bytes& board, const Bytes& bar);
void blendMatchPlayer(Bytes& destination, const DrawnPlayer& sprite);
}

#include "match_art.hpp"

#include <utility>

namespace legoblast {

MatchArt::MatchArt(const std::filesystem::path& root, const std::filesystem::path& sprites)
    : root_(root), bank_(readBytes(root / "binary/Lego_Blocs.dat")),
      attached_(readBytes(sprites)), attachedIndex_(readBytes(root / "binary/Lego_SpritesIndex.dat")),
      attachedColors_(readBytes(root / "binary/Lego_Sprites.col")),
      independent_(readBytes(root / "binary/Lego_Sprites8.dat")),
      independentIndex_(readBytes(root / "binary/Lego_SpritesIndex8.dat")),
      independentColors_(readBytes(root / "binary/Mec8_normal.col")),
      hud_(sprites.parent_path()), podium_(sprites.parent_path()), ready_(sprites.parent_path()) {}

Bytes MatchArt::board(const Session& session) {
    constexpr std::array flameFiles{"Lego_Flam_bib.Dat", "Lego_Flam_Manu.Dat", "Lego_Flam_lazer.Dat"};
    const auto& level = session.arena();
    const auto& bombs = session.bombs();
    const auto& map = session.map();
    if (lastPalette_ != level.palette) {
        boardPalette_ = readLevelPalette(root_, level.palette);
        lastPalette_ = level.palette;
    }
    if (lastFlamePalette_ != level.flamePalette) {
        flames_ = readBytes(root_ / "binary" / flameFiles.at(level.flamePalette));
        lastFlamePalette_ = level.flamePalette;
    }
    if (lastArena_ != session.arenaIndex() || displayedTiles_ != bombs.level().tiles || displayedBlocks_ != level.blocks) {
        lastArena_ = session.arenaIndex();
        displayedTiles_ = bombs.level().tiles;
        displayedBlocks_ = level.blocks;
        terrain_ = staticLevelIndices(bombs.level(), bank_);
    }
    auto frame = terrain_;
    for (const auto& bumper : session.bumpers())
        if (bumper.state >= 0 && map.at(bumper.cell.x, bumper.cell.y).visible == 27)
            drawLevelBlock(frame, bumper.cell, bumper.frame + bumper.imageOffset, level.blocks[0], bank_);
    for (const auto& closing : session.closingFrames())
        drawLevelPattern(frame, closing.tile.x * 16, closing.tile.y * 16, 16, closing.image, bank_);
    for (const auto& block : bombs.brokenBlocks())
        drawLevelPattern(frame, block.cell.x * 8, block.cell.y * 8, 16, block.frame, bank_);
    for (int y = 0; y < Height * 2; ++y)
        for (int x = 0; x < Width * 2; ++x)
            if (const auto mask = bombs.flameMask(x, y); mask && !map.at(x, y).visible)
                drawLevelPattern(frame, x * 8, y * 8, 8, mask, flames_);
    for (const auto& bomb : bombs.bombs())
        if (bomb.active)
            drawLevelPattern(frame, bomb.cell.x * 8, bomb.cell.y * 8, 16, bomb.image(), bank_);
    return session.showReady() ? ready_.render(std::move(frame), level, bank_, boardPalette_) :
        levelRgb(frame, boardPalette_);
}

bool MatchArt::independent(const Session& session) {
    return std::ranges::count_if(session.players(), [](const Player& player) { return player.control >= 0; }) > 4;
}

Bytes MatchArt::bar(const Session& session, bool wood) const {
    if (wood) return levelRgb(hud_.wood(), boardPalette_);
    return levelRgb(hud_.render(session, independent(session)), boardPalette_);
}

std::vector<DrawnPlayer> MatchArt::players(const Session& session) const {
    std::vector<const Player*> visible;
    if (!session.paused())
        for (const auto& player : session.players())
            if (player.visible) visible.push_back(&player);
    std::stable_sort(visible.begin(), visible.end(), [](const Player* a, const Player* b) {
        return a->sprite.y < b->sprite.y;
    });
    bool split = independent(session);
    std::vector<DrawnPlayer> drawn;
    for (const auto* player : visible) {
        const auto slot = static_cast<unsigned>(player - session.players().data());
        const auto frame = player->frame + player->imageOffset;
        const auto center = player->center();
        drawn.push_back({{short(BoardX + center.x - 7), short(center.y - 20)},
            split ? independentSprite(independent_, independentIndex_, independentColors_, slot, frame) :
                attachedSprite(attached_, attachedIndex_, attachedColors_, player->frameBase + frame)});
    }
    return drawn;
}

void copyMatchBoard(Bytes& destination, const Bytes& board, const Bytes& bar) {
    destination.resize(ScreenBytes);
    for (int y = 0; y < BoardHeight; ++y) {
        auto* row = destination.data() + y * ScreenWidth * 3;
        for (int x = 0; x < ScreenWidth; ++x) {
            row[x * 3] = 14;
            row[x * 3 + 1] = 19;
            row[x * 3 + 2] = 29;
        }
        std::copy_n(board.data() + y * BoardWidth * 3, BoardWidth * 3, row + BoardX * 3);
    }
    const auto sourceWidth = bar.size() / (Hud::Height * 3);
    for (int y = 0; y < Hud::Height; ++y)
        for (int x = 0; x < ScreenWidth; ++x)
            std::copy_n(bar.data() + (y * sourceWidth + x * sourceWidth / ScreenWidth) * 3, 3,
                destination.data() + ((BoardHeight + y) * ScreenWidth + x) * 3);
}

void blendMatchPlayer(Bytes& destination, const DrawnPlayer& sprite) {
    for (int sy = 0; sy < SpriteHeight; ++sy)
        for (int sx = 0; sx < SpriteWidth; ++sx) {
            const auto x = sprite.topLeft.x + sx, y = sprite.topLeft.y + sy;
            const auto pixel = (sy * SpriteWidth + sx) * 4;
            if (x >= 0 && x < ScreenWidth && y >= 0 && y < ScreenHeight && sprite.image[pixel + 3])
                std::copy_n(sprite.image.data() + pixel, 3, destination.data() + (y * ScreenWidth + x) * 3);
        }
}

Bytes MatchArt::frame(const Session& session, bool wood) {
    if (session.phase() == RoundPhase::Podium || session.phase() == RoundPhase::Statistics) {
        auto image = podium(session);
        image.resize(ScreenBytes);
        return image;
    }
    const auto terrain = board(session);
    Bytes image;
    copyMatchBoard(image, terrain, bar(session, wood));
    for (const auto& player : players(session))
        blendMatchPlayer(image, player);
    return image;
}
}

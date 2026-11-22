#pragma once

#include "preferences.hpp"

#include <string_view>

namespace legoblast {
class ScreenArt {
public:
    static constexpr int Width = 320, Height = 256;

    ScreenArt(const std::filesystem::path& image, const std::filesystem::path& palette,
              int width = Width, int height = Height, bool compressed = false);
    const Bytes& indices() const { return indices_; }
    Bytes rgb(std::span<const std::uint8_t> image, unsigned brightness = 100, unsigned grey = 0,
              unsigned cycle = 0, unsigned white = 0) const;
    void applyMenuGradient(unsigned variant);

private:
    Bytes indices_, palette_;
};

class ExtraScreens {
public:
    ExtraScreens(const std::filesystem::path& binary, unsigned gradient);
    Bytes intro(unsigned tick) const;
    Bytes slideshow(unsigned page, unsigned tick) const;

private:
    ScreenArt intro_, credits_, bonuses_;
};

class PodiumArt {
public:
    explicit PodiumArt(const std::filesystem::path& binary);
    std::vector<unsigned> ranking(const Session& session) const;
    Bytes render(const Session& session) const;

private:
    void drawPlayer(Bytes& image, int x, int y, unsigned animation, unsigned frame, unsigned player) const;
    void drawStatistics(Bytes& image, const Session& session) const;
    ScreenArt backdrop_;
    Bytes feelings_, heads_, textFont_;
};

class ReadyPanel {
public:
    explicit ReadyPanel(const std::filesystem::path& binary);
    Bytes render(Bytes board, const Level& level, const Bytes& blocks, const Bytes& palette) const;

private:
    Bytes titleFont_, textFont_;
};

struct ArenaEntry {
    std::filesystem::path file;
    Level level;
    unsigned number;
    bool enabled{true};
};
std::vector<ArenaEntry> loadArenaList(const std::filesystem::path& binary);

enum class MenuInput { Up, Down, Left, Right, Fire, Back };
enum class MenuResult { Continue, Start, Exit };

class Menus {
public:
    Menus(const std::filesystem::path& binary, std::vector<ArenaEntry>& arenas, const Preferences& prefs = {});
    MenuResult handle(MenuInput input);
    Bytes render(unsigned tick) const;
    const auto& options() const { return options_; }
    const auto& levelFile() const { return arenas_[arena_].file; }
    bool sharedKeyboard() const { return control_ >= 5; }
    bool mainPage() const { return page_ == 0; }
    void saveOptions(Preferences& prefs) const;

private:
    void drawSelection(Bytes& picture, unsigned bob, unsigned offset) const;
    void print(Bytes& picture, int x, int y, std::string_view phrase, unsigned color = 31) const;

    ScreenArt main_, optionsArt_;
    Bytes boxes_, font_;
    std::vector<ArenaEntry>& arenas_;
    MatchOptions options_{};
    int page_{}, row_{}, section_{2}, field_{-1}, control_{4}, definition_{};
    std::size_t arena_{};
};
}

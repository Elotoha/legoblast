#include "screens.hpp"

#include <algorithm>
#include <stdexcept>
#include <tuple>

namespace legoblast {
namespace {
unsigned bigEndian(const Bytes& bytes, std::size_t offset, unsigned length) {
    unsigned result = 0;
    for (unsigned i = 0; i < length; ++i)
        result = (result << 8) | bytes.at(offset + i);
    return result;
}

void printBitmap(Bytes& picture, int stride, const Bytes& font, int x, int y,
                 std::string_view phrase, unsigned color) {
    for (unsigned char letter : phrase) {
        const auto offset = bigEndian(font, letter * 4, 4);
        const auto width = static_cast<int>(bigEndian(font, offset, 2));
        const auto height = static_cast<int>(bigEndian(font, offset + 2, 2));
        for (int row = 0; row < height; ++row) {
            const auto bits = bigEndian(font, offset + 4 + row * 4, 4);
            for (int col = 0; col < width && col < 24 && x + col < stride; ++col)
                if (bits & (0x80000000u >> col))
                    picture.at((y + row) * stride + x + col) = static_cast<std::uint8_t>(color);
        }
        x += width;
    }
}

std::string timeLabel(unsigned ticks) {
    const auto seconds = ticks / 50;
    if (seconds < 60)
        return std::to_string(seconds) + " Seconds.";
    return std::to_string(seconds / 60) + ":" +
        std::to_string(100 + seconds % 60).substr(1);
}

// decrunch.i: each unary code selects a run of zeroes or ones in BitList.
Bytes unpackProxima(const Bytes& packed, std::size_t size) {
    constexpr std::array lengths{1, 3, 1, 5, 2, 32, 256, 256, 4096, 4096};
    constexpr std::array ones{false, true, true, true, true, false, true, false, true, false};
    Bytes result(size);
    std::size_t destination = 0, code = 0;
    for (const auto byte : packed)
        for (unsigned mask = 128; mask; mask >>= 1) {
            if (destination == size * 8)
                return result;
            if (byte & mask) {
                ++code;
                continue;
            }
            if (code >= lengths.size())
                throw std::runtime_error("invalid Proxima run");
            const auto count = std::min<std::size_t>(lengths[code], size * 8 - destination);
            if (ones[code])
                for (std::size_t i = 0; i < count; ++i) {
                    const auto pixel = destination + i;
                    result[pixel / 8] |= 128 >> (pixel % 8);
                }
            destination += count;
            code = 0;
        }
    if (destination != size * 8)
        throw std::runtime_error("truncated Proxima screen");
    return result;
}
}

ScreenArt::ScreenArt(const std::filesystem::path& image, const std::filesystem::path& palette,
                     int width, int height, bool compressed)
    : indices_(width * height), palette_(readBytes(palette)) {
    const int planes = compressed ? 8 : 7;
    const int planeSize = width * height / 8;
    auto raw = readBytes(image);
    if (compressed)
        raw = unpackProxima(raw, planes * planeSize);
    if (raw.size() != static_cast<std::size_t>(planes * planeSize) ||
        palette_.size() != static_cast<std::size_t>((1u << planes) * 4))
        throw std::runtime_error("invalid planar screen or palette");
    for (std::size_t pixel = 0; pixel < indices_.size(); ++pixel)
        for (int plane = 0; plane < planes; ++plane)
            indices_[pixel] |= ((raw[plane * planeSize + pixel / 8] >> (7 - pixel % 8)) & 1) << plane;
}

Bytes ScreenArt::rgb(std::span<const std::uint8_t> image, unsigned brightness, unsigned grey,
                     unsigned cycle, unsigned white) const {
    Bytes rgb(image.size() * 3);
    for (std::size_t pixel = 0; pixel < image.size(); ++pixel) {
        auto index = static_cast<unsigned>(image[pixel]);
        if (index >= 96 && index < 112)
            index = 96 + (index - 96 + cycle) % 16;
        const auto* color = palette_.data() + index * 4 + 1;
        const unsigned average = (color[0] + color[1] + color[2]) / 3;
        const auto fade = index < 96 ? grey : 0;
        for (std::size_t channel = 0; channel < 3; ++channel) {
            const auto shade = (average * fade + color[channel] * (100 - fade)) / 100;
            rgb[pixel * 3 + channel] = (shade * brightness * (100 - white) / 100 + 255 * white) / 100;
        }
    }
    return rgb;
}

void ScreenArt::applyMenuGradient(unsigned variant) {
    constexpr std::array<std::array<int, 6>, 6> gradients{{
        {21,0,99,62,0,255}, {49,0,29,255,0,43}, {52,13,76,133,93,156},
        {0,25,56,79,105,134}, {0,46,0,0,137,0}, {84,0,59,171,5,209},
    }};
    const auto& values = gradients.at(variant);
    for (unsigned channel = 0; channel < 3; ++channel) {
        const auto start = values[channel];
        palette_[1 + channel] = start;
        const auto advance = (values[channel + 3] - start) * 65536 / 31;
        for (int i = 0; i < 32; ++i)
            palette_[(32 + i) * 4 + 1 + channel] = start + (advance * i >> 16);
    }
}

ExtraScreens::ExtraScreens(const std::filesystem::path& binary, unsigned gradient)
    : intro_(binary / "proxima.crp", binary / "Proxima.col", 640, ScreenArt::Height, true),
      credits_(binary / "MENU_CREDITS.RAW", binary / "MENU_Credits.col"),
      bonuses_(binary / "MENU_Bonus2.raw", binary / "MENU_Bonus.col", ScreenArt::Width, 377) {
    credits_.applyMenuGradient(gradient);
    bonuses_.applyMenuGradient(gradient);
}

Bytes ExtraScreens::intro(unsigned tick) const {
    return intro_.rgb(intro_.indices(), std::min(tick, 250u) * 100 / 250, 0, 0,
                      tick > 250 ? std::min(tick - 250, 40u) * 100 / 40 : 0);
}

Bytes ExtraScreens::slideshow(unsigned page, unsigned tick) const {
    const auto brightness = std::min(tick * 2, 100u);
    if (page == 1)
        return credits_.rgb(credits_.indices(), brightness);
    const auto scroll = tick % 634;
    constexpr int bottom = 377 - ScreenArt::Height;
    int row = bottom;
    if (scroll >= 50 && scroll < 292)
        row = bottom - (scroll - 50) / 2;
    else if (scroll >= 292)
        row = scroll < 392 ? 0 : (scroll - 392) / 2;
    const auto frame = std::span(bonuses_.indices()).subspan(row * ScreenArt::Width,
                                                            ScreenArt::Width * ScreenArt::Height);
    return bonuses_.rgb(frame, brightness);
}

PodiumArt::PodiumArt(const std::filesystem::path& binary)
    : backdrop_(binary / "PODIUM.RAW", binary / "Podium.col"),
      feelings_(readBytes(binary / "lego_feelings.dat")),
      heads_(readBytes(binary / "statsblocs.dat")),
      textFont_(readBytes(binary / "tinytxt8.font")) {
    if (feelings_.size() != 24 * 160 * 8 || heads_.size() != 3 * 122 * 8)
        throw std::runtime_error("invalid Lego_Feelings bank");
}

std::vector<unsigned> PodiumArt::ranking(const Session& session) const {
    std::vector<unsigned> players;
    for (unsigned i = 0; i < PlayerCount; ++i)
        if (session.players()[i].completedRounds)
            players.push_back(i);
    if (session.isTeamMatch()) {
        std::stable_sort(players.begin(), players.end(), [](unsigned a, unsigned b) {
            return a % 2 < b % 2;
        });
    } else {
        const auto statistics = [&](unsigned i) {
            const auto& player = session.players()[i];
            return std::tuple(player.victories, player.completedRounds, player.bombsPlanted, player.bonusesTaken);
        };
        std::stable_sort(players.begin(), players.end(), [&](unsigned a, unsigned b) {
            return statistics(a) > statistics(b);
        });
    }
    return players;
}

void PodiumArt::drawPlayer(Bytes& image, int x, int y, unsigned animation, unsigned frame, unsigned player) const {
    constexpr int planeSize = 24 * 160;
    constexpr std::array uniforms{21, 24, 27, 38, 56, 44};
    const auto base = frame * 23 * 24 + animation * 3;
    for (int py = 0; py < 22; ++py)
        for (int px = 0; px < 24; ++px) {
            const auto offset = base + py * 24 + px / 8;
            const auto bit = 0x80 >> (px % 8);
            unsigned color = 0;
            for (unsigned plane = 0; plane < 7; ++plane)
                if (feelings_[offset + (plane + 1) * planeSize] & bit)
                    color |= 1 << plane;
            for (auto uniform : uniforms)
                if (color >= static_cast<unsigned>(uniform) && color <= static_cast<unsigned>(uniform + 2)) {
                    color += uniforms[player] - uniform;
                    break;
                }
            const auto target = (y + py) * ScreenArt::Width + x + px;
            if (feelings_[offset] & bit)
                color |= image[target];
            image[target] = static_cast<std::uint8_t>(color);
        }
}

Bytes PodiumArt::render(const Session& session) const {
    auto image = backdrop_.indices();
    std::array<std::vector<unsigned>, 3> groups;
    unsigned step = 0;
    for (auto slot : ranking(session)) {
        if (session.isTeamMatch()) {
            groups[session.score()[slot % 2] > session.score()[(slot + 1) % 2] ? 0 : 2].push_back(slot);
        } else {
            if (step < 2 && !groups[step].empty() &&
                (groups[step].size() == 4 || session.score()[groups[step].back()] != session.score()[slot]))
                ++step;
            groups[step].push_back(slot);
        }
    }
    constexpr std::array left{144, 24, 208}, top{133, 148, 163}, width{64, 96, 96}, animation{2, 1, 3};
    constexpr std::array start{0u, 5u, 11u};
    const bool grey = session.phase() == RoundPhase::Statistics;
    for (unsigned i = 0; i < groups.size(); ++i) {
        const int count = static_cast<int>(groups[i].size());
        const int gap = (width[i] - count * 19) / (count + 1);
        const unsigned sequence = (start[i] + session.podiumTime() / 3) % 14;
        const auto frame = grey ? 0 : sequence < 7 ? sequence : 13 - sequence;
        for (int j = 0; j < count; ++j)
            drawPlayer(image, left[i] + gap + j * (19 + gap), top[i], animation[i], frame, groups[i][j]);
    }
    if (grey)
        drawStatistics(image, session);
    return backdrop_.rgb(image, std::min(session.podiumTime(), 100u), grey ? 100 : session.podiumGrey());
}

void PodiumArt::drawStatistics(Bytes& image, const Session& session) const {
    const auto rectangle = [&](int x, int y, int width, int height, unsigned color) {
        for (int row = y; row < y + height; ++row)
            std::fill_n(image.begin() + row * ScreenArt::Width + x, width, color);
    };
    for (int offset : {0, 250}) {
        rectangle(0, offset, 320, 6, 103);
        rectangle(offset ? 314 : 0, 0, 6, 256, 103);
    }
    const auto text = [&](int x, int y, std::string_view value) {
        printBitmap(image, ScreenArt::Width, textFont_, x + 1, y + 2, value, 102);
        printBitmap(image, ScreenArt::Width, textFont_, x, y + 1, value, 103);
    };
    constexpr std::array columns{52, 86, 153, 196, 248};
    constexpr std::array headings{"WINS", "GAMES", "DEADS", "BOMBS", "BONUS"};
    for (std::size_t i = 0; i < columns.size(); ++i)
        text(columns[i], 104, headings[i]);

    unsigned games = 1, bombs = 1, bonuses = 1;
    for (const auto& player : session.players()) {
        games = std::max(games, player.completedRounds);
        bombs = std::max(bombs, player.bombsPlanted);
        bonuses = std::max(bonuses, player.bonusesTaken);
    }
    int y = 117;
    for (auto slot : ranking(session)) {
        const auto& player = session.players()[slot];
        for (int dy = 0; dy < 15; ++dy)
            for (int x = 0; x < 24; ++x) {
                const auto byte = 3 * (slot * 16 + dy) + x / 8;
                const auto bit = 128 >> (x % 8);
                if (!(heads_[byte] & bit))
                    continue;
                unsigned color = 0;
                for (unsigned plane = 0; plane < 7; ++plane)
                    if (heads_[(plane + 1) * 3 * 122 + byte] & bit)
                        color |= 1 << plane;
                image[(y - 2 + dy) * ScreenArt::Width + 32 + x] = static_cast<std::uint8_t>(color);
            }
        const int played = 60 * player.completedRounds / games;
        const int wins = 60 * player.victories / games;
        const int losses = 60 * player.deaths / games;
        rectangle(88, y + 1, played + 1, 9, 102);
        rectangle(87, y, played + 1, 9, 98);
        if (losses) {
            rectangle(87 + played - losses, y, losses + 1, 9, 99);
            rectangle(87 + played - losses, y, 1, 9, 100);
            rectangle(87 + played, y, 1, 9, 100);
        }
        if (wins) {
            rectangle(87, y, wins + 1, 9, 110);
            rectangle(87, y, 1, 9, 108);
            rectangle(87 + wins, y, 1, 9, 108);
        }
        text(56, y, std::to_string(player.victories));
        text(89, y, std::to_string(player.completedRounds));
        text(159, y, std::to_string(player.deaths));
        for (const auto& [x, value, maximum] : {std::tuple{191, player.bombsPlanted, bombs},
                                               std::tuple{243, player.bonusesTaken, bonuses}}) {
            rectangle(x + 1, y + 1, 46, 9, 102);
            rectangle(x, y, 46, 9, 101);
            if (value) {
                const int width = 45 * value / maximum;
                rectangle(x, y, width + 1, 9, 99);
                rectangle(x + width, y, 1, 9, 100);
                text(x + 2, y, std::to_string(value));
            }
        }
        y += 16;
    }
}

ReadyPanel::ReadyPanel(const std::filesystem::path& binary)
    : titleFont_(readBytes(binary / "aachen13.font")),
      textFont_(readBytes(binary / "tinytxt8.font")) {}

Bytes ReadyPanel::render(Bytes board, const Level& level, const Bytes& blocks, const Bytes& palette) const {
    constexpr int stride = Width * TileSize;
    constexpr int boardX = (ScreenArt::Width - stride) / 2;
    constexpr int left = 60 - boardX, right = 260 - boardX, top = 70, bottom = 180;
    const auto original = board;
    std::fill_n(board.begin() + (top - 1) * stride + left - 1, right - left + 3, 15);
    std::fill_n(board.begin() + (bottom + 1) * stride + left - 1, right - left + 3, 15);
    for (int y = top; y <= bottom; ++y) {
        board[y * stride + left - 1] = 15;
        board[y * stride + right + 1] = 15;
    }
    const auto label = [&](const Bytes& font, int x, int y, std::string_view text) {
        printBitmap(board, stride, font, x - boardX + 2, y + 2, text, 15);
        printBitmap(board, stride, font, x - boardX, y, text, 30);
    };
    label(titleFont_, 130, 82, "READY ?!");
    std::string name = "Level ";
    const auto world = level.number / 100;
    constexpr std::array worlds{"Normal", "Alien", "Antic", "Tronic", "Wood", "Teams"};
    if (level.number && world < worlds.size()) {
        label(textFont_, 66, 111, std::string(worlds[world]) + " World");
        name += std::to_string(100 + level.number % 100).substr(1) + ": ";
    }
    label(textFont_, 66, 123, name + level.name);
    if (level.warningTime < level.totalTime)
        label(textFont_, 66, 143, "ALERT TIME  " + timeLabel(level.warningTime));
    label(textFont_, 66, 155, "TOTAL TIME  " + timeLabel(level.totalTime));
    for (int i = 0; i < 3; ++i)
        drawLevelPattern(board, 200 - boardX, 120 + i * 16, 16, 22 + i, blocks);
    label(textFont_, 228, 126, std::to_string(level.reach ? (level.reach - 1) / 2 : 0));
    label(textFont_, 228, 142, std::to_string(level.bombs));
    label(textFont_, 228, 158, level.push ? "Yes" : "No");

    // RestoreWorkingScreenEHB clears the seventh plane wherever the drawing
    // changed the background, leaving the unmodified arena in half-bright.
    auto rgb = levelRgb(board, palette);
    for (int y = top; y <= bottom; ++y)
        for (int x = left; x <= right; ++x) {
            const auto pixel = y * stride + x;
            if (board[pixel] == original[pixel])
                for (int c = 0; c < 3; ++c)
                    rgb[3 * pixel + c] /= 2;
        }
    return rgb;
}

std::vector<ArenaEntry> loadArenaList(const std::filesystem::path& binary) {
    std::vector<ArenaEntry> arenas;
    for (unsigned world = 0; world < 6; ++world)
        for (unsigned index = 1; index <= 30; ++index) {
            const auto number = 100 * world + index;
            const auto code = std::to_string(1000 + number).substr(1);
            const auto file = binary / ("Lego_Level" + code + ".dat");
            if (std::filesystem::is_regular_file(file))
                arenas.push_back({file, loadLevel(file), number});
        }
    return arenas;
}

Menus::Menus(const std::filesystem::path& binary, std::vector<ArenaEntry>& arenas, const Preferences& prefs)
    : main_(binary / "MENUA.raw", binary / "MENUA.col"), optionsArt_(binary / "MENUB.raw", binary / "MENUB.col"),
      boxes_(readBytes(binary / "mainmenubox.dat")), font_(readBytes(binary / "tinytxt8.font")), arenas_(arenas),
      options_(prefs.match), control_(prefs.controls), definition_(prefs.definition) {
    if (arenas_.empty())
        throw std::runtime_error("no arenas available");
    main_.applyMenuGradient(prefs.gradient);
    optionsArt_.applyMenuGradient(prefs.gradient);
    for (std::size_t i = 0; i < arenas_.size(); ++i) {
        if (arenas_[i].number == prefs.arena)
            arena_ = i;
        arenas_[i].enabled = !prefs.disabled.at(preferenceArenaSlot(arenas_[i].number));
    }
}

void Menus::saveOptions(Preferences& prefs) const {
    prefs.match = options_;
    prefs.arena = arenas_[arena_].number;
    prefs.controls = control_;
    prefs.definition = definition_;
    for (const auto& entry : arenas_)
        prefs.disabled.at(preferenceArenaSlot(entry.number)) = !entry.enabled;
}

MenuResult Menus::handle(MenuInput input) {
    const auto vertical = int(input == MenuInput::Down) - int(input == MenuInput::Up);
    const auto horizontal = int(input == MenuInput::Right) - int(input == MenuInput::Left);
    if (!page_) {
        row_ = std::clamp(row_ + vertical, 0, 2);
        if (input == MenuInput::Back || (input == MenuInput::Fire && row_ == 2))
            return MenuResult::Exit;
        if (input == MenuInput::Fire && row_ == 0)
            return MenuResult::Start;
        if (input == MenuInput::Fire && row_ == 1)
            page_ = 1;
        return MenuResult::Continue;
    }
    if (field_ < 0) {
        if (vertical > 0)
            section_ = 2;
        if (vertical < 0 && section_ == 2)
            section_ = 1;
        if (section_ < 2)
            section_ = std::clamp(section_ + horizontal, 0, 1);
        if (input == MenuInput::Back || (input == MenuInput::Fire && section_ == 2))
            page_ = 0;
        else if (input == MenuInput::Fire)
            field_ = 0;
        return MenuResult::Continue;
    }

    field_ += vertical;
    if (field_ > 2 || input == MenuInput::Back) {
        field_ = -1;
        if (vertical > 0)
            section_ = 2;
    } else if (section_ == 0) {
        if (field_ == 0 && horizontal) {
            constexpr std::array order{ArenaMode::Random, ArenaMode::Sequential, ArenaMode::Fixed, ArenaMode::Dynablaster};
            const auto current = std::ranges::find(order, options_.arena) - order.begin();
            options_.arena = order[std::clamp(static_cast<int>(current) + horizontal, 0, 3)];
        } else if (field_ == 1) {
            arena_ = std::clamp(static_cast<int>(arena_) + horizontal, 0, static_cast<int>(arenas_.size()) - 1);
            if (input == MenuInput::Fire)
                arenas_[arena_].enabled = !arenas_[arena_].enabled;
        } else if (field_ == 2 && horizontal) {
            options_.fiveWins = horizontal > 0;
        }
    } else if (horizontal) {
        if (field_ == 0) {
            const auto layout = std::clamp((options_.teams ? 1 : options_.survivor ? 2 : 0) + horizontal, 0, 2);
            options_.teams = layout == 1;
            options_.survivor = layout == 2;
        } else if (field_ == 1) {
            control_ = std::clamp(control_ + horizontal, 0, 6);
        } else if (field_ == 2) {
            definition_ = std::clamp(definition_ + horizontal, 0, 2);
        }
    }
    return MenuResult::Continue;
}

void Menus::drawSelection(Bytes& picture, unsigned bob, unsigned offset) const {
    auto source = bigEndian(boxes_, bob * 4, 4);
    const auto width = bigEndian(boxes_, source, 2);
    const auto height = bigEndian(boxes_, source + 2, 2);
    const auto depth = bigEndian(boxes_, source + 4, 2);
    source += 6;
    for (unsigned y = 0; y < height; ++y)
        for (unsigned word = 0; word < width; ++word, source += 16) {
            const auto mask = bigEndian(boxes_, source, 2);
            if (mask == 0xffff)
                continue;
            std::array<unsigned, 7> planes{};
            for (unsigned plane = 0; plane < depth && plane < planes.size(); ++plane)
                planes[plane] = bigEndian(boxes_, source + 2 + 2 * plane, 2);
            for (unsigned x = 0; x < 16; ++x) {
                auto& pixel = picture.at(offset * 8 + y * ScreenArt::Width + word * 16 + x);
                const auto bit = 1 << (15 - x);
                unsigned color = mask & bit ? pixel : 0;
                for (unsigned plane = 0; plane < planes.size(); ++plane)
                    if (planes[plane] & bit)
                        color |= 1 << plane;
                pixel = static_cast<std::uint8_t>(color);
            }
        }
}

void Menus::print(Bytes& picture, int x, int y, std::string_view phrase, unsigned color) const {
    printBitmap(picture, ScreenArt::Width, font_, x, y, phrase, color);
}

Bytes Menus::render(unsigned tick) const {
    if (!page_) {
        auto picture = main_.indices();
        drawSelection(picture, 0, (86 + 18 * row_) * 40 + 15);
        return main_.rgb(picture, std::min(tick, 15u) * 100 / 15, false, tick / 5);
    }
    auto picture = optionsArt_.indices();
    const auto rectangle = [&](int x, int y, int width, int height, unsigned color) {
        for (int row = y; row < y + height; ++row)
            std::fill_n(picture.begin() + row * ScreenArt::Width + x, width, color);
    };
    for (int y : {112, 142, 172})
        for (int x : {57, 217})
            rectangle(x + 2, y + 2, 79, 10, 23);
    rectangle(108, 129, 22, 10, 17);
    constexpr std::array controls{"Joystick 0", "Joystick 1", "Joy Doubler 3", "Joy Doubler 4",
                                  "Keyboard A-1/1", "Keyboard B-1/2", "Keyboard B-2/2"};
    constexpr std::array definitions{"Fl\xe8" "ches RAlt", "]879 Fl\xe8" "che droite", "\"EZR Espace"};
    const auto mode = options_.arena == ArenaMode::Random ? "Random" :
        options_.arena == ArenaMode::Sequential ? "Sequential" :
        options_.arena == ArenaMode::Dynablaster ? "Dynablaster" : "One level";
    print(picture, 60, 115, mode);
    const auto& arena = arenas_[arena_];
    print(picture, 60, 145, arena.level.name, arena.enabled ? 31 : 26);
    const auto number = std::to_string(arena.number / 100 + 1) + "-" +
        std::to_string(100 + arena.number % 100).substr(1);
    print(picture, 110, 130, number);
    print(picture, 60, 175, options_.fiveWins ? "5 Win Match" : "Free play");
    print(picture, 220, 115, options_.teams ? "Two Teams" : options_.survivor ? "Survivor" : "Individual");
    print(picture, 220, 145, controls[control_]);
    print(picture, 220, 175, definitions[definition_]);
    if (field_ < 0) {
        constexpr std::array offsets{3001u, 3021u, 8708u};
        drawSelection(picture, section_ == 2 ? 3 : 1, offsets[section_]);
    } else {
        drawSelection(picture, 4, (112 + 30 * field_) * 40 + (section_ == 0 ? 7 : 27));
    }
    return optionsArt_.rgb(picture, 100, false, tick / 5);
}
}

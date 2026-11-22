#include "preferences.hpp"

#include <algorithm>
#include <fstream>
#include <stdexcept>

namespace legoblast {
namespace {
constexpr std::size_t Size = 330, Levels = 50, Menus = 250;
constexpr std::array<std::uint8_t, 4> Magic{'L', 'E', 'G', 'O'};
constexpr std::array Modes{ArenaMode::Random, ArenaMode::Sequential, ArenaMode::Fixed, ArenaMode::Dynablaster};

unsigned read(const Bytes& data, std::size_t offset, int width) {
    unsigned value = 0;
    for (int i = 0; i < width; ++i)
        value = (value << 8) | data[offset + i];
    return value;
}

void write(Bytes& data, std::size_t offset, int width, unsigned value) {
    for (int i = width - 1; i >= 0; --i) {
        data[offset + i] = static_cast<std::uint8_t>(value);
        value >>= 8;
    }
}
}

std::size_t preferenceArenaSlot(unsigned number) {
    return (number / 100) * 30 + number % 100 - 1;
}

Preferences readPreferences(const std::filesystem::path& file) {
    Preferences prefs;
    std::ifstream input(file, std::ios::binary);
    Bytes data(Size);
    if (!input.read(reinterpret_cast<char*>(data.data()), data.size()) ||
        input.peek() != std::char_traits<char>::eof() ||
        !std::ranges::equal(std::span(data).first(4), Magic))
        return prefs;

    const auto volume = [&](int offset, unsigned initial) {
        const auto value = read(data, offset, 2);
        return value <= 64 ? value : initial;
    };
    prefs.musicVolume = volume(4, prefs.musicVolume);
    prefs.effectsVolume = volume(6, prefs.effectsVolume);
    const auto track = read(data, 48, 2);
    prefs.music = track <= 4 ? track : prefs.music;
    const auto gradient = read(data, 8, 2);
    prefs.gradient = gradient < 6 ? (gradient + 1) % 6 : prefs.gradient;
    for (std::size_t i = 0; i < prefs.disabled.size(); ++i)
        prefs.disabled[i] = data[Levels + i] != 0;

    const auto mode = read(data, Menus, 4);
    if (mode % 4 == 0 && mode / 4 < Modes.size())
        prefs.match.arena = Modes[mode / 4];
    const auto level = read(data, Menus + 4, 4);
    if (level % 8 == 0 && level / 8 < 180)
        prefs.arena = (level / 8 / 30) * 100 + level / 8 % 30 + 1;
    prefs.match.fiveWins = read(data, Menus + 8, 4) != 0;
    const auto layout = read(data, Menus + 12, 4);
    prefs.match.teams = layout == 4;
    prefs.match.survivor = layout == 8;
    const auto controls = read(data, Menus + 16, 4);
    const auto definition = read(data, Menus + 20, 4);
    if (controls % 4 == 0 && controls / 4 <= 6)
        prefs.controls = controls / 4;
    if (definition % 4 == 0 && definition / 4 <= 2)
        prefs.definition = definition / 4;
    return prefs;
}

void writePreferences(const std::filesystem::path& file, const Preferences& prefs) {
    Bytes data(Size);
    std::ranges::copy(Magic, data.begin());
    write(data, 4, 2, prefs.musicVolume);
    write(data, 6, 2, prefs.effectsVolume);
    write(data, 8, 2, prefs.gradient);
    write(data, 10, 2, prefs.gradient);
    write(data, 48, 2, prefs.music);
    for (std::size_t i = 0; i < prefs.disabled.size(); ++i)
        data[Levels + i] = prefs.disabled[i] ? 0xff : 0;

    const auto mode = std::ranges::find(Modes, prefs.match.arena) - Modes.begin();
    write(data, Menus, 4, static_cast<unsigned>(mode) * 4);
    write(data, Menus + 4, 4, static_cast<unsigned>(preferenceArenaSlot(prefs.arena)) * 8);
    write(data, Menus + 8, 4, prefs.match.fiveWins ? 4 : 0);
    write(data, Menus + 12, 4, prefs.match.teams ? 4 : prefs.match.survivor ? 8 : 0);
    write(data, Menus + 16, 4, prefs.controls * 4);
    write(data, Menus + 20, 4, prefs.definition * 4);

    auto temp = file;
    temp += ".tmp";
    std::ofstream output(temp, std::ios::binary | std::ios::trunc);
    output.write(reinterpret_cast<const char*>(data.data()), data.size());
    output.close();
    if (!output)
        throw std::runtime_error("cannot write LegoBlast preferences");
    std::filesystem::rename(temp, file);
}
}

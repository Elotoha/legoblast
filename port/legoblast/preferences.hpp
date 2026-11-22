#pragma once

#include "session.hpp"

namespace legoblast {
struct Preferences {
    MatchOptions match;
    unsigned music{1}, musicVolume{35}, effectsVolume{64};
    unsigned gradient{3};
    unsigned arena{1}, controls{4}, definition{};
    std::array<bool, 200> disabled{};
};

std::size_t preferenceArenaSlot(unsigned number);
Preferences readPreferences(const std::filesystem::path& file);
void writePreferences(const std::filesystem::path& file, const Preferences& prefs);
}

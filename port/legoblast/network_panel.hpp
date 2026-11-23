#pragma once

#include "netplay.hpp"

#include <SDL3/SDL.h>

namespace legoblast {

class NetworkPanel {
public:
    NetworkPanel(std::string url, std::filesystem::path preference);
    bool handle(const SDL_Event& event, SDL_Renderer* renderer, bool gameplay);
    void render(SDL_Renderer* renderer, bool gameplay) const;
    bool modal() const;
    void started() { open_ = false; }

    Network link;
private:
    struct Item { SDL_FRect box; std::string label, action; };
    std::vector<Item> items(float x, float y) const;
    void activate(std::string_view action);
    void save() const;
    std::filesystem::path preference_;
    bool open_{};
    std::size_t selection_{};
};
}

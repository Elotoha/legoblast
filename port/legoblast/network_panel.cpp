#include "network_panel.hpp"

#include <fstream>

namespace legoblast {
namespace {
void color(SDL_Renderer* renderer, Uint8 red, Uint8 green, Uint8 blue) {
    SDL_SetRenderDrawColor(renderer, red, green, blue, 255);
}

void label(SDL_Renderer* renderer, float x, float y, const std::string& text) {
    SDL_RenderDebugText(renderer, x, y, text.c_str());
}

SDL_FRect badge(SDL_Renderer* renderer, bool gameplay) {
    int width{}, height{};
    SDL_GetRenderLogicalPresentation(renderer, &width, &height, nullptr);
    const bool touch = width > NetWidth;
    return {float(width - (touch ? 76 : 86)), gameplay && touch ? 135.f : 55.f, 68, 31};
}

void tile(SDL_Renderer* renderer, SDL_FRect box, const std::string& text, bool focus = false) {
    if (focus) color(renderer, 61, 83, 106);
    else color(renderer, 41, 55, 75);
    SDL_RenderFillRect(renderer, &box);
    color(renderer, 208, 226, 239);
    SDL_RenderRect(renderer, &box);
    label(renderer, box.x + (box.w - 8.f * text.size()) / 2, box.y + (box.h - 8.f) / 2, text);
}
}

NetworkPanel::NetworkPanel(std::string url, std::filesystem::path preference)
    : link(std::move(url)), preference_(std::move(preference)) {
    if (std::ifstream(preference_).get() == '1') link.enable(true);
}

bool NetworkPanel::modal() const {
    return open_ || !link.offer.empty() || (link.room && !link.room->started);
}

std::vector<NetworkPanel::Item> NetworkPanel::items(float x, float y) const {
    std::vector<Item> buttons;
    const auto add = [&](float dx, float dy, float width, const char* label, const char* action) {
        buttons.push_back({{x + dx, y + dy, width, 27}, label, action});
    };
    if (!link.offer.empty() && !link.room) {
        add(16, 100, 124, "REJOINDRE", "join");
        add(152, 100, 124, "REFUSER", "decline");
    } else if (link.room && !link.room->started) {
        add(16, 96, 78, "+ LIA", "lia");
        add(106, 96, 78, "+ MICRO", "micro");
        add(196, 96, 80, "- BOT", "remove");
        add(16, 132, 130, "QUITTER", "leave");
    } else if (link.room && link.room->started) {
        add(16, 100, 124, "QUITTER", "leave");
        add(152, 100, 124, "RETOUR", "close");
    } else {
        if (link.connected) add(16, 54, 260, "INVITER", "create");
        add(16, 89, 260, link.enabled ? "COUPER LES INVITATIONS" : "ACTIVER LES INVITATIONS", "toggle");
        add(16, 124, 260, "RETOUR AU JEU", "close");
    }
    return buttons;
}

void NetworkPanel::save() const {
    if (!preference_.empty()) std::ofstream(preference_) << (link.enabled ? '1' : '0');
}

void NetworkPanel::activate(std::string_view action) {
    selection_ = 0;
    if (action == "toggle") {
        link.enable(!link.enabled);
        save();
    } else if (action == "create") {
        link.send("CREATE");
    } else if (action == "join") {
        link.send("JOIN " + link.offer);
        link.decline();
        open_ = true;
    } else if (action == "decline") {
        link.decline();
        open_ = false;
    } else if (action == "lia") {
        link.send("ADD L");
    } else if (action == "micro") {
        link.send("ADD M");
    } else if (action == "remove") {
        link.send("REMOVE");
    } else if (action == "leave") {
        link.leave();
        open_ = false;
    } else if (action == "close") {
        open_ = false;
    }
}

bool NetworkPanel::handle(const SDL_Event& event, SDL_Renderer* renderer, bool gameplay) {
    if (event.type == SDL_EVENT_KEY_DOWN && !event.key.repeat) {
        if (event.key.scancode == SDL_SCANCODE_F11) {
            open_ = !open_;
            return true;
        }
        if (modal() && (event.key.key == SDLK_ESCAPE || event.key.key == SDLK_AC_BACK)) {
            if (!link.offer.empty()) activate("decline");
            else if (link.room && !link.room->started) activate("leave");
            else activate("close");
            return true;
        }
    }
    if (modal() && event.type == SDL_EVENT_KEY_DOWN && !event.key.repeat) {
        const auto actions = items(0, 0);
        if (!actions.empty()) {
            selection_ %= actions.size();
            if (event.key.key == SDLK_UP)
                selection_ = (selection_ + actions.size() - 1) % actions.size();
            else if (event.key.key == SDLK_DOWN)
                selection_ = (selection_ + 1) % actions.size();
            else if (event.key.key == SDLK_RETURN || event.key.key == SDLK_KP_ENTER)
                activate(actions[selection_].action);
        }
        return true;
    }
    SDL_FPoint point{};
    if (event.type == SDL_EVENT_FINGER_DOWN || event.type == SDL_EVENT_MOUSE_BUTTON_DOWN) {
        auto converted = event;
        if (!SDL_ConvertEventToRenderCoordinates(renderer, &converted)) return false;
        if (event.type == SDL_EVENT_FINGER_DOWN)
            point = {converted.tfinger.x, converted.tfinger.y};
        else {
            if (event.button.which == SDL_TOUCH_MOUSEID || event.button.button != SDL_BUTTON_LEFT) return modal();
            point = {converted.button.x, converted.button.y};
        }
        if (!modal()) {
            int width{};
            SDL_GetRenderLogicalPresentation(renderer, &width, nullptr, nullptr);
            const auto box = badge(renderer, gameplay);
            if ((!gameplay || width > NetWidth) && SDL_PointInRectFloat(&point, &box)) {
                open_ = true;
                return true;
            }
        } else {
            int w{}, h{};
            SDL_GetRenderLogicalPresentation(renderer, &w, &h, nullptr);
            for (const auto& item : items((w - 292.f) / 2, (h - 176.f) / 2))
                if (SDL_PointInRectFloat(&point, &item.box)) {
                    activate(item.action);
                    break;
                }
            return true;
        }
    }
    return modal() && (event.type == SDL_EVENT_FINGER_MOTION || event.type == SDL_EVENT_FINGER_UP ||
        event.type == SDL_EVENT_KEY_DOWN || event.type == SDL_EVENT_MOUSE_BUTTON_UP);
}

void NetworkPanel::render(SDL_Renderer* renderer, bool gameplay) const {
    int w{}, h{};
    SDL_GetRenderLogicalPresentation(renderer, &w, &h, nullptr);
    if (!modal()) {
        if (gameplay && w == NetWidth) return;
        const auto box = badge(renderer, gameplay);
        tile(renderer, box, "RESEAU");
        constexpr std::array<unsigned, 7> head{0b0011100, 0b0111110, 0b1111111,
            0b1011101, 0b1111111, 0b1100011, 0b0111110};
        color(renderer, 235, 205, 42);
        SDL_RenderLine(renderer, box.x + 24, box.y + 5, box.x + 44, box.y + 5);
        for (float offset : {16.f, 44.f})
            for (unsigned y = 0; y < head.size(); ++y)
                for (unsigned x = 0; x < 7; ++x)
                    if (head[y] & (1u << x)) SDL_RenderPoint(renderer, box.x + offset + x, box.y + 2 + y);
        return;
    }
    const SDL_FRect panel{(w - 292.f) / 2, (h - 176.f) / 2, 292, 176};
    color(renderer, 16, 23, 35);
    SDL_RenderFillRect(renderer, &panel);
    color(renderer, 208, 226, 239);
    SDL_RenderRect(renderer, &panel);
    const auto x = panel.x + 16, y = panel.y;
    if (!link.offer.empty() && !link.room) {
        label(renderer, x, y + 16, "INVITATION RESEAU");
        label(renderer, x, y + 47, "Rejoindre le salon " + link.offer);
    } else if (link.room) {
        const auto& room = *link.room;
        label(renderer, x, y + 16, "SALON " + room.code + "  " + std::to_string(room.roster.size()) + "/4");
        for (unsigned i = 0; i < NetworkPlaces; ++i) {
            const auto kind = i < room.roster.size() ? room.roster[i] : '-';
            const auto name = kind == 'H' ? "JOUEUR" : kind == 'L' ? "LIA" : kind == 'M' ? "MICRO" : "LIBRE";
            label(renderer, x + (i % 2) * 130, y + 42 + (i / 2) * 21,
                  std::to_string(i + 1) + " " + (i == room.seat ? "MOI" : name));
        }
    } else {
        label(renderer, x, y + 16, "RESEAU  |  F11");
        label(renderer, x, y + 35, link.connected ? "INVITATIONS ACTIVES" :
              link.enabled ? (link.notice.empty() ? "CONNEXION..." : link.notice) : "JEU LOCAL");
    }
    const auto controls = items(panel.x, panel.y);
    for (std::size_t i = 0; i < controls.size(); ++i)
        tile(renderer, controls[i].box, controls[i].label, i == selection_ % controls.size());
}
}

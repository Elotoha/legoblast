#pragma once

#include <SDL3/SDL.h>

#include <array>
#include <memory>
#include <span>
#include <string_view>
#include <utility>
#include <vector>

namespace legoblast {

// The touchscreen gets its own player slot. Convert these input events
// through the same press/release handling as a physical keyboard.
inline constexpr std::array TouchKeys{SDL_SCANCODE_F13, SDL_SCANCODE_F14,
    SDL_SCANCODE_F15, SDL_SCANCODE_F16, SDL_SCANCODE_F17};

class Presentation {
public:
    Presentation(int width, int height);
    void configure(int width, int height, bool gameplay);
    SDL_Renderer* renderer() const { return renderer_.get(); }
    bool handle(const SDL_Event& event);
    void beginFrame();
    void present(std::string_view status = {});

private:
    struct Button {
        SDL_FRect box;
        SDL_Scancode key;
        const char* label;
        bool keepOpen{};
    };
    struct Touch {
        SDL_TouchID device;
        SDL_FingerID finger;
        SDL_Scancode key;
        bool steering;
    };

    void key(SDL_Scancode code, bool down);
    bool held(SDL_Scancode code) const;
    void clearTouches();
    void drawButtons(std::span<const Button> buttons);
    void drawControls(std::string_view status);
    void configureShortcuts(int width, int height, bool gameplay);
    bool handleShortcutTouch(const SDL_TouchFingerEvent& finger, SDL_FPoint point);
    SDL_Scancode directionAt(SDL_FPoint point, SDL_Scancode previous) const;

    std::unique_ptr<SDL_Window, decltype(&SDL_DestroyWindow)> window_{nullptr, SDL_DestroyWindow};
    std::unique_ptr<SDL_Renderer, decltype(&SDL_DestroyRenderer)> renderer_{nullptr, SDL_DestroyRenderer};
    SDL_Rect viewport_{};
    SDL_FRect steeringArea_{};
    std::vector<Touch> touches_;
    std::vector<Button> buttons_;
    SDL_FRect shortcutToggle_{}, shortcutPanel_{};
    std::vector<Button> shortcutButtons_;
    std::vector<std::pair<SDL_TouchID, SDL_FingerID>> shortcutFingers_;
    bool shortcutsOpen_{};
};

}

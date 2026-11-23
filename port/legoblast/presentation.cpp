#include "presentation.hpp"

#include <algorithm>
#include <cmath>
#include <stdexcept>
#include <string>

namespace legoblast {
namespace {
#ifdef SDL_PLATFORM_ANDROID
constexpr bool Touchscreen = true;
#else
constexpr bool Touchscreen = false;
#endif
constexpr int Gutter = Touchscreen ? 84 : 0;
constexpr std::array<Uint8, 3> Background{14, 19, 29};

void check(bool ok) {
    if (!ok)
        throw std::runtime_error(SDL_GetError());
}
}

Presentation::Presentation(int width, int height) {
    if (Touchscreen) {
        SDL_SetHint(SDL_HINT_TOUCH_MOUSE_EVENTS, "0");
        SDL_SetHint(SDL_HINT_ANDROID_TRAP_BACK_BUTTON, "1");
        SDL_SetHint(SDL_HINT_ORIENTATIONS, "LandscapeLeft LandscapeRight");
    }
    SDL_Window* window{};
    SDL_Renderer* renderer{};
    check(SDL_CreateWindowAndRenderer("LegoBlast", 3 * width, 3 * height,
                                      Touchscreen ? SDL_WINDOW_FULLSCREEN : SDL_WINDOW_RESIZABLE,
                                      &window, &renderer));
    window_.reset(window);
    renderer_.reset(renderer);
    if (Touchscreen)
        SDL_SetRenderVSync(renderer, 1);
}

void Presentation::configure(int width, int height, bool gameplay) {
    clearTouches();
    shortcutsOpen_ = false;
    shortcutFingers_.clear();
    check(SDL_SetRenderViewport(renderer(), nullptr));
    check(SDL_SetRenderLogicalPresentation(renderer(), width + 2 * Gutter, height,
        Touchscreen ? SDL_LOGICAL_PRESENTATION_LETTERBOX : SDL_LOGICAL_PRESENTATION_INTEGER_SCALE));
    if (!Touchscreen)
        check(SDL_SetWindowMinimumSize(window_.get(), width, height));
    viewport_ = {Gutter, 0, width, height};
    if (!Touchscreen)
        return;
    const float right = width + Gutter;
    const float center = height - 86.f;
    steeringArea_ = gameplay ? SDL_FRect{0, center - 67, Gutter, 134} : SDL_FRect{};
    buttons_ = {
        {{26, center - 53, 32, 34}, gameplay ? TouchKeys[2] : SDL_SCANCODE_UP, "^"},
        {{ 4, center - 17, 34, 34}, gameplay ? TouchKeys[0] : SDL_SCANCODE_LEFT, "<"},
        {{46, center - 17, 34, 34}, gameplay ? TouchKeys[1] : SDL_SCANCODE_RIGHT, ">"},
        {{26, center + 19, 32, 34}, gameplay ? TouchKeys[3] : SDL_SCANCODE_DOWN, "v"},
        {{right + 8, height - 78.f, 68, 50}, gameplay ? TouchKeys[4] : SDL_SCANCODE_RETURN, gameplay ? "FIRE" : "OK"},
        {{right + 8, 9, 68, 34}, SDL_SCANCODE_ESCAPE, "BACK"},
    };
    if (gameplay) {
        buttons_.push_back({{8, 9, 68, 34}, SDL_SCANCODE_P, "PAUSE"});
        buttons_.push_back({{right + 8, 52, 68, 34}, SDL_SCANCODE_BACKSPACE, "MICRO"});
        buttons_.push_back({{right + 8, 93, 68, 34}, SDL_SCANCODE_L, "LIA"});
    }
    configureShortcuts(width + 2 * Gutter, height, gameplay);
}

void Presentation::configureShortcuts(int width, int height, bool gameplay) {
    shortcutToggle_ = {8, gameplay ? 52.f : 9.f, 68, 34};
    shortcutPanel_ = {18, 10, width - 36.f, height - 20.f};
    shortcutButtons_.clear();
    shortcutButtons_.push_back({{width - 108.f, 19, 80, 30}, SDL_SCANCODE_UNKNOWN, "FERMER"});
    const auto add = [&](SDL_Scancode key, const char* label, bool keepOpen = false) {
        const auto tile = shortcutButtons_.size() - 1;
        const float boxWidth = (shortcutPanel_.w - 40.f) / 4.f;
        const float left = shortcutPanel_.x + 8.f + (tile % 4) * (boxWidth + 8.f);
        const float top = 60.f + (tile / 4) * 40.f;
        shortcutButtons_.push_back({{left, top, boxWidth, 34}, key, label, keepOpen});
    };
    if (gameplay) {
        add(SDL_SCANCODE_F1, "ARENE -");
        add(SDL_SCANCODE_F2, "ARENE +");
        add(SDL_SCANCODE_HOME, "REJOUER");
        add(SDL_SCANCODE_BACKSLASH, "PODIUM");
        constexpr std::array tracks{"MUSIQUE 1", "MUSIQUE 2", "MUSIQUE 3", "MUSIQUE 4",
                                    "MUSIQUE 5", "MUSIQUE 6", "MUSIQUE 7", "MUET"};
        for (std::size_t i = 0; i < tracks.size(); ++i)
            add(static_cast<SDL_Scancode>(SDL_SCANCODE_F3 + i), tracks[i]);
        add(SDL_SCANCODE_KP_MINUS, "VOL MUS -", true);
        add(SDL_SCANCODE_KP_PLUS, "VOL MUS +", true);
        add(SDL_SCANCODE_KP_DIVIDE, "EFFETS -", true);
        add(SDL_SCANCODE_KP_MULTIPLY, "EFFETS +", true);
    } else {
        add(SDL_SCANCODE_F1, "VOIX 1", true);
        add(SDL_SCANCODE_F2, "VOIX 2", true);
        add(SDL_SCANCODE_F3, "VOIX 3", true);
        add(SDL_SCANCODE_F4, "VOIX 4", true);
        add(SDL_SCANCODE_SPACE, "CREDITS");
    }
}

bool Presentation::handleShortcutTouch(const SDL_TouchFingerEvent& finger, SDL_FPoint point) {
    const auto id = std::pair{finger.touchID, finger.fingerID};
    const auto blocked = std::ranges::find(shortcutFingers_, id);
    if (blocked != shortcutFingers_.end()) {
        if (finger.type == SDL_EVENT_FINGER_UP || finger.type == SDL_EVENT_FINGER_CANCELED)
            shortcutFingers_.erase(blocked);
        return true;
    }
    if (finger.type != SDL_EVENT_FINGER_DOWN)
        return shortcutsOpen_;
    if (!shortcutsOpen_ && !SDL_PointInRectFloat(&point, &shortcutToggle_))
        return false;

    shortcutFingers_.push_back(id);
    if (!shortcutsOpen_) {
        for (const auto& touch : touches_)
            shortcutFingers_.emplace_back(touch.device, touch.finger);
        clearTouches();
        shortcutsOpen_ = true;
        return true;
    }
    for (const auto& button : shortcutButtons_) {
        if (!SDL_PointInRectFloat(&point, &button.box))
            continue;
        if (button.key != SDL_SCANCODE_UNKNOWN) {
            key(button.key, true);
            key(button.key, false);
        }
        shortcutsOpen_ = button.keepOpen;
        return true;
    }
    if (!SDL_PointInRectFloat(&point, &shortcutPanel_))
        shortcutsOpen_ = false;
    return true;
}

void Presentation::key(SDL_Scancode code, bool down) {
    SDL_Event event{};
    event.type = down ? SDL_EVENT_KEY_DOWN : SDL_EVENT_KEY_UP;
    event.key.windowID = SDL_GetWindowID(window_.get());
    event.key.scancode = code;
    event.key.key = SDL_GetKeyFromScancode(code, SDL_KMOD_NONE, false);
    event.key.down = down;
    check(SDL_PushEvent(&event));
}

bool Presentation::held(SDL_Scancode code) const {
    return std::ranges::any_of(touches_, [code](const Touch& touch) { return touch.key == code; });
}

void Presentation::clearTouches() {
    for (const auto& button : buttons_)
        if (held(button.key))
            key(button.key, false);
    touches_.clear();
}

SDL_Scancode Presentation::directionAt(SDL_FPoint point, SDL_Scancode previous) const {
    const float dx = point.x - (steeringArea_.x + steeringArea_.w / 2);
    const float dy = point.y - (steeringArea_.y + steeringArea_.h / 2);
    const float horizontal = std::abs(dx), vertical = std::abs(dy);
    if (std::max(horizontal, vertical) < 8.f)
        return SDL_SCANCODE_UNKNOWN;
    // Hold the current axis near a diagonal to avoid oscillating at the corners.
    const auto stick = std::abs(horizontal - vertical) < 4.f;
    const auto wasHorizontal = previous == TouchKeys[0] || previous == TouchKeys[1];
    const auto useHorizontal = stick && previous != SDL_SCANCODE_UNKNOWN ? wasHorizontal : horizontal > vertical;
    return useHorizontal ? TouchKeys[dx < 0 ? 0 : 1] : TouchKeys[dy < 0 ? 2 : 3];
}

bool Presentation::handle(const SDL_Event& event) {
    if (!Touchscreen)
        return false;
    if (event.type == SDL_EVENT_WINDOW_FOCUS_LOST || event.type == SDL_EVENT_WILL_ENTER_BACKGROUND) {
        clearTouches();
        shortcutFingers_.clear();
        shortcutsOpen_ = false;
        return false;
    }
    if (shortcutsOpen_ && event.type == SDL_EVENT_KEY_DOWN &&
        (event.key.scancode == SDL_SCANCODE_ESCAPE || event.key.key == SDLK_AC_BACK)) {
        shortcutsOpen_ = false;
        return true;
    }

    const bool release = event.type == SDL_EVENT_FINGER_UP || event.type == SDL_EVENT_FINGER_CANCELED;
    if (!release && event.type != SDL_EVENT_FINGER_DOWN && event.type != SDL_EVENT_FINGER_MOTION)
        return false;
    const auto& finger = event.tfinger;
    SDL_FPoint point{};
    if (!release) {
        SDL_Event converted = event;
        check(SDL_ConvertEventToRenderCoordinates(renderer(), &converted));
        point = {converted.tfinger.x, converted.tfinger.y};
    }
    if (handleShortcutTouch(finger, point))
        return true;

    auto found = std::ranges::find_if(touches_, [&](const Touch& touch) {
        return finger.touchID == touch.device && finger.fingerID == touch.finger;
    });
    const auto previous = found == touches_.end() ? SDL_SCANCODE_UNKNOWN : found->key;
    SDL_Scancode next = SDL_SCANCODE_UNKNOWN;
    bool steering = found != touches_.end() && found->steering;
    if (!release) {
        if (event.type == SDL_EVENT_FINGER_DOWN && SDL_PointInRectFloat(&point, &steeringArea_))
            steering = std::ranges::none_of(touches_, &Touch::steering);
        if (steering) {
            next = directionAt(point, previous);
        } else {
            for (const auto& button : buttons_) {
                // Directions belong to the captured thumb in gameplay.
                if (steeringArea_.w && button.key >= TouchKeys[0] && button.key <= TouchKeys[3])
                    continue;
                if ((button.key != SDL_SCANCODE_L || event.type == SDL_EVENT_FINGER_DOWN ||
                     previous == SDL_SCANCODE_L) && SDL_PointInRectFloat(&point, &button.box)) {
                    next = button.key;
                    break;
                }
            }
        }
    }
    if (previous == next && !release && (!steering || found != touches_.end()))
        return false;
    if (found != touches_.end())
        touches_.erase(found);
    if (previous != SDL_SCANCODE_UNKNOWN && !held(previous))
        key(previous, false);
    if (next != SDL_SCANCODE_UNKNOWN || (steering && !release)) {
        const bool alreadyHeld = held(next);
        touches_.push_back({finger.touchID, finger.fingerID, next, steering});
        if (next != SDL_SCANCODE_UNKNOWN && !alreadyHeld)
            key(next, true);
    }
    return false;
}

void Presentation::beginFrame() {
    check(SDL_SetRenderDrawColor(renderer(), Background[0], Background[1], Background[2], 255));
    check(SDL_RenderClear(renderer()));
    check(SDL_SetRenderViewport(renderer(), &viewport_));
}

void Presentation::drawButtons(std::span<const Button> buttons) {
    for (const auto& button : buttons) {
        const bool pressed = held(button.key);
        check(SDL_SetRenderDrawColor(renderer(), pressed ? 107 : 41, pressed ? 78 : 50, pressed ? 46 : 67, 255));
        check(SDL_RenderFillRect(renderer(), &button.box));
        check(SDL_SetRenderDrawColor(renderer(), 220, 226, 233, 255));
        check(SDL_RenderRect(renderer(), &button.box));
        const float labelWidth = SDL_strlen(button.label) * SDL_DEBUG_TEXT_FONT_CHARACTER_SIZE;
        check(SDL_RenderDebugText(renderer(), button.box.x + (button.box.w - labelWidth) / 2,
            button.box.y + (button.box.h - SDL_DEBUG_TEXT_FONT_CHARACTER_SIZE) / 2, button.label));
    }
}

void Presentation::drawControls(std::string_view status) {
    if (shortcutsOpen_) {
        check(SDL_SetRenderDrawColor(renderer(), 20, 27, 39, 255));
        check(SDL_RenderFillRect(renderer(), &shortcutPanel_));
        check(SDL_SetRenderDrawColor(renderer(), 220, 226, 233, 255));
        check(SDL_RenderRect(renderer(), &shortcutPanel_));
        check(SDL_RenderDebugText(renderer(), shortcutPanel_.x + 8, 28, "RACCOURCIS"));
        if (!status.empty())
            check(SDL_RenderDebugText(renderer(), shortcutPanel_.x + 8, 226, std::string(status).c_str()));
        drawButtons(shortcutButtons_);
        return;
    }
    if (steeringArea_.w) {
        check(SDL_SetRenderDrawColor(renderer(), 24, 32, 45, 255));
        check(SDL_RenderFillRect(renderer(), &steeringArea_));
    }
    drawButtons(buttons_);
    const Button toggle{shortcutToggle_, SDL_SCANCODE_UNKNOWN, "RACC."};
    drawButtons(std::span(&toggle, 1));
}

void Presentation::present(std::string_view status) {
    check(SDL_SetRenderViewport(renderer(), nullptr));
    if (Touchscreen)
        drawControls(status);
    check(SDL_RenderPresent(renderer()));
}
}

#pragma once

#include "assets.hpp"

#include <span>

class Mixer {
public:
    static constexpr unsigned Rate = 48000;

    explicit Mixer(std::size_t voiceCount);
    void play(const Music& cue);
    void enableStem(std::size_t index, bool enabled);
    bool play(const Sound& sound, unsigned repetitions = 1);
    void render(std::span<float> stereo);

private:
    struct Voice {
        const Sound* sound{};
        std::uint64_t position{};
        unsigned repetitions{};
        std::uint64_t order{};
    };

    const Music* music_{};
    std::uint64_t musicPosition_{};
    std::vector<bool> enabledStems_;
    std::vector<Voice> voices_;
    std::uint64_t order_{};
};

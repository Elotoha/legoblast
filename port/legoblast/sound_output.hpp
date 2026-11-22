#pragma once

#include "sound_cues.hpp"

#include <filesystem>
#include <memory>
#include <span>

namespace legoblast {
class SoundOutput {
public:
    SoundOutput(const std::filesystem::path& root, unsigned track, bool smoke);
    ~SoundOutput();
    bool selectTrack(unsigned track);
    void tick(std::span<const SoundRequest> requests, bool paused, bool results, bool podium = false);

private:
    struct Playback;
    std::unique_ptr<Playback> playback_;
};
}

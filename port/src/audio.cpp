#include "audio.hpp"

#include <algorithm>
#include <array>
#include <stdexcept>
#include <tuple>

namespace {
void mixFrame(std::array<float, 2>& output, const AudioClip& clip, std::uint64_t position,
              std::size_t next, float gain) {
    const auto frame = position / Mixer::Rate;
    const auto fraction = static_cast<float>(position % Mixer::Rate) / Mixer::Rate;
    for (unsigned channel = 0; channel < output.size(); ++channel) {
        const unsigned source = clip.channels == 1 ? 0 : channel;
        const float a = clip.samples[frame * clip.channels + source];
        const float b = clip.samples[next * clip.channels + source];
        output[channel] += (a + (b - a) * fraction) * gain;
    }
}
}

Mixer::Mixer(std::size_t voiceCount) : voices_(voiceCount) {
    if (!voiceCount)
        throw std::invalid_argument("mixer requires at least one effect voice");
}

void Mixer::play(const Music& cue) {
    music_ = &cue;
    musicPosition_ = 0;
    musicVolume_ = cue.volume;
    enabledStems_.assign(cue.stems.size(), true);
}

void Mixer::seekMusic(std::uint32_t milliseconds) {
    if (!music_) return;
    auto frame = std::uint64_t(milliseconds) * music_->stems.front().rate / 1000;
    if (frame >= music_->loopEnd)
        frame = music_->loopStart + (frame - music_->loopEnd) % (music_->loopEnd - music_->loopStart);
    musicPosition_ = frame * Rate;
}

void Mixer::enableStem(std::size_t index, bool enabled) {
    enabledStems_.at(index) = enabled;
}

bool Mixer::play(const Sound& sound, unsigned repetitions) {
    if (!repetitions)
        return false;
    auto voice = std::find_if(voices_.begin(), voices_.end(), [](auto& item) {
        return item.sound == nullptr;
    });
    if (voice == voices_.end()) {
        voice = std::min_element(voices_.begin(), voices_.end(), [](auto& a, auto& b) {
            return std::tie(a.sound->priority, a.order) < std::tie(b.sound->priority, b.order);
        });
        if (voice->sound->priority > sound.priority)
            return false;
    }
    *voice = {&sound, 0, repetitions, order_++};
    return true;
}

void Mixer::render(std::span<float> stereo) {
    if (stereo.size() % 2 != 0)
        throw std::invalid_argument("mixer expects complete stereo frames");

    for (std::size_t sample = 0; sample < stereo.size(); sample += 2) {
        std::array<float, 2> output{};
        if (music_) {
            const auto frame = musicPosition_ / Rate;
            const auto next = frame + 1 == music_->loopEnd ? music_->loopStart : frame + 1;
            for (std::size_t i = 0; i < music_->stems.size(); ++i)
                if (enabledStems_[i])
                    mixFrame(output, music_->stems[i], musicPosition_, next, musicVolume_);
            musicPosition_ += music_->stems.front().rate;
            const auto end = music_->loopEnd * static_cast<std::uint64_t>(Rate);
            const auto start = music_->loopStart * static_cast<std::uint64_t>(Rate);
            if (musicPosition_ >= end)
                musicPosition_ = start + (musicPosition_ - end) % (end - start);
        }
        for (auto& voice : voices_) {
            if (!voice.sound)
                continue;
            const auto& clip = voice.sound->clip;
            const auto frame = voice.position / Rate;
            const auto next = frame + 1 < clip.frames() ? frame + 1 : voice.repetitions > 1 ? 0 : frame;
            mixFrame(output, clip, voice.position, next, voice.sound->volume);
            voice.position += clip.rate;
            const auto length = clip.frames() * static_cast<std::uint64_t>(Rate);
            const auto completed = voice.position / length;
            if (completed >= voice.repetitions) {
                voice.sound = nullptr;
            } else {
                voice.repetitions -= static_cast<unsigned>(completed);
                voice.position %= length;
            }
        }
        stereo[sample] = std::clamp(output[0], -1.0f, 1.0f);
        stereo[sample + 1] = std::clamp(output[1], -1.0f, 1.0f);
    }
}

#include "sound_output.hpp"
#include "audio.hpp"
#include "audio_io.hpp"

#include <SDL3/SDL.h>
#include <sndfile.h>

#include <array>
#include <stdexcept>

namespace legoblast {
struct SoundOutput::Playback {
    std::array<Sound, static_cast<unsigned>(SoundCue::Count)> effects{};
    Music music{};
    Mixer mixer;
    std::unique_ptr<SDL_AudioStream, decltype(&SDL_DestroyAudioStream)> stream{nullptr, SDL_DestroyAudioStream};
    bool smoke;

    Playback(const std::filesystem::path& root, unsigned track, bool smokeTest)
        : mixer(track ? 1 : 4), smoke(smokeTest) {
        for (unsigned i = 0; i < effects.size(); ++i) {
            const auto file = "sample-" + std::to_string(100 + i).substr(1) + ".wav";
            effects[i].clip = loadAudioClip(root / file, SF_FORMAT_WAV);
            effects[i].volume = 0.5f;
        }
        if (track) {
            const auto file = "Mod_Game" + std::to_string(track) + ".flac";
            music.stems.push_back(loadAudioClip(root / file, SF_FORMAT_FLAC));
            music.loopEnd = music.stems.front().frames();
            music.volume = 35.f / 64;
            mixer.play(music);
        }
        if (SDL_InitSubSystem(SDL_INIT_AUDIO)) {
            const SDL_AudioSpec output{SDL_AUDIO_F32, 2, Mixer::Rate};
            stream.reset(SDL_OpenAudioDeviceStream(SDL_AUDIO_DEVICE_DEFAULT_PLAYBACK, &output, nullptr, nullptr));
        }
        if (stream && SDL_ResumeAudioStreamDevice(stream.get()))
            return;
        if (smoke)
            throw std::runtime_error(SDL_GetError());
        SDL_Log("LegoBlast audio is unavailable: %s", SDL_GetError());
        stream.reset();
    }
};

SoundOutput::SoundOutput(const std::filesystem::path& root, unsigned track, bool smoke)
    : playback_(std::make_unique<Playback>(root, track, smoke)) {}

SoundOutput::~SoundOutput() = default;

void SoundOutput::tick(std::span<const SoundRequest> requests, bool paused, bool results) {
    auto& output = *playback_;
    if (!output.stream)
        return;
    for (const auto& request : requests) {
        auto& effect = output.effects.at(static_cast<unsigned>(request.cue));
        effect.priority = request.priority;
        output.mixer.play(effect, request.repetitions);
    }
    constexpr std::size_t samplesPerTick = 2 * Mixer::Rate / 50;
    constexpr int bytesPerTick = samplesPerTick * sizeof(float);
    output.mixer.setMusicVolume((paused ? 5.f : results ? 20.f : 35.f) / 64);
    if (SDL_GetAudioStreamQueued(output.stream.get()) >= 3 * bytesPerTick)
        return;
    std::array<float, samplesPerTick> stereo;
    output.mixer.render(stereo);
    if (!SDL_PutAudioStreamData(output.stream.get(), stereo.data(), bytesPerTick) && output.smoke)
        throw std::runtime_error(SDL_GetError());
}
}

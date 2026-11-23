#include "sound_output.hpp"
#include "audio.hpp"
#include "audio_io.hpp"

#include <SDL3/SDL.h>

#include <array>
#include <algorithm>
#include <atomic>
#include <stdexcept>
#include <utility>

namespace legoblast {
namespace {
class AudioLock {
public:
    explicit AudioLock(SDL_AudioStream* stream) : stream_(stream) {
        if (stream_ && !SDL_LockAudioStream(stream_))
            throw std::runtime_error(SDL_GetError());
    }
    ~AudioLock() { if (stream_) SDL_UnlockAudioStream(stream_); }
    AudioLock(const AudioLock&) = delete;
    AudioLock& operator=(const AudioLock&) = delete;
private:
    SDL_AudioStream* stream_;
};
}

struct SoundOutput::Playback {
    std::array<Sound, static_cast<unsigned>(SoundCue::Count)> effects{};
    std::filesystem::path assetRoot;
    unsigned currentTrack{};
    Music music{};
    Mixer mixer{4};
    Mixer podiumMixer{4};
    Mixer* activeMixer{&mixer};
    unsigned musicVolume{35};
    unsigned effectsVolume{64};
    std::atomic<std::uint64_t> renderedFrames{};
    std::atomic<bool> submitFailed{};
    // Destroy the stream and join its callbacks before destroying mixer state.
    std::unique_ptr<SDL_AudioStream, decltype(&SDL_DestroyAudioStream)> stream{nullptr, SDL_DestroyAudioStream};

    Playback(const std::filesystem::path& root, unsigned track, bool smokeTest)
        : assetRoot(root) {
        for (unsigned i = 0; i < effects.size(); ++i) {
            const auto file = "sample-" + std::to_string(100 + i).substr(1) + ".wav";
            effects[i].clip = loadAudioClip(root / file, AudioContainer::Wav);
            effects[i].volume = 0.5f;
        }
        select(track);
        if (SDL_InitSubSystem(SDL_INIT_AUDIO)) {
            const SDL_AudioSpec output{SDL_AUDIO_F32, 2, Mixer::Rate};
            stream.reset(SDL_OpenAudioDeviceStream(SDL_AUDIO_DEVICE_DEFAULT_PLAYBACK, &output, nullptr, nullptr));
        }
        if (stream && SDL_SetAudioStreamGetCallback(stream.get(), fill, this) &&
            SDL_ResumeAudioStreamDevice(stream.get()))
            return;
        if (smokeTest)
            throw std::runtime_error(SDL_GetError());
        SDL_Log("LegoBlast audio is unavailable: %s", SDL_GetError());
        stream.reset();
    }

    static void SDLCALL fill(void* userdata, SDL_AudioStream* stream, int needed, int) {
        auto& audio = *static_cast<Playback*>(userdata);
        constexpr int bytesPerFrame = 2 * sizeof(float);
        std::array<float, 2 * 1024> stereo;
        for (int frames = (std::max(needed, 0) + bytesPerFrame - 1) / bytesPerFrame; frames > 0;) {
            const auto count = std::min(frames, 1024);
            audio.activeMixer->render(std::span(stereo).first(2 * count));
            if (!SDL_PutAudioStreamData(stream, stereo.data(), count * bytesPerFrame)) {
                audio.submitFailed.store(true, std::memory_order_relaxed);
                return;
            }
            audio.renderedFrames.fetch_add(count, std::memory_order_relaxed);
            frames -= count;
        }
    }

    bool select(unsigned track) {
        if (track == currentTrack)
            return true;
        const auto file = track == 9 ? "Mod_Menu.flac" : "Mod_Game" + std::to_string(track) + ".flac";
        const bool available = !track || std::filesystem::is_regular_file(assetRoot / file);
        Music replacement{};
        if (track && available) {
            if (track == 9) {
                for (unsigned voice = 1; voice <= 4; ++voice) {
                    const auto name = "Mod_Menu_Voice" + std::to_string(voice) + ".flac";
                    replacement.stems.push_back(loadAudioClip(assetRoot / name, AudioContainer::Flac));
                }
            } else {
                replacement.stems.push_back(loadAudioClip(assetRoot / file, AudioContainer::Flac));
            }
            replacement.loopEnd = replacement.stems.front().frames();
            replacement.volume = 35.f / 64;
            for (const auto& clip : replacement.stems)
                if (clip.frames() != replacement.loopEnd || clip.rate != replacement.stems.front().rate)
                    throw std::runtime_error("menu voices have different durations");
        }
        Mixer replacementMixer(track && available ? 1 : 4);
        const AudioLock lock(stream.get());
        currentTrack = available ? track : 0;
        mixer = std::move(replacementMixer);
        std::swap(music, replacement);
        activeMixer = &mixer;
        if (currentTrack)
            mixer.play(music);
        mixer.setMusicVolume(musicVolume / 64.f);
        return available;
    }
};

SoundOutput::SoundOutput(const std::filesystem::path& root, unsigned track, bool smoke)
    : playback_(std::make_unique<Playback>(root, track, smoke)) {}

SoundOutput::~SoundOutput() = default;

bool SoundOutput::selectTrack(unsigned track) {
    return playback_->select(track);
}

void SoundOutput::verifyWithoutGameTicks() const {
    const auto before = playback_->renderedFrames.load(std::memory_order_relaxed);
    const auto deadline = SDL_GetTicks() + 1000;
    while (playback_->renderedFrames.load(std::memory_order_relaxed) - before < Mixer::Rate / 5 &&
           SDL_GetTicks() < deadline)
        SDL_Delay(10);
    if (playback_->renderedFrames.load(std::memory_order_relaxed) - before < Mixer::Rate / 5 ||
        playback_->submitFailed.load(std::memory_order_relaxed))
        throw std::runtime_error("audio stopped without game ticks");
}

void SoundOutput::setVolumes(unsigned music, unsigned effects) {
    auto& output = *playback_;
    const AudioLock lock(output.stream.get());
    output.musicVolume = std::min(music, 64u);
    output.effectsVolume = std::min(effects, 64u);
    output.mixer.setMusicVolume(output.musicVolume / 64.f);
    for (auto& effect : output.effects)
        effect.volume = output.effectsVolume / 128.f;
}

void SoundOutput::setMenuVoices(unsigned count) {
    auto& output = *playback_;
    const AudioLock lock(output.stream.get());
    if (output.currentTrack == 9)
        for (unsigned i = 0; i < output.music.stems.size(); ++i)
            output.mixer.enableStem(i, i < count);
}

void SoundOutput::tick(std::span<const SoundRequest> requests, bool paused, bool results, bool podium) {
    auto& output = *playback_;
    if (!output.stream)
        return;
    const AudioLock lock(output.stream.get());
    auto& mixer = podium ? output.podiumMixer : output.mixer;
    output.activeMixer = &mixer;
    for (const auto& request : requests) {
        auto& effect = output.effects.at(static_cast<unsigned>(request.cue));
        effect.priority = request.priority;
        mixer.play(effect, request.repetitions);
    }
    mixer.setMusicVolume((paused ? std::min(output.musicVolume, 5u) :
                          results ? std::min(output.musicVolume, 20u) : output.musicVolume) / 64.f);
}
}

#include "audio_io.hpp"

#include <SDL3/SDL.h>

#define DR_FLAC_NO_OGG
#define DR_FLAC_IMPLEMENTATION
#include <dr_flac.h>

#include <bit>
#include <memory>
#include <stdexcept>

namespace {
AudioClip allocate(unsigned rate, unsigned channels, std::uint64_t frames) {
    if (!rate || rate > 192000 || (channels != 1 && channels != 2) ||
        !frames || frames > 32'000'000 / channels)
        throw std::runtime_error("unsupported audio rate, channels or length");
    return {rate, channels, std::vector<float>(static_cast<std::size_t>(frames * channels))};
}
}

AudioClip loadAudioClip(const std::filesystem::path& path, AudioContainer container) {
    if (container == AudioContainer::Flac) {
        std::unique_ptr<drflac, decltype(&drflac_close)> file(drflac_open_file(path.c_str(), nullptr), drflac_close);
        if (!file)
            throw std::runtime_error(path.string() + ": invalid FLAC");
        auto clip = allocate(file->sampleRate, file->channels, file->totalPCMFrameCount);
        if (drflac_read_pcm_frames_f32(file.get(), clip.frames(), clip.samples.data()) != clip.frames())
            throw std::runtime_error(path.string() + ": truncated FLAC");
        return clip;
    }

    SDL_AudioSpec spec{};
    Uint8* data{};
    Uint32 bytes{};
    if (!SDL_LoadWAV(path.c_str(), &spec, &data, &bytes))
        throw std::runtime_error(path.string() + ": " + SDL_GetError());
    std::unique_ptr<Uint8, decltype(&SDL_free)> samples(data, SDL_free);
    if (spec.format != SDL_AUDIO_S16LE || (spec.channels != 1 && spec.channels != 2) ||
        bytes % (2 * spec.channels))
        throw std::runtime_error(path.string() + ": expected 16-bit PCM WAV");
    auto clip = allocate(spec.freq, spec.channels, bytes / (2 * spec.channels));
    for (std::size_t i = 0; i < clip.samples.size(); ++i) {
        const auto word = static_cast<std::uint16_t>(data[2 * i] | (data[2 * i + 1] << 8));
        clip.samples[i] = std::bit_cast<std::int16_t>(word) / 32768.f;
    }
    return clip;
}

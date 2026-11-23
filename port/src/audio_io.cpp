#include "audio_io.hpp"

#include <sndfile.h>

#include <memory>
#include <stdexcept>

AudioClip loadAudioClip(const std::filesystem::path& path, AudioContainer type) {
    const auto container = type == AudioContainer::Wav ? SF_FORMAT_WAV : SF_FORMAT_FLAC;
    SF_INFO info{};
#ifdef _WIN32
    auto* file = sf_wchar_open(path.c_str(), SFM_READ, &info);
#else
    auto* file = sf_open(path.c_str(), SFM_READ, &info);
#endif
    std::unique_ptr<SNDFILE, decltype(&sf_close)> input(file, sf_close);
    if (!input)
        throw std::runtime_error(path.string() + ": " + sf_strerror(nullptr));
    if ((info.format & SF_FORMAT_TYPEMASK) != container)
        throw std::runtime_error("audio container differs from manifest");
    if (container == SF_FORMAT_WAV && (info.format & SF_FORMAT_SUBMASK) != SF_FORMAT_PCM_16)
        throw std::runtime_error("expected 16-bit PCM WAV");
    if (info.samplerate <= 0 || info.samplerate > 192000 ||
        (info.channels != 1 && info.channels != 2) ||
        info.frames <= 0 || info.frames > 32'000'000 / info.channels)
        throw std::runtime_error("unsupported audio rate, channels or length");
    AudioClip clip{static_cast<unsigned>(info.samplerate), static_cast<unsigned>(info.channels),
                   std::vector<float>(static_cast<std::size_t>(info.frames) * info.channels)};
    if (sf_readf_float(input.get(), clip.samples.data(), info.frames) != info.frames)
        throw std::runtime_error("truncated audio");
    return clip;
}

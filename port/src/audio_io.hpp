#pragma once

#include "assets.hpp"

enum class AudioContainer { Wav, Flac };
AudioClip loadAudioClip(const std::filesystem::path& path, AudioContainer container);

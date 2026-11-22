#include "assets.hpp"
#include "audio_io.hpp"

#include <nlohmann/json.hpp>
#include <png.h>
#include <sndfile.h>

#include <algorithm>
#include <array>
#include <fstream>
#include <memory>
#include <stdexcept>

namespace {
using Json = nlohmann::json;
using Path = std::filesystem::path;

void require(bool condition, const char* message) {
    if (!condition)
        throw std::runtime_error(message);
}

Path file(const Path& package, const std::string& name, const std::string& extension) {
    const Path path(name);
    require(path == path.filename() && path.extension() == extension,
            "invalid package filename");
    return package / path;
}

ImagePixels png(const Path& path, bool indexed, bool mask = false) {
    png_image reader{};
    reader.version = PNG_IMAGE_VERSION;
    struct Cleanup {
        png_image& reader;
        ~Cleanup() { png_image_free(&reader); }
    } cleanup{reader};

    const auto filename = path.string();
    if (!png_image_begin_read_from_file(&reader, filename.c_str()))
        throw std::runtime_error(filename + ": " + reader.message);
    require(reader.width <= 8192 && reader.height <= 8192, "PNG exceeds image size limit");
    if (indexed)
        require((reader.format & PNG_FORMAT_FLAG_COLORMAP) != 0, "palette cycle requires indexed PNG");
    reader.format = indexed ? PNG_FORMAT_RGBA_COLORMAP : mask ? PNG_FORMAT_GRAY : PNG_FORMAT_RGBA;
    ImagePixels image{{static_cast<int>(reader.width), static_cast<int>(reader.height)},
                      std::vector<std::uint8_t>(PNG_IMAGE_SIZE(reader)), {}, {}};
    if (indexed)
        image.palette.resize(PNG_IMAGE_COLORMAP_SIZE(reader));
    if (!png_image_finish_read(&reader, nullptr, image.pixels.data(), 0,
                               indexed ? image.palette.data() : nullptr))
        throw std::runtime_error(filename + ": " + reader.message);
    if (indexed)
        image.palette.resize(reader.colormap_entries * 4);
    return image;
}

Size dimensions(const Json& values) {
    const auto pair = values.get<std::array<int, 2>>();
    require(pair[0] > 0 && pair[0] <= 8192 && pair[1] > 0 && pair[1] <= 8192,
            "invalid image dimensions");
    return {pair[0], pair[1]};
}

float volume(const Json& entry) {
    const float value = entry.value("volume", 1.0f);
    require(value >= 0 && value <= 1, "volume must be between 0 and 1");
    return value;
}

ImageAsset loadImage(const Path& package, const Json& entry) {
    const auto logical = dimensions(entry.at("logical_size"));
    const auto pixels = dimensions(entry.at("pixel_size"));
    const auto anchor = entry.value("anchor", std::array<int, 2>{0, 0});
    const auto grid = dimensions(entry.value("grid", Json::array({1, 1})));
    const int frameTicks = entry.value("frame_ticks", 1);
    require(pixels.w % grid.w == 0 && pixels.h % grid.h == 0 && frameTicks > 0,
            "invalid frame grid or duration");
    ImageAsset asset{logical, {anchor[0], anchor[1]}, static_cast<unsigned>(grid.w),
                     static_cast<unsigned>(grid.h), static_cast<unsigned>(frameTicks), {}, {}};
    for (const auto& cycle : entry.value("cycles", Json::array())) {
        const int first = cycle.at("first").get<int>();
        const int last = cycle.at("last").get<int>();
        const int ticks = cycle.at("ticks").get<int>();
        const int direction = cycle.value("direction", 1);
        require(first >= 0 && last > first && last < 256 && ticks > 0 &&
                (direction == 1 || direction == -1), "invalid palette cycle");
        for (const auto& other : asset.cycles)
            require(first > static_cast<int>(other.last) || last < static_cast<int>(other.first),
                    "overlapping palette cycles");
        asset.cycles.push_back({static_cast<unsigned>(first), static_cast<unsigned>(last),
                                static_cast<unsigned>(ticks), direction});
    }
    for (const auto& [tier, variant] : entry.at("variants").items()) {
        require(tier.size() == 1 && tier[0] >= '1' && tier[0] <= '4', "invalid image tier");
        const int scale = tier[0] - '0';
        auto image = png(file(package, variant.at("image"), ".png"), !asset.cycles.empty());
        require(image.size.w == pixels.w * scale && image.size.h == pixels.h * scale,
                "image size differs from manifest");
        for (const auto& cycle : asset.cycles)
            require(cycle.last < image.palette.size() / 4, "cycle exceeds image palette");
        if (variant.contains("mask")) {
            auto opacity = png(file(package, variant.at("mask"), ".png"), false, true);
            require(opacity.size.w == image.size.w && opacity.size.h == image.size.h,
                    "mask size differs from image");
            image.mask = std::move(opacity.pixels);
        }
        asset.variants.emplace(scale, std::move(image));
    }
    require(asset.variants.contains(1), "missing base image tier");
    return asset;
}

template<class Loader>
void readGroup(const Json& manifest, const std::string& group, Loader load) {
    const auto& entries = manifest.at(group);
    require(entries.is_object(), "resource group must be an object");
    for (const auto& [id, entry] : entries.items()) {
        try {
            load(id, entry);
        } catch (const std::exception& error) {
            throw std::runtime_error(group + "/" + id + " " + entry.dump() + ": " + error.what());
        }
    }
}
}

Assets loadAssets(const std::filesystem::path& package) {
    const auto manifestPath = package / "manifest.json";
    std::ifstream input(manifestPath);
    if (!input)
        throw std::runtime_error("cannot open " + manifestPath.string());
    const auto manifest = Json::parse(input);
    require(manifest.at("version") == 1, "unsupported manifest version");

    Assets result;
    readGroup(manifest, "images", [&](const auto& id, const auto& entry) {
        result.images.emplace(id, loadImage(package, entry));
    });
    readGroup(manifest, "sounds", [&](const auto& id, const auto& entry) {
        result.sounds.emplace(id, Sound{loadAudioClip(file(package, entry.at("file"), ".wav"), SF_FORMAT_WAV),
                                       entry.value("priority", 0), volume(entry)});
    });
    readGroup(manifest, "music", [&](const auto& id, const auto& entry) {
        Music music{{}, 0, 0, volume(entry)};
        const auto& filenames = entry.at("files");
        require(filenames.is_array() && !filenames.empty() && filenames.size() <= 32,
                "expected 1 to 32 music stems");
        for (const auto& name : filenames)
            music.stems.push_back(loadAudioClip(file(package, name, ".flac"), SF_FORMAT_FLAC));
        const auto& first = music.stems.front();
        for (const auto& clip : music.stems)
            require(clip.rate == first.rate && clip.frames() == first.frames(),
                    "music stems must have the same rate and frame count");
        const auto loop = entry.value("loop", std::array<std::size_t, 2>{0, first.frames()});
        require(loop[0] < loop[1] && loop[1] <= first.frames(), "invalid music loop");
        music.loopStart = loop[0];
        music.loopEnd = loop[1];
        result.music.emplace(id, std::move(music));
    });
    return result;
}

int ImageAsset::tier(double scale) const {
    for (auto it = variants.rbegin(); it != variants.rend(); ++it)
        if (it->first <= scale)
            return it->first;
    return 1;
}

std::vector<std::uint8_t> ImagePixels::rgba(std::uint64_t tick,
                                             const std::vector<PaletteCycle>& cycles) const {
    if (palette.empty() && mask.empty())
        return pixels;

    auto colors = palette;
    for (const auto& cycle : cycles) {
        const unsigned span = cycle.last - cycle.first + 1;
        unsigned shift = (tick / cycle.ticks) % span;
        if (cycle.direction > 0)
            shift = (span - shift) % span;
        const auto begin = colors.begin() + cycle.first * 4;
        std::rotate(begin, begin + shift * 4, begin + span * 4);
    }
    const auto count = static_cast<std::size_t>(size.w) * size.h;
    std::vector<std::uint8_t> result = colors.empty() ? pixels : std::vector<std::uint8_t>(count * 4);
    for (std::size_t i = 0; i < count; ++i) {
        if (!colors.empty()) {
            const auto index = static_cast<std::size_t>(pixels[i]) * 4;
            if (index + 4 > colors.size())
                throw std::runtime_error("PNG pixel exceeds palette");
            std::copy_n(colors.data() + index, 3, result.data() + i * 4);
            result[i * 4 + 3] = palette[index + 3];
        }
        if (!mask.empty())
            result[i * 4 + 3] = static_cast<unsigned>(result[i * 4 + 3]) * mask[i] / 255;
    }
    return result;
}

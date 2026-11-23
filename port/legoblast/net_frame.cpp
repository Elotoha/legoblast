#include "netplay.hpp"

#include <algorithm>

namespace legoblast {
namespace {
constexpr std::array<std::uint8_t, 4> Magic{'L', 'B', 1, 0};

void putNumber(Bytes& blob, std::uint32_t number) {
    for (int shift = 0; shift < 32; shift += 8)
        blob.push_back(static_cast<std::uint8_t>(number >> shift));
}

std::uint32_t numberAt(std::span<const std::uint8_t> blob, std::size_t offset) {
    std::uint32_t number = 0;
    for (int i = 0; i < 4; ++i)
        number |= std::uint32_t(blob[offset + i]) << (8 * i);
    return number;
}

// Each token describes a run of up to 128 unchanged bytes, or up to
// 128 literal bytes. A keyframe uses a zero reference of the same size.
void pack(Bytes& packet, std::span<const std::uint8_t> current, std::span<const std::uint8_t> previous) {
    const auto diff = [&](std::size_t i) {
        return static_cast<std::uint8_t>(current[i] ^ (previous.empty() ? 0 : previous[i]));
    };
    for (std::size_t i = 0; i < current.size();) {
        const bool skip = diff(i) == 0;
        const auto token = packet.size();
        packet.push_back(0);
        std::size_t count = 0;
        while (i < current.size() && count < 128 && ((diff(i) == 0) == skip)) {
            if (!skip) packet.push_back(diff(i));
            ++i;
            ++count;
        }
        packet[token] = static_cast<std::uint8_t>((skip ? 128 : 0) | (count - 1));
    }
}
}

unsigned packInput(Buttons b) {
    return unsigned(b.left) | unsigned(b.right) << 1 | unsigned(b.up) << 2 |
           unsigned(b.down) << 3 | unsigned(b.fire) << 4;
}

Buttons unpackInput(unsigned bits) {
    return {bool(bits & 1), bool(bits & 2), bool(bits & 4), bool(bits & 8), bool(bits & 16)};
}

Bytes FrameWriter::encode(const NetFrame& frame, bool full) {
    if (frame.pixels.size() != NetPixels) return {};
    full |= previous_.empty();
    Bytes packet(Magic.begin(), Magic.end());
    putNumber(packet, ++sequence_);
    putNumber(packet, full ? 0 : sequence_ - 1);
    putNumber(packet, frame.trackRevision);
    putNumber(packet, frame.musicMs);
    packet.push_back(static_cast<std::uint8_t>(frame.track));
    packet.push_back(static_cast<std::uint8_t>(frame.flags));
    const auto text = std::min<std::size_t>(frame.status.size(), 39);
    const auto sounds = std::min<std::size_t>(frame.sounds.size(), 32);
    packet.push_back(static_cast<std::uint8_t>(text));
    packet.push_back(static_cast<std::uint8_t>(sounds));
    packet.insert(packet.end(), frame.status.begin(), frame.status.begin() + text);
    for (std::size_t i = 0; i < sounds; ++i) {
        const auto& effect = frame.sounds[i];
        packet.push_back(static_cast<std::uint8_t>(effect.cue));
        packet.push_back(static_cast<std::uint8_t>(std::clamp(effect.priority, -64, 63) + 64));
        packet.push_back(static_cast<std::uint8_t>(std::min(effect.repetitions, 32u)));
    }
    const auto pixelsAt = packet.size();
    pack(packet, frame.pixels, full ? std::span<const std::uint8_t>{} : std::span<const std::uint8_t>(previous_));
    if (packet.size() - pixelsAt >= NetPixels) {
        packet[3] = 1;
        std::fill(packet.begin() + 8, packet.begin() + 12, 0);
        packet.resize(pixelsAt);
        packet.insert(packet.end(), frame.pixels.begin(), frame.pixels.end());
    }
    previous_ = frame.pixels;
    return packet;
}

bool FrameReader::decode(std::span<const std::uint8_t> packet) {
    if (packet.size() < 24 || !std::ranges::equal(std::span(Magic).first(3), packet.first(3)) || packet[3] > 1) return false;
    const auto seq = numberAt(packet, 4);
    const auto base = numberAt(packet, 8);
    if (seq <= sequence_ || (base && (base != sequence_ || frame_.pixels.empty()))) return false;
    NetFrame next;
    next.trackRevision = numberAt(packet, 12);
    next.musicMs = numberAt(packet, 16);
    next.track = packet[20];
    next.flags = packet[21];
    const auto text = packet[22], sounds = packet[23];
    if (next.track > 7 || next.flags > 15 || text > 39 || sounds > 32 || packet.size() < 24u + text + sounds * 3u)
        return false;
    next.status.assign(packet.begin() + 24, packet.begin() + 24 + text);
    std::size_t at = 24 + text;
    for (unsigned i = 0; i < sounds; ++i) {
        if (packet[at] >= static_cast<unsigned>(SoundCue::Count) || packet[at + 1] > 127 || packet[at + 2] > 32)
            return false;
        next.sounds.push_back({static_cast<SoundCue>(packet[at]), int(packet[at + 1]) - 64, packet[at + 2]});
        at += 3;
    }
    next.pixels = base ? frame_.pixels : Bytes(NetPixels);
    std::size_t written = 0;
    if (packet[3]) {
        if (base || packet.size() - at != NetPixels) return false;
        std::ranges::copy(packet.subspan(at), next.pixels.begin());
        written = NetPixels;
        at = packet.size();
    }
    while (at < packet.size()) {
        const auto token = packet[at++];
        const std::size_t count = (token & 127u) + 1;
        if (written + count > NetPixels) return false;
        if (!(token & 128)) {
            if (at + count > packet.size()) return false;
            for (std::size_t i = 0; i < count; ++i) next.pixels[written + i] ^= packet[at + i];
            at += count;
        }
        written += count;
    }
    if (written != NetPixels) return false;
    if (pending_.size() + next.sounds.size() <= 96)
        pending_.insert(pending_.end(), next.sounds.begin(), next.sounds.end());
    frame_ = std::move(next);
    sequence_ = seq;
    return true;
}

std::vector<SoundRequest> FrameReader::takeSounds() {
    auto result = std::move(pending_);
    pending_.clear();
    return result;
}

}

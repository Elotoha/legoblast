#include "netplay.hpp"

#include <iostream>
#include <stdexcept>

using namespace legoblast;

namespace {
void check(bool ok, const char* message) {
    if (!ok) throw std::runtime_error(message);
}

void frameCodec() {
    FrameWriter writer;
    FrameReader reader;
    NetFrame first;
    first.pixels.resize(NetPixels);
    for (std::size_t i = 0; i < NetPixels; ++i)
        first.pixels[i] = i % 2 ? 180 : 0;
    first.track = 2;
    first.trackRevision = 3;
    first.musicMs = 1982;
    first.flags = 1;
    first.status = "MUSIC 2";
    const auto keyframe = writer.encode(first, false);
    check(!keyframe.empty() && keyframe.size() <= 300000, "keyframe exceeds the relay limit");
    check(reader.decode(keyframe) && reader.image().pixels == first.pixels, "keyframe payload");
    check(reader.image().track == 2 && reader.image().trackRevision == 3 &&
          reader.image().musicMs == 1982 && reader.image().status == "MUSIC 2", "music synchronization fields");

    auto second = first;
    second.pixels[8314] = 21;
    second.sounds.push_back({SoundCue::Explosion, -2});
    const auto delta = writer.encode(second, false);
    check(delta.size() < 3000, "a small screen change should be a small packet");
    check(!reader.decode(std::span(delta).first(delta.size() - 1)), "truncated delta accepted");
    check(reader.image().pixels == first.pixels && reader.takeSounds().empty(), "invalid frame changed state");
    check(reader.decode(delta) && reader.image().pixels == second.pixels, "delta payload");
    check(!reader.decode(delta) && reader.takeSounds().size() == 1, "duplicate effect replayed");

    FrameReader joining;
    check(!joining.decode(delta), "delta accepted without its reference");
    check(joining.decode(writer.encode(second, true)) && joining.image().pixels == second.pixels,
          "reconnecting guest did not get a complete image");
    for (unsigned bits = 0; bits < 32; ++bits)
        check(packInput(unpackInput(bits)) == bits, "input round trip");
}
}

int main() {
    try {
        frameCodec();
    } catch (const std::exception& error) {
        std::cerr << error.what() << '\n';
        return 1;
    }
}

#pragma once

#include "net_socket.hpp"
#include "players.hpp"

#include <deque>

namespace legoblast {
inline constexpr int NetWidth = 320, NetHeight = 258;
inline constexpr std::size_t NetPixels = NetWidth * NetHeight * 3;
inline constexpr std::size_t NetworkPlaces = 4;

unsigned packInput(Buttons input);
Buttons unpackInput(unsigned bits);

struct NetFrame {
    Bytes pixels;
    std::vector<SoundRequest> sounds;
    std::string status;
    unsigned flags{}; // pause, results, podium, statistics
    unsigned track{};
    std::uint32_t trackRevision{}, musicMs{};
};

class FrameWriter {
public:
    Bytes encode(const NetFrame& frame, bool full);
    void reset() { previous_.clear(); sequence_ = 0; }
private:
    Bytes previous_;
    std::uint32_t sequence_{};
};

class FrameReader {
public:
    bool decode(std::span<const std::uint8_t> blob);
    const NetFrame& image() const { return frame_; }
    std::vector<SoundRequest> takeSounds();
    void reset() { frame_ = {}; sequence_ = 0; pending_.clear(); }
private:
    NetFrame frame_;
    std::uint32_t sequence_{};
    std::vector<SoundRequest> pending_;
};

struct NetRoom {
    std::string code, roster;
    unsigned seat{};
    bool host{}, started{};
};

class Network {
public:
    explicit Network(std::string url);
    void enable(bool active);
    void poll(std::uint64_t now);
    bool send(std::string_view command);
    bool sendFrame(const NetFrame& frame);
    void sendInput(Buttons input);
    void leave();
    void beginMatch();
    void decline();
    Controls humanInputs(Buttons local);
    std::deque<std::string> commands;

    bool enabled{};
    bool connected{};
    std::optional<NetRoom> room;
    std::string offer, notice;
    FrameReader frames;

private:
    void message(std::string_view text);
    void disconnected(std::uint64_t now);
    std::string url_, key_;
    std::unique_ptr<NetSocket> socket_;
    std::uint64_t retryAt_{}, now_{}, lastInputAt_{};
    std::array<unsigned, NetworkPlaces> input_{};
    std::array<std::uint64_t, NetworkPlaces> inputExpires_{};
    std::array<bool, NetworkPlaces> fireEdge_{};
    int lastInput_{-1};
    unsigned framesSent_{};
    bool fullFrame_{true}, leaving_{};
    FrameWriter writer_;
};
}

#include "netplay.hpp"

#include <sstream>

namespace legoblast {
Network::Network(std::string url) : url_(std::move(url)) {}

void Network::enable(bool active) {
    if (active == enabled) return;
    if (!active && room) leave();
    enabled = active;
    if (active) {
        retryAt_ = 0;
        notice = "CONNEXION...";
    } else if (!leaving_) {
        socket_.reset();
        connected = false;
        offer.clear();
        notice.clear();
    }
}

bool Network::send(std::string_view command) {
    return socket_ && socket_->send({reinterpret_cast<const std::uint8_t*>(command.data()), command.size()}, false);
}

void Network::disconnected(std::uint64_t now) {
    socket_.reset();
    connected = false;
    retryAt_ = now + 2500;
    input_ = {};
    fireEdge_ = {};
    lastInput_ = -1;
    fullFrame_ = true;
    offer.clear();
    notice = "RECONNEXION...";
}

void Network::poll(std::uint64_t now) {
    now_ = now;
    if (!socket_ && (enabled || leaving_) && now >= retryAt_)
        socket_ = connectSocket(url_);
    for (unsigned i = 0; socket_ && i < 64; ++i) {
        const auto next = socket_->receive();
        if (!next) return;
        switch (next->event) {
        case NetEvent::Open:
            send("HELLO " + (key_.empty() ? "-" : key_));
            break;
        case NetEvent::Text:
            message(std::string_view(reinterpret_cast<const char*>(next->data.data()), next->data.size()));
            break;
        case NetEvent::Binary:
            if (room && room->started && !room->host) frames.decode(next->data);
            break;
        case NetEvent::Closed:
            disconnected(now);
            break;
        }
    }
}

void Network::message(std::string_view text) {
    if (text.size() > 160) return;
    std::istringstream message{std::string(text)};
    std::string cmd, arg;
    message >> cmd >> arg;
    if (cmd == "HELLO" && arg.size() == 36) {
        key_ = arg;
        connected = true;
        lastInput_ = -1;
        notice.clear();
    } else if (cmd == "LOBBY") {
        room.reset();
        frames.reset();
        leaving_ = false;
    } else if (cmd == "INVITE" && !room && arg.size() == 6) {
        if (offer != arg) offer = arg;
    } else if (cmd == "CANCEL") {
        if (offer == arg) offer.clear();
    } else if (cmd == "ROOM") {
        NetRoom next;
        next.code = arg;
        unsigned host{}, started{};
        if (!(message >> host >> next.seat >> next.roster >> started) || next.seat >= next.roster.size() ||
            next.roster.size() > NetworkPlaces || next.roster[next.seat] != 'H' || (started && next.roster.size() != NetworkPlaces))
            return;
        next.host = host != 0;
        next.started = started != 0;
        room = std::move(next);
        offer.clear();
        notice.clear();
        if (leaving_) send("LEAVE");
    } else if (cmd == "RESET") {
        fullFrame_ = true;
    } else if (cmd == "END") {
        room.reset();
        frames.reset();
        leaving_ = false;
        notice = std::string(text.substr(4));
        if (!enabled) {
            socket_.reset();
            connected = false;
        }
    } else if (cmd == "ERROR") {
        notice = std::string(text.substr(6));
        offer.clear();
    } else if (cmd == "I" && room && room->host) {
        unsigned seat{}, bits{};
        std::istringstream values{std::string(text.substr(2))};
        if (values >> seat >> bits && seat < NetworkPlaces && bits < 32) {
            fireEdge_[seat] |= (bits & 16) && !(input_[seat] & 16);
            input_[seat] = bits;
            inputExpires_[seat] = now_ + 1200;
        }
    } else if (cmd == "C" && room && room->host && commands.size() < 32) {
        commands.push_back(arg);
    }
}

void Network::beginMatch() {
    writer_.reset();
    framesSent_ = 0;
    fullFrame_ = true;
    input_ = {};
    fireEdge_ = {};
    lastInput_ = -1;
    commands.clear();
}

bool Network::sendFrame(const NetFrame& frame) {
    if (!connected || !socket_) return false;
    const auto packet = writer_.encode(frame, fullFrame_ || framesSent_++ % 60 == 0);
    fullFrame_ = !socket_->send(packet, true);
    return !fullFrame_;
}

void Network::sendInput(Buttons input) {
    const auto bits = static_cast<int>(packInput(input));
    if (connected && (bits != lastInput_ || now_ - lastInputAt_ >= 400) && send("I " + std::to_string(bits))) {
        lastInput_ = bits;
        lastInputAt_ = now_;
    }
}

Controls Network::humanInputs(Buttons local) {
    Controls input{};
    if (!room || !room->host) return input;
    for (std::size_t i = 0; i < NetworkPlaces; ++i) {
        input[i] = i == room->seat ? local : (now_ < inputExpires_[i] ? unpackInput(input_[i]) : Buttons{});
        input[i].fire |= fireEdge_[i];
        fireEdge_[i] = false;
    }
    return input;
}

void Network::decline() { offer.clear(); }

void Network::leave() {
    if (!room) return;
    leaving_ = true;
    if (connected) send("LEAVE");
    room.reset();
    frames.reset();
}
}

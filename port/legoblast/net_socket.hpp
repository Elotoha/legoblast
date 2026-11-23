#pragma once

#include "level.hpp"

#include <memory>
#include <optional>
#include <string>

namespace legoblast {
enum class NetEvent { Open, Text, Binary, Closed };
struct NetMessage {
    NetEvent event;
    Bytes data;
};

class NetSocket {
public:
    virtual ~NetSocket() = default;
    virtual bool send(std::span<const std::uint8_t> data, bool binary) = 0;
    virtual std::optional<NetMessage> receive() = 0;
};

std::unique_ptr<NetSocket> connectSocket(const std::string& url);
}

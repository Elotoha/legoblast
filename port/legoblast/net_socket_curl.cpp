#include "net_socket.hpp"

#include <curl/curl.h>

#include <chrono>
#include <deque>
#include <mutex>
#include <thread>

namespace legoblast {
namespace {
constexpr std::size_t Limit = 1'500'000;
struct Packet { Bytes data; bool binary; };

class CurlSocket final : public NetSocket {
public:
    explicit CurlSocket(const std::string& url) : worker_([this, url](std::stop_token stop) { run(url, stop); }) {}

    bool send(std::span<const std::uint8_t> data, bool binary) override {
        std::lock_guard lock(mutex_);
        if (closed_ || outgoingBytes_ + data.size() > Limit)
            return false;
        outgoingBytes_ += data.size();
        outgoing_.push_back({Bytes(data.begin(), data.end()), binary});
        return true;
    }

    std::optional<NetMessage> receive() override {
        std::lock_guard lock(mutex_);
        if (incoming_.empty()) return std::nullopt;
        auto message = std::move(incoming_.front());
        incomingBytes_ -= message.data.size();
        incoming_.pop_front();
        return message;
    }

private:
    bool push(NetMessage message) {
        std::lock_guard lock(mutex_);
        if (incomingBytes_ + message.data.size() > Limit) return false;
        incomingBytes_ += message.data.size();
        incoming_.push_back(std::move(message));
        return true;
    }

    static int interrupt(void* context, curl_off_t, curl_off_t, curl_off_t, curl_off_t) {
        return static_cast<std::stop_token*>(context)->stop_requested();
    }

    void run(const std::string& url, std::stop_token stop) {
        static const auto initialized = curl_global_init(CURL_GLOBAL_DEFAULT);
        std::unique_ptr<CURL, decltype(&curl_easy_cleanup)> curl(
            initialized == CURLE_OK ? curl_easy_init() : nullptr, curl_easy_cleanup);
        if (curl) {
            curl_easy_setopt(curl.get(), CURLOPT_URL, url.c_str());
            curl_easy_setopt(curl.get(), CURLOPT_CONNECT_ONLY, 2L);
            curl_easy_setopt(curl.get(), CURLOPT_CONNECTTIMEOUT_MS, 4000L);
            curl_easy_setopt(curl.get(), CURLOPT_TIMEOUT_MS, 6000L);
            curl_easy_setopt(curl.get(), CURLOPT_NOSIGNAL, 1L);
            curl_easy_setopt(curl.get(), CURLOPT_NOPROGRESS, 0L);
            curl_easy_setopt(curl.get(), CURLOPT_XFERINFOFUNCTION, &interrupt);
            curl_easy_setopt(curl.get(), CURLOPT_XFERINFODATA, &stop);
            if (curl_easy_perform(curl.get()) == CURLE_OK) {
                push({NetEvent::Open, {}});
                transfer(curl.get(), stop);
            }
        }
        std::lock_guard lock(mutex_);
        closed_ = true;
        incoming_.push_back({NetEvent::Closed, {}});
    }

    void transfer(CURL* curl, std::stop_token stop) {
        Packet sending{};
        std::size_t sent = 0;
        Bytes receiving;
        bool binary = false;
        while (!stop.stop_requested()) {
            if (sending.data.empty()) {
                std::lock_guard lock(mutex_);
                if (!outgoing_.empty()) {
                    sending = std::move(outgoing_.front());
                    outgoingBytes_ -= sending.data.size();
                    outgoing_.pop_front();
                    sent = 0;
                }
            }
            if (!sending.data.empty()) {
                std::size_t amount{};
                const auto flags = CURLWS_OFFSET | (sent == 0 ? (sending.binary ? CURLWS_BINARY : CURLWS_TEXT) : 0);
                const auto result = curl_ws_send(curl, sending.data.data() + sent, sending.data.size() - sent,
                    &amount, sent == 0 ? static_cast<curl_off_t>(sending.data.size()) : 0, flags);
                if (result != CURLE_OK && result != CURLE_AGAIN) return;
                sent += amount;
                if (sent == sending.data.size()) sending.data.clear();
            }
            std::array<std::uint8_t, 16384> buffer{};
            for (unsigned i = 0; i < 32; ++i) {
                const curl_ws_frame* meta = nullptr;
                std::size_t size = 0;
                const auto result = curl_ws_recv(curl, buffer.data(), buffer.size(), &size, &meta);
                if (result == CURLE_AGAIN) break;
                if (result != CURLE_OK || !meta || (meta->flags & CURLWS_CLOSE)) return;
                if (meta->flags & (CURLWS_PING | CURLWS_PONG)) continue;
                if (receiving.empty()) binary = (meta->flags & CURLWS_BINARY) != 0;
                if (receiving.size() + size > 300000) return;
                receiving.insert(receiving.end(), buffer.begin(), buffer.begin() + size);
                if (!meta->bytesleft && !(meta->flags & CURLWS_CONT)) {
                    if (!push({binary ? NetEvent::Binary : NetEvent::Text, std::move(receiving)})) return;
                    receiving.clear();
                }
            }
            std::this_thread::sleep_for(std::chrono::milliseconds(2));
        }
    }

    std::mutex mutex_;
    std::deque<NetMessage> incoming_;
    std::deque<Packet> outgoing_;
    std::size_t incomingBytes_{}, outgoingBytes_{};
    bool closed_{};
    std::jthread worker_;
};
}

std::unique_ptr<NetSocket> connectSocket(const std::string& url) {
    return std::make_unique<CurlSocket>(url);
}
}

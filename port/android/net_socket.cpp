#include "net_socket.hpp"

#include <SDL3/SDL.h>
#include <jni.h>

namespace legoblast {
namespace {
class AndroidSocket final : public NetSocket {
public:
    explicit AndroidSocket(const std::string& url) {
        env_ = static_cast<JNIEnv*>(SDL_GetAndroidJNIEnv());
        if (!env_) return;
        auto activity = static_cast<jobject>(SDL_GetAndroidActivity());
        if (!activity) return;
        auto activityClass = env_->GetObjectClass(activity);
        auto factory = env_->GetMethodID(activityClass, "openGameSocket", "(Ljava/lang/String;)Lorg/legoblast/game/GameSocket;");
        auto address = env_->NewStringUTF(url.c_str());
        auto socket = factory ? env_->CallObjectMethod(activity, factory, address) : nullptr;
        if (env_->ExceptionCheck()) {
            env_->ExceptionClear();
            socket = nullptr;
        }
        env_->DeleteLocalRef(address);
        env_->DeleteLocalRef(activityClass);
        env_->DeleteLocalRef(activity);
        if (!socket) return;
        socket_ = env_->NewGlobalRef(socket);
        auto type = env_->GetObjectClass(socket);
        send_ = env_->GetMethodID(type, "sendMessage", "([BZ)Z");
        next_ = env_->GetMethodID(type, "nextMessage", "()[B");
        close_ = env_->GetMethodID(type, "stop", "()V");
        env_->DeleteLocalRef(type);
        env_->DeleteLocalRef(socket);
    }

    ~AndroidSocket() override {
        if (socket_) {
            env_->CallVoidMethod(socket_, close_);
            env_->DeleteGlobalRef(socket_);
        }
    }

    bool send(std::span<const std::uint8_t> data, bool binary) override {
        if (!socket_) return false;
        auto bytes = env_->NewByteArray(static_cast<jsize>(data.size()));
        if (!bytes) { env_->ExceptionClear(); return false; }
        env_->SetByteArrayRegion(bytes, 0, static_cast<jsize>(data.size()), reinterpret_cast<const jbyte*>(data.data()));
        const auto sent = env_->CallBooleanMethod(socket_, send_, bytes, static_cast<jboolean>(binary));
        env_->DeleteLocalRef(bytes);
        if (env_->ExceptionCheck()) { env_->ExceptionClear(); return false; }
        return sent;
    }

    std::optional<NetMessage> receive() override {
        if (!socket_) return NetMessage{NetEvent::Closed, {}};
        auto bytes = static_cast<jbyteArray>(env_->CallObjectMethod(socket_, next_));
        if (!bytes) return std::nullopt;
        const auto size = env_->GetArrayLength(bytes);
        Bytes data(size);
        env_->GetByteArrayRegion(bytes, 0, size, reinterpret_cast<jbyte*>(data.data()));
        env_->DeleteLocalRef(bytes);
        if (data.empty()) return std::nullopt;
        const auto event = static_cast<NetEvent>(data.back());
        data.pop_back();
        return NetMessage{event, std::move(data)};
    }

private:
    JNIEnv* env_{};
    jobject socket_{};
    jmethodID send_{}, next_{}, close_{};
};
}

std::unique_ptr<NetSocket> connectSocket(const std::string& url) {
    return std::make_unique<AndroidSocket>(url);
}
}

#pragma once

#include "lia.hpp"
#include "netplay.hpp"

namespace legoblast {

class NetworkBots {
public:
    void fill(const Session& session, Controls& input, std::string_view roster, const LiaModel* model = nullptr);
    static unsigned microMask(std::string_view roster);
private:
    std::array<Lia, NetworkPlaces> lias_;
    std::array<unsigned, NetworkPlaces> actions_{};
    unsigned previousTick_{}, round_{};
};

void applyMatchCommand(Session& session, std::string_view command);

}

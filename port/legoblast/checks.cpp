#include "level.hpp"

#include <iostream>
#include <stdexcept>

using namespace legoblast;

void check(bool ok, const char* message) {
    if (!ok)
        throw std::runtime_error(message);
}

int main(int argc, char** argv) {
    try {
        check(argc == 2, "expected Amiga source path");
        const std::filesystem::path root = argv[1];
        const auto binary = root / "binary";
        const auto level = loadLevel(binary / "Lego_Level001.dat");
        check(level.warningTime == 1000 && level.totalTime == 15000 &&
              level.starts[0].x == 1 && level.starts[1].x == 17 &&
              level.teleporters.empty(), "original level 001 header");
        check(loadLevel(binary / "Lego_Level002.dat").teleporters.size() == 4, "level 002 teleporters");
        int count = 0;
        const auto bank = readBytes(binary / "Lego_Blocs.dat");
        int emptyNames = 0;
        for (const auto& entry : std::filesystem::directory_iterator(binary)) {
            const auto name = entry.path().filename().string();
            if (name.starts_with("Lego_Level") && name.ends_with(".dat")) {
                const auto candidate = loadLevel(entry.path());
                if (candidate.name.empty())
                    ++emptyNames;
                ++count;
                try {
                    check(staticLevelRgb(candidate, bank, readLevelPalette(root, candidate.palette)).size()
                              == 304 * 240 * 3, "incorrect image size");
                } catch (const std::exception& error) {
                    throw std::runtime_error(name + ": " + error.what());
                }
            }
        }
        check(count == 130 && emptyNames == 1, "original level corpus");
        auto bad = readBytes(binary / "Lego_Level001.dat");
        bad.resize(513);
        bool rejected = false;
        try { decodeLevel(bad); }
        catch (const std::runtime_error&) { rejected = true; }
        check(rejected, "truncated teleporter sentinel accepted");

        RandomState state{0x12345678u, 0xabcdefffu};
        check(state.next() == 0x8b9d518bu && state.d1 == 0xabcdef74u, "Rnd_Engine first draw");
        check(state.next() == 0x95f9cb52u && state.d1 == 0xabcdef22u, "Rnd_Engine second draw");
        state = {0x12345678u, 0xabcdefffu};
        check(state.test(0x518b) == 0, "Rnd_Bool equality");
        auto dyna = loadLevel(binary / "Lego_Level999.dat");
        state = {0x12345678u, 0xabcdefffu};
        dynaInit(dyna, state);
        std::uint32_t hash = 2166136261u;
        for (auto byte : dyna.tiles)
            hash = (hash ^ byte) * 16777619u;
        check(hash == 0xb25e4e9du && state.d0 == 0x8f04d6b6u && state.d1 == 0xabcdef6du,
              "DynaInit original template and post-generation random state");

        Level synthetic{};
        synthetic.bonusWeights[1] = 1;
        synthetic.bonusWeights[2] = 2;
        const auto bonus = makeBonusTable(synthetic);
        check(bonus[0] == 1 && bonus[84] == 1 && bonus[85] == 2 &&
              bonus[254] == 2 && bonus[255] == 0 && bonus[256] == 0,
              "MakeRndCorresp integer division and clear remainder");
        auto seeded = loadLevel(binary / "Lego_Level002.dat");
        seeded.tiles.fill(0);
        seeded.tiles.back() = 2;
        state = {0x12345678u, 0xabcdefffu};
        auto expected = state;
        for (int draw = 0; draw < 5; ++draw)
            expected.next();
        const auto initialized = initialLevelRandoms(seeded, state);
        check(initialized.teleporterFrames == std::vector<std::uint8_t>{138, 137, 142, 140} &&
              state.d0 == expected.d0 && state.d1 == expected.d1,
              "teleporter and hidden bonus random draw order");
        std::cout << count << " original levels decoded and rendered\n";
    } catch (const std::exception& error) {
        std::cerr << error.what() << '\n';
        return 1;
    }
}

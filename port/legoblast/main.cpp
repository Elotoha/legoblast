#include "level.hpp"

#include <fstream>
#include <iostream>
#include <stdexcept>

int main(int argc, char* argv[]) {
    try {
        if (argc != 2 && argc != 4) {
            std::cerr << "usage: legoblast_levels LEVEL.dat [AMIGA_SRC OUTPUT.ppm]\n";
            return 2;
        }
        const auto level = legoblast::loadLevel(argv[1]);
        std::cout << level.name << " | " << level.warningTime << '/' << level.totalTime
                  << " VBL | palette " << level.palette << " | "
                  << level.teleporters.size() << " teleporters\n";
        if (argc == 4) {
            const std::filesystem::path root = argv[2];
            const auto rgb = legoblast::staticLevelRgb(level,
                legoblast::readBytes(root / "binary/Lego_Blocs.dat"),
                legoblast::readLevelPalette(root, level.palette));
            std::ofstream output(argv[3], std::ios::binary);
            output << "P6\n" << legoblast::Width * legoblast::TileSize << ' '
                   << legoblast::Height * legoblast::TileSize << "\n255\n";
            output.write(reinterpret_cast<const char*>(rgb.data()), static_cast<std::streamsize>(rgb.size()));
            output.close();
            if (!output)
                throw std::runtime_error("cannot write static level image");
        }
        return 0;
    } catch (const std::exception& error) {
        std::cerr << error.what() << '\n';
        return 1;
    }
}

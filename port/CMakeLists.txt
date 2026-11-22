cmake_minimum_required(VERSION 3.24)
project(legoblast_port LANGUAGES CXX)

find_package(SDL3 3.2 CONFIG REQUIRED)
find_package(PNG REQUIRED)
find_path(SNDFILE_INCLUDE_DIR sndfile.h REQUIRED)
find_library(SNDFILE_LIBRARY NAMES sndfile libsndfile.so.1 REQUIRED)
find_package(nlohmann_json 3.11 CONFIG REQUIRED)

add_library(port_runtime src/assets.cpp src/audio.cpp src/audio_io.cpp src/display.cpp)
target_compile_features(port_runtime PUBLIC cxx_std_20)
target_include_directories(port_runtime PUBLIC src PRIVATE "${SNDFILE_INCLUDE_DIR}")
target_link_libraries(port_runtime PUBLIC SDL3::SDL3 PRIVATE PNG::PNG "${SNDFILE_LIBRARY}" nlohmann_json::nlohmann_json)

add_executable(asset_preview src/main.cpp)
target_link_libraries(asset_preview PRIVATE port_runtime)

include(CTest)
if(BUILD_TESTING)
  find_package(Python3 REQUIRED COMPONENTS Interpreter)
  add_executable(port_checks tests/checks.cpp)
  target_link_libraries(port_checks PRIVATE port_runtime)
  add_test(NAME asset_pipeline COMMAND "${Python3_EXECUTABLE}" "${CMAKE_CURRENT_SOURCE_DIR}/tests/pipeline.py"
    "${CMAKE_CURRENT_SOURCE_DIR}/tools/convert.py" "$<TARGET_FILE:port_checks>" "$<TARGET_FILE:asset_preview>")
endif()

cmake_minimum_required(VERSION 3.24)
project(ember_relay LANGUAGES CXX)

find_package(SDL3 3.2 CONFIG REQUIRED)

add_library(ember_rules rules.cpp)
target_compile_features(ember_rules PUBLIC cxx_std_20)
target_include_directories(ember_rules PUBLIC .)
add_executable(EmberRelay main.cpp)
target_link_libraries(EmberRelay PRIVATE ember_rules SDL3::SDL3)

include(CTest)
if(BUILD_TESTING)
  add_executable(ember_checks checks.cpp)
  target_link_libraries(ember_checks PRIVATE ember_rules)
  add_test(NAME arena_rules COMMAND ember_checks)
  add_test(NAME arena_sdl COMMAND EmberRelay --smoke)
  set_tests_properties(arena_sdl PROPERTIES ENVIRONMENT "SDL_VIDEODRIVER=dummy;SDL_RENDER_DRIVER=software")
endif()

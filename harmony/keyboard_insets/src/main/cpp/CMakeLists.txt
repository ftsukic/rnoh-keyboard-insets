cmake_minimum_required(VERSION 3.13)
set(CMAKE_VERBOSE_MAKEFILE on)

set(rnoh_keyboard_insets_generated_dir "${CMAKE_CURRENT_SOURCE_DIR}/RNOH/generated")
file(GLOB_RECURSE rnoh_keyboard_insets_generated_SRC
    "${rnoh_keyboard_insets_generated_dir}/**/*.cpp")
file(GLOB_RECURSE rnoh_keyboard_insets_codegen_SRC
    "${CMAKE_CURRENT_SOURCE_DIR}/react/**/*.cpp")
file(GLOB rnoh_keyboard_insets_SRC CONFIGURE_DEPENDS *.cpp)
add_library(rnoh__keyboard_insets SHARED
    ${rnoh_keyboard_insets_SRC}
    ${rnoh_keyboard_insets_generated_SRC}
    ${rnoh_keyboard_insets_codegen_SRC})
target_include_directories(rnoh__keyboard_insets PUBLIC
    ${CMAKE_CURRENT_SOURCE_DIR}
    ${rnoh_keyboard_insets_generated_dir})
target_link_libraries(rnoh__keyboard_insets PUBLIC rnoh)

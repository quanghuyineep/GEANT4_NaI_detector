cmake_minimum_required(VERSION 3.16)
project(sim_nai)

find_package(Geant4 REQUIRED ui_all vis_all)
include(${Geant4_USE_FILE})

file(GLOB SOURCES ${PROJECT_SOURCE_DIR}/src/*.cc)
file(GLOB HEADERS ${PROJECT_SOURCE_DIR}/include/*.hh)

add_executable(sim_nai sim_nai.cc ${SOURCES} ${HEADERS})

# DÒNG CẦN THÊM VÀO ĐÂY:
target_include_directories(sim_nai PRIVATE ${PROJECT_SOURCE_DIR}/include)

target_link_libraries(sim_nai ${Geant4_LIBRARIES})
cmake_minimum_required(VERSION 3.0)
project(fdptest)

add_executable(fdptest "src/program.cpp")

target_link_libraries(fdptest PUBLIC stupid)

target_include_directories(fdptest PUBLIC
                          "${PROJECT_BINARY_DIR}"
                          "${PROJECT_SOURCE_DIR}/src/include"
                          )
cmake_minimum_required(VERSION 3.13)
project(cp_uring)


set(LIBURING_SOURCE_DIR "${PROJECT_SOURCE_DIR}/../../liburing/src")
set(LIBURING_INCLUDE_DIR "${LIBURING_SOURCE_DIR}/include")

find_library(LIBURING NAMES uring PATHS ${LIBURING_SOURCE_DIR})

if(NOT LIBURING)
message(FATAL_ERROR "liburing not found in ${LIBURING_SOURCE_DIR}")
endif()

add_executable(cpring "main.cpp")

target_link_libraries(cpring PRIVATE LIBURING)

target_include_directories(cpring PRIVATE
                                    ${LIBURING_INCLUDE_DIR})
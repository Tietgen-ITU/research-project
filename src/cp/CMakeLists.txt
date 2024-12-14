cmake_minimum_required(VERSION 3.13)
project(cp_uring)


set(LIBURING_SOURCE_DIR "${PROJECT_SOURCE_DIR}/../../liburing/src")
set(LIBURING_INCLUDE_DIR "${LIBURING_SOURCE_DIR}/include")

find_library(LIBURING NAMES uring PATHS ${LIBURING_SOURCE_DIR})

if(NOT LIBURING)
    message(FATAL_ERROR "liburing not found in ${LIBURING_SOURCE_DIR}")
endif()

message(STATUS "Found liburing: ${LIBURING}")

add_executable(cpring "main.cpp")

# Add the ioring subdirectory
set(IORING_INCLUDE_DIR "${PROJECT_SOURCE_DIR}/include/ioring")

add_subdirectory(ioring)
target_link_libraries(cpring PRIVATE ${LIBURING} 
                                        ioring)

target_include_directories(cpring PRIVATE
                                    ${LIBURING_INCLUDE_DIR}
                                    include
                                    ${IORING_INCLUDE_DIR}
                                    )
cmake_minimum_required(VERSION 3.0)

project(db)

set(CMAKE_CXX_STANDARD 11)

find_library(DUCKDB NAMES duckdb PATHS ${PROJECT_SOURCE_DIR}/../../duckdb/build/release/src)

if(NOT DUCKDB)
    message(FATAL_ERROR "DUCKDB not found in ${EXTERNAL_LIB_DIR}")
endif()

add_executable(dbcli ${PROJECT_SOURCE_DIR}/main.cpp)

target_link_directories(dbcli PRIVATE ${PROJECT_SOURCE_DIR}/../../duckdb/build/release/src)
target_link_libraries(dbcli PRIVATE ${DUCKDB})
target_include_directories(dbcli PRIVATE ${PROJECT_SOURCE_DIR}/../../duckdb/src/include)
cmake_minimum_required(VERSION 3.0)

project(db)

set(CMAKE_CXX_STANDARD 11) # Very important or else we will get errors compiling the duckdb code

set(DUCKDB_LIB_DIR ${PROJECT_SOURCE_DIR}/../../duckdb/build/release/src)
set(DUCKDB_INCLUDE_DIR ${PROJECT_SOURCE_DIR}/../../duckdb/src/include)

find_library(DUCKDB NAMES duckdb PATHS ${DUCKDB_LIB_DIR}) # Finds the absolute patht to the duckdb library

if(NOT DUCKDB)
    message(FATAL_ERROR "DUCKDB not found in ${DUCKDB_LIB_DIR}")
endif()

add_executable(dbcli ${PROJECT_SOURCE_DIR}/main.cpp)

target_link_libraries(dbcli PRIVATE ${DUCKDB})                  # Link the duckdb library to the dbcli executable
target_include_directories(dbcli PRIVATE ${DUCKDB_INCLUDE_DIR}) # Include the duckdb headers in the dbcli executable
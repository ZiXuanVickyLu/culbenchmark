cmake_minimum_required(VERSION 3.18)

project(culbenchmark LANGUAGES CXX CUDA)
enable_language(CUDA)

# Find CUDA Toolkit
find_package(CUDAToolkit REQUIRED)
message(STATUS "CUDA Toolkit version: ${CUDAToolkit_VERSION}")
message(STATUS "CUDA Toolkit root: ${CUDAToolkit_ROOT}")
message(STATUS "CUDA Include directories: ${CUDAToolkit_INCLUDE_DIRS}")

# Set C++ and CUDA standards
set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_STANDARD_REQUIRED ON)
set(CMAKE_CUDA_STANDARD 17)
set(CMAKE_CUDA_STANDARD_REQUIRED ON)

# Enable compile_commands.json generation for clangd
set(CMAKE_EXPORT_COMPILE_COMMANDS ON)
set(CMAKE_EXPORT_COMPILE_COMMANDS_JSON "${CMAKE_BINARY_DIR}/compile_commands.json")

set(CMAKE_POSITION_INDEPENDENT_CODE ON)

# Set CUDA specific flags (use space-separated, not semicolon)
set(CMAKE_CUDA_FLAGS "${CMAKE_CUDA_FLAGS} --extended-lambda --expt-relaxed-constexpr" CACHE STRING "CUDA flags" FORCE)

# Force CUDA compilation 
set_source_files_properties(
    ${CMAKE_CURRENT_SOURCE_DIR}/src/vector_type_t.h
    PROPERTIES
    LANGUAGE CUDA
)

#default use double precision
option(CLBCH_USE_DOUBLE "CLBCH_USE_DOUBLE" OFF)
if(CLBCH_USE_DOUBLE)
	message(STATUS "Using double precision")
	add_compile_definitions(CLBCH_USE_DOUBLE)
endif()

set(CMAKE_RUNTIME_OUTPUT_DIRECTORY ${CMAKE_BINARY_DIR})
set(CMAKE_LIBRARY_OUTPUT_DIRECTORY ${CMAKE_BINARY_DIR})
set(CMAKE_ARCHIVE_OUTPUT_DIRECTORY ${CMAKE_BINARY_DIR})

set(CMAKE_MODULE_PATH ${CMAKE_MODULE_PATH} ${CMAKE_CURRENT_SOURCE_DIR}/cmake)
include(auto_detext_cuda_arch)
message(STATUS "CUDA_ARCHS: ${CUDA_ARCHS}")

# Extract compute capability from CUDA_ARCHS and set CMAKE_CUDA_ARCHITECTURES
if(CUDA_ARCHS)
    string(REGEX MATCH "compute_([0-9]+)" COMPUTE_CAPABILITY "${CUDA_ARCHS}")
    set(COMPUTE_CAPABILITY "${CMAKE_MATCH_1}")
    # Set as CACHE variable to propagate to all subdirectories and FetchContent projects
    set(CMAKE_CUDA_ARCHITECTURES ${COMPUTE_CAPABILITY} CACHE STRING "CUDA architectures" FORCE)
    message(STATUS "Setting CMAKE_CUDA_ARCHITECTURES to: ${CMAKE_CUDA_ARCHITECTURES}")
endif()
message(STATUS "CUDA Architectures: ${CMAKE_CUDA_ARCHITECTURES}")



## define project
set(CLBCH_ASSET_PATH "${CMAKE_SOURCE_DIR}/asset")
add_compile_definitions(CLBCH_ASSET_PATH="${CLBCH_ASSET_PATH}")

set(CLBCH_OUTPUT_PATH "${CMAKE_SOURCE_DIR}/output")
add_compile_definitions(CLBCH_OUTPUT_PATH="${CLBCH_OUTPUT_PATH}")

set(CLBCH_TEST_PATH "${CMAKE_SOURCE_DIR}/test")
set(CLBCH_SRC_PATH "${CMAKE_SOURCE_DIR}/src")
set(CLBCH_EXT_PATH "${CMAKE_SOURCE_DIR}/ext")



find_package(TBB REQUIRED)

# add external dependencies
add_subdirectory(ext)

# CCCL (Thrust, CUB, libcudacxx) are included in CUDA Toolkit
# Handle both CUDA 13.0+ (cccl/ subdirectory) and earlier versions (direct include)
# see: https://nvidia.github.io/cccl/cccl/3.0_migration_guide.html
if(CUDAToolkit_VERSION VERSION_GREATER_EQUAL "13.0")
    # CUDA 13.0+: CCCL is in a separate cccl/ subdirectory
    set(CCCL_ROOT "${CUDAToolkit_INCLUDE_DIRS}/cccl")
    set(THRUST_INCLUDE_DIR "${CCCL_ROOT}/thrust")
    set(CUB_INCLUDE_DIR "${CCCL_ROOT}/cub")
    set(LIBCUDACXX_INCLUDE_DIR "${CCCL_ROOT}/cuda/include")
    message(STATUS "CUDA ${CUDAToolkit_VERSION}: Using CCCL from cccl/ subdirectory")
else()
    # CUDA < 13.0: CCCL components are directly in include directory
    set(THRUST_INCLUDE_DIR "${CUDAToolkit_INCLUDE_DIRS}/thrust")
    set(CUB_INCLUDE_DIR "${CUDAToolkit_INCLUDE_DIRS}/cub")
    set(LIBCUDACXX_INCLUDE_DIR "${CUDAToolkit_INCLUDE_DIRS}/cuda")
    message(STATUS "CUDA ${CUDAToolkit_VERSION}: Using CCCL from include/ directory")
endif()

# Add CCCL include paths for host compiler
include_directories(SYSTEM 
    ${THRUST_INCLUDE_DIR}
    ${CUB_INCLUDE_DIR}
    ${LIBCUDACXX_INCLUDE_DIR}
)

message(STATUS "CCCL paths configured:")
message(STATUS "  Thrust: ${THRUST_INCLUDE_DIR}")
message(STATUS "  CUB: ${CUB_INCLUDE_DIR}")
message(STATUS "  libcudacxx: ${LIBCUDACXX_INCLUDE_DIR}")

add_subdirectory(src)

option(ENABLE_TESTS "Enable tests" ON)
if(ENABLE_TESTS)
    message(STATUS "Building tests")
    add_subdirectory(test)
endif()
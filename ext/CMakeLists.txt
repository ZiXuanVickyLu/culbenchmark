include(FetchContent)

# Enable verbose FetchContent output
set(FETCHCONTENT_QUIET OFF)

# Eigen
message(STATUS "fetch eigen...")
FetchContent_Declare(
	eigen
	GIT_REPOSITORY https://gitlab.com/Libero0809/eigen.git
	GIT_TAG 956fb32bae763affd597b9c54f745c7a2a8d5f91
	GIT_SHALLOW TRUE
)
# make eigen available for other find_package call
# This will make Eigen generate its config files
set(EIGEN_BUILD_DOC OFF)
set(BUILD_TESTING OFF)
set(EIGEN_BUILD_PKGCONFIG OFF)
set(CMAKE_POLICY_DEFAULT_CMP0077 NEW)
set(EIGEN_SKIP_FIND_PACKAGE_HANDLING ON)

# Make Eigen available for find_package
set(Eigen3_DIR ${eigen_BINARY_DIR} CACHE PATH "Directory containing Eigen3Config.cmake" FORCE)
FetchContent_GetProperties(eigen)
if(NOT eigen_POPULATED)
    FetchContent_Populate(eigen)
endif()

add_library(Eigen3_Eigen INTERFACE)
add_library(Eigen3::Eigen ALIAS Eigen3_Eigen)

include(GNUInstallDirs)
target_include_directories(Eigen3_Eigen SYSTEM INTERFACE
    $<BUILD_INTERFACE:${eigen_SOURCE_DIR}>
    $<INSTALL_INTERFACE:${CMAKE_INSTALL_INCLUDEDIR}>
)

option(EIGEN_MPL2_ONLY "Compile Eigen with MPL2 code only" OFF)
if(EIGEN_MPL2_ONLY)
    target_compile_definitions(Eigen3_Eigen INTERFACE EIGEN_MPL2_ONLY)
endif()

# On Windows, enable natvis files to improve debugging experience
if(WIN32 AND eigen_SOURCE_DIR)
    target_sources(Eigen3_Eigen INTERFACE $<BUILD_INTERFACE:${eigen_SOURCE_DIR}/debug/msvc/eigen.natvis>)
endif()

# Install rules
set(CMAKE_INSTALL_DEFAULT_COMPONENT_NAME eigen)
set_target_properties(Eigen3_Eigen PROPERTIES EXPORT_NAME Eigen)
install(DIRECTORY ${eigen_SOURCE_DIR}/Eigen DESTINATION ${CMAKE_INSTALL_INCLUDEDIR})
install(TARGETS Eigen3_Eigen EXPORT EigenTargets)
install(EXPORT EigenTargets DESTINATION ${CMAKE_INSTALL_LIBDIR}/cmake/eigen NAMESPACE Eigen3::)


# json
message(STATUS "fetch json...")
FetchContent_Declare(
    json
    GIT_REPOSITORY https://github.com/nlohmann/json
    GIT_TAG v3.11.3
    GIT_SHALLOW TRUE
)

FetchContent_MakeAvailable(json)

# spdlog
message(STATUS "fetch spdlog...")
FetchContent_Declare(
    spdlog
    GIT_REPOSITORY https://github.com/gabime/spdlog.git
    GIT_TAG v1.14.1
    GIT_SHALLOW TRUE
)

FetchContent_MakeAvailable(spdlog)


find_package(TBB REQUIRED)

# cuda-api-wrappers
message(STATUS "fetch cuda-api-wrappers...")
FetchContent_Declare(
    cuda-api-wrappers
    GIT_REPOSITORY https://github.com/eyalroz/cuda-api-wrappers.git
    GIT_TAG master
    GIT_SHALLOW TRUE
    OVERRIDE_FIND_PACKAGE
)

find_package(cuda-api-wrappers CONFIG REQUIRED)

# AMGX
message(STATUS "fetch AMGX...")

# Ensure AMGX respects the parent's CMAKE_CUDA_ARCHITECTURES
# CUDA 13.0+ doesn't support compute_70, minimum is compute_75
if(CMAKE_CUDA_ARCHITECTURES)
    message(STATUS "Using detected CUDA architecture for AMGX: ${CMAKE_CUDA_ARCHITECTURES}")
    # Check if the detected architecture is supported by CUDA 13.0+
    if(CUDAToolkit_VERSION VERSION_GREATER_EQUAL "13.0")
        if(CMAKE_CUDA_ARCHITECTURES LESS 75)
            message(WARNING "CUDA 13.0+ doesn't support compute_${CMAKE_CUDA_ARCHITECTURES}. Setting to minimum supported: 75")
            set(CMAKE_CUDA_ARCHITECTURES "75" CACHE STRING "CUDA architecture" FORCE)
        endif()
    endif()
else()
    message(WARNING "CMAKE_CUDA_ARCHITECTURES not set! Using default for your GPU")
    set(CMAKE_CUDA_ARCHITECTURES "89" CACHE STRING "CUDA architecture" FORCE)
endif()

FetchContent_Declare(
    amgx
    GIT_REPOSITORY https://github.com/NVIDIA/AMGX.git
    GIT_TAG main
    GIT_SHALLOW FALSE  # Need full history for submodules
    GIT_SUBMODULES_RECURSE TRUE  # Recursively initialize submodules
)

# AMGX build options - must be set BEFORE FetchContent_MakeAvailable
set(AMGX_NO_RPATH OFF CACHE BOOL "Disable RPATH in AMGX" FORCE)

# Override AMGX's default architectures - this is critical for CUDA 13.0+
# AMGX has hardcoded arch flags, we need to override them
set(CUDA_ARCH "${CMAKE_CUDA_ARCHITECTURES}" CACHE STRING "CUDA architectures for AMGX" FORCE)
set(CMAKE_CUDA_ARCHITECTURES_DEFAULT "${CMAKE_CUDA_ARCHITECTURES}" CACHE STRING "Default CUDA architectures" FORCE)

FetchContent_MakeAvailable(amgx)

# After AMGX is fetched, enforce architecture again to prevent AMGX from overriding
set(CMAKE_CUDA_ARCHITECTURES "${CMAKE_CUDA_ARCHITECTURES}" CACHE STRING "CUDA architectures" FORCE)

# fast_matrix_market
message(STATUS "fetch fast_matrix_market...")
FetchContent_Declare(
    fast_matrix_market
    GIT_REPOSITORY https://github.com/alugowski/fast_matrix_market.git
    GIT_TAG main
    GIT_SHALLOW TRUE
)

FetchContent_MakeAvailable(fast_matrix_market)

message(STATUS "Install and clone thirdparty built finished!")
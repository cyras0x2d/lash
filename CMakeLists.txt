cmake_minimum_required(VERSION 3.16)
project(lash VERSION 1.0 LANGUAGES CXX)

set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_STANDARD_REQUIRED ON)
set(CMAKE_CXX_EXTENSIONS OFF)

set(CMAKE_AUTOMOC ON) # Qt's Meta-Object Compiler
set(CMAKE_AUTORCC ON)
set(CMAKE_AUTOUIC ON)

# Check Link Time Optimization (LTO / IPO) support
include(CheckIPOSupported)
check_ipo_supported(RESULT ipo_supported OUTPUT ipo_error)

# Find necessary libraries
find_package(Qt6 COMPONENTS Core Gui Qml Quick REQUIRED)
find_package(OpenSSL REQUIRED)
find_library(LEVELDB_LIB leveldb REQUIRED)
find_package(Threads REQUIRED)

# Add executable target
qt_add_executable(lash
    main.cpp
    HashController.cpp
    HashController.h
)

set_target_properties(lash PROPERTIES QT_RESOURCE_PREFIX "/")
qt6_add_resources(lash "app_resources"
    PREFIX "/"
    FILES
        Main.qml
        icons/clear.svg
        icons/folder-open.svg
        icons/info.svg
        icons/keep.svg
        icons/plus-square.svg
        font/Bitcoa.otf
        font/Bitcoa.ttf
        "font/Cyber Blast.otf"
        font/cyberblast.otf
        font/cyberblast.ttf
)

# Apply Interprocedural Optimization (LTO) if supported by compiler/toolchain
if(ipo_supported)
    set_property(TARGET lash PROPERTY INTERPROCEDURAL_OPTIMIZATION TRUE)
else()
    message(STATUS "LTO / IPO is not supported: ${ipo_error}")
endif()

# Hardened and optimized compiler/linker options for GCC/Clang
if(CMAKE_CXX_COMPILER_ID MATCHES "GNU|Clang")
    target_compile_options(lash PRIVATE
        -O3
        -Wall
        -Wextra
        -Wpedantic
        -fstack-protector-strong
        -fPIE
    )
    target_link_options(lash PRIVATE
        -pie
        -Wl,-z,relro,-z,now
    )
endif()

# Link everything together
target_link_libraries(lash PRIVATE
    Qt6::Core
    Qt6::Gui
    Qt6::Qml
    Qt6::Quick
    OpenSSL::Crypto
    ${LEVELDB_LIB}
    Threads::Threads
)

install(TARGETS lash DESTINATION bin)

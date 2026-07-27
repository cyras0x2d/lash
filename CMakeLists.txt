cmake_minimum_required(VERSION 3.16)
project(lash VERSION 1.0 LANGUAGES CXX)

set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_STANDARD_REQUIRED ON)
set(CMAKE_AUTOMOC ON) # Qt's Meta-Object Compiler
set(CMAKE_AUTORCC ON)
set(CMAKE_AUTOUIC ON)

# Find necessary libraries
find_package(Qt6 COMPONENTS Core Gui Qml Quick REQUIRED)
find_package(OpenSSL REQUIRED)
find_library(LEVELDB_LIB leveldb REQUIRED)
find_package(Threads REQUIRED)

# Add your executable
qt_add_executable(lash
    main.cpp
    HashController.cpp
    HashController.h
    qml.qrc
)

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


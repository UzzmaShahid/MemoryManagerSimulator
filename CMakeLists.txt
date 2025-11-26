cmake_minimum_required(VERSION 3.10)
project(MemoryManager)

set(CMAKE_CXX_STANDARD 17)
set(CMAKE_AUTOMOC ON)
set(CMAKE_AUTOUIC ON)
set(CMAKE_INCLUDE_CURRENT_DIR ON)

find_package(Qt5 COMPONENTS Widgets REQUIRED)

include_directories(src/core src/gui)

set(SOURCES
    src/main.cpp
    src/core/Page.cpp
    src/core/PageTable.cpp
    src/core/MemoryManager.cpp
    src/core/FIFO.cpp
    src/core/LRU.cpp
    src/gui/MainWindow.cpp
)

add_executable(MemoryManager ${SOURCES})
target_link_libraries(MemoryManager Qt5::Widgets)

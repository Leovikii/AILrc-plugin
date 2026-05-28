cmake_minimum_required(VERSION 3.15)
project(AILrcPlugin)

set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_STANDARD_REQUIRED ON)

# Fetch nlohmann_json
include(FetchContent)
FetchContent_Declare(json
  URL https://github.com/nlohmann/json/releases/download/v3.11.3/json.tar.xz
)
FetchContent_MakeAvailable(json)

# Create shared library
add_library(AILrc_plugin SHARED
    Plugin.cpp
    Controller.cpp
    Utils.cpp
)

# Include AIMP SDK
target_include_directories(AILrc_plugin PRIVATE ${CMAKE_CURRENT_SOURCE_DIR}/aimp_sdk)

# Link JSON library
target_link_libraries(AILrc_plugin PRIVATE nlohmann_json::nlohmann_json)

# Windows libraries
target_link_libraries(AILrc_plugin PRIVATE user32 shell32)

# Definitions
target_compile_definitions(AILrc_plugin PRIVATE UNICODE _UNICODE)

# We do not want the lib/exp files, but they are generated for SHARED.
# Ensure that we export AIMPPluginGetHeader.

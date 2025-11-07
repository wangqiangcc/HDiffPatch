# xxHash CMakeLists.txt
# Template for xxHash library
# Clone from: https://github.com/sisong/xxHash.git

# Check if source files exist
if(EXISTS "${CMAKE_CURRENT_SOURCE_DIR}/xxhash.c")
    set(XXH_SOURCES
        xxhash.c
    )

    add_library(xxhash STATIC ${XXH_SOURCES})
    
    target_include_directories(xxhash PUBLIC 
        ${CMAKE_CURRENT_SOURCE_DIR}
    )
    
    # Set properties to match the original Makefile
    set_target_properties(xxhash PROPERTIES
        C_STANDARD 99
        POSITION_INDEPENDENT_CODE ON
    )
else()
    message(WARNING "xxhash source files not found. Please clone the repository:")
    message(WARNING "git clone https://github.com/sisong/xxHash.git ${CMAKE_CURRENT_SOURCE_DIR}")
    
    # Create a dummy target to avoid build errors
    add_library(xxhash INTERFACE)
endif()
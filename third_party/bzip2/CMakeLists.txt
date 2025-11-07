# BZIP2 CMakeLists.txt
# Template for bzip2 library
# Clone from: https://github.com/sisong/bzip2.git

# Check if source files exist
if(EXISTS "${CMAKE_CURRENT_SOURCE_DIR}/blocksort.c")
    set(BZIP2_SOURCES
        blocksort.c
        bzlib.c
        compress.c
        crctable.c
        decompress.c
        huffman.c
        randtable.c
    )

    add_library(bz2 STATIC ${BZIP2_SOURCES})
    
    target_include_directories(bz2 PUBLIC 
        ${CMAKE_CURRENT_SOURCE_DIR}
    )
    
    # Set properties to match the original Makefile
    set_target_properties(bz2 PROPERTIES
        C_STANDARD 99
        POSITION_INDEPENDENT_CODE ON
    )
else()
    message(WARNING "bzip2 source files not found. Please clone the repository:")
    message(WARNING "git clone https://github.com/sisong/bzip2.git ${CMAKE_CURRENT_SOURCE_DIR}")
    
    # Create a dummy target to avoid build errors
    add_library(bz2 INTERFACE)
endif()
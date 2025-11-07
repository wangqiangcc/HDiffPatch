# MD5 CMakeLists.txt
# Template for libmd5 library
# Clone from: https://github.com/sisong/libmd5.git

# Check if source files exist
if(EXISTS "${CMAKE_CURRENT_SOURCE_DIR}/md5.c")
    set(MD5_SOURCES
        md5.c
    )

    add_library(md5 STATIC ${MD5_SOURCES})
    
    target_include_directories(md5 PUBLIC 
        ${CMAKE_CURRENT_SOURCE_DIR}
    )
    
    # Set properties to match the original Makefile
    set_target_properties(md5 PROPERTIES
        C_STANDARD 99
        POSITION_INDEPENDENT_CODE ON
    )
else()
    message(WARNING "md5 source files not found. Please clone the repository:")
    message(WARNING "git clone https://github.com/sisong/libmd5.git ${CMAKE_CURRENT_SOURCE_DIR}")
    
    # Create a dummy target to avoid build errors
    add_library(md5 INTERFACE)
endif()
# ZSTD CMakeLists.txt
# Template for zstd library
# Clone from: https://github.com/sisong/zstd.git

# Check if source files exist
if(EXISTS "${CMAKE_CURRENT_SOURCE_DIR}/common")
    set(ZSTD_COMMON_SOURCES
        common/debug.c
        common/entropy_common.c
        common/error_private.c
        common/fse_decompress.c
        common/xxhash.c
        common/zstd_common.c
    )

    set(ZSTD_COMPRESS_SOURCES
        compress/fse_compress.c
        compress/hist.c
        compress/huf_compress.c
        compress/zstd_compress.c
        compress/zstd_compress_literals.c
        compress/zstd_compress_sequences.c
        compress/zstd_compress_superblock.c
        compress/zstd_preSplit.c
        compress/zstd_double_fast.c
        compress/zstd_fast.c
        compress/zstd_lazy.c
        compress/zstd_ldm.c
        compress/zstd_opt.c
    )

    set(ZSTD_DECOMPRESS_SOURCES
        decompress/huf_decompress.c
        decompress/zstd_ddict.c
        decompress/zstd_decompress.c
        decompress/zstd_decompress_block.c
    )

    set(ZSTD_MT_SOURCES
        common/pool.c
        common/threading.c
        compress/zstdmt_compress.c
    )

    # ZSTD library
    add_library(zstd STATIC
        ${ZSTD_COMMON_SOURCES}
        ${ZSTD_COMPRESS_SOURCES}
        ${ZSTD_DECOMPRESS_SOURCES}
    )
    
    target_include_directories(zstd PUBLIC
        ${CMAKE_CURRENT_SOURCE_DIR}
        ${CMAKE_CURRENT_SOURCE_DIR}/common
        ${CMAKE_CURRENT_SOURCE_DIR}/compress
        ${CMAKE_CURRENT_SOURCE_DIR}/decompress
    )
    
    target_compile_definitions(zstd PUBLIC
        ZSTD_HAVE_WEAK_SYMBOLS=0
        ZSTD_TRACE=0
        ZSTD_DISABLE_ASM=1
        ZSTD_LIB_DEPRECATED=0
        ZSTD_STRIP_ERROR_STRINGS=1
    )
    
    # Multithreading support
    if(EXISTS "${CMAKE_CURRENT_SOURCE_DIR}/common/pool.c")
        target_sources(zstd PRIVATE ${ZSTD_MT_SOURCES})
    endif()
    
    # Set properties
    set_target_properties(zstd PROPERTIES
        C_STANDARD 99
        POSITION_INDEPENDENT_CODE ON
    )
else()
    message(WARNING "zstd source files not found. Please clone the repository:")
    message(WARNING "git clone https://github.com/sisong/zstd.git ${CMAKE_CURRENT_SOURCE_DIR}/..")
    
    # Create a dummy target
    add_library(zstd INTERFACE)
endif()
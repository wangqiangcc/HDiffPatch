cmake_minimum_required(VERSION 3.10)
project(HDiffPatch VERSION 1.0.0 LANGUAGES C CXX)

# Set C++ standard
set(CMAKE_CXX_STANDARD 11)
set(CMAKE_CXX_STANDARD_REQUIRED ON)
set(CMAKE_C_STANDARD 99)

# Options (corresponding to Makefile variables)
option(DIR_DIFF "Enable directory diff support" ON)
option(MT "Enable multi-threading support" ON)
option(LDEF "Use libdeflate" ON)
option(ARM64ASM "Enable ARM64 assembly optimizations for LZMA" OFF)
option(USE_CRC_EMU "Use software CRC for LZMA" OFF)
option(MD5 "Enable MD5 checksum support" ON)
option(XXH "Enable xxHash checksum support" ON)
option(VCD "Enable VCDIFF support" ON)
option(BSD "Enable BSDIFF support" ON)
option(M32 "Build with -m32 flag" OFF)
option(MINS "Build for minimum size" OFF)
option(STATIC_CPP "Static link C++ standard library" OFF)
option(STATIC_C "Static link C runtime" OFF)
option(PIE "Position independent executable" 0)
option(ATOMIC_U64 "Support atomic uint64" ON)

# Configure Visual Studio runtime library based on static options
if(WIN32 AND MSVC)
    if(STATIC_C OR STATIC_CPP)
        # Use static runtime library (/MT) for static builds
        set(CMAKE_MSVC_RUNTIME_LIBRARY "MultiThreaded$<$<CONFIG:Debug>:Debug>")
        # Also set compiler flags for older CMake versions
        foreach(flag_var
            CMAKE_C_FLAGS CMAKE_C_FLAGS_DEBUG CMAKE_C_FLAGS_RELEASE
            CMAKE_C_FLAGS_MINSIZEREL CMAKE_C_FLAGS_RELWITHDEBINFO
            CMAKE_CXX_FLAGS CMAKE_CXX_FLAGS_DEBUG CMAKE_CXX_FLAGS_RELEASE
            CMAKE_CXX_FLAGS_MINSIZEREL CMAKE_CXX_FLAGS_RELWITHDEBINFO)
            if(${flag_var} MATCHES "/MD")
                string(REGEX REPLACE "/MD" "/MT" ${flag_var} "${${flag_var}}")
            endif()
        endforeach()
        message(STATUS "Using static runtime library (/MT) for static builds")
    else()
        # Use dynamic runtime library (/MD) for dynamic builds  
        set(CMAKE_MSVC_RUNTIME_LIBRARY "MultiThreadedDLL$<$<CONFIG:Debug>:Debug>")
        message(STATUS "Using dynamic runtime library (/MD) for dynamic builds")
    endif()
endif()

# Platform detection
if(WIN32)
    set(BZIP2_DEFAULT 1)
    add_definitions(-D_IS_USED_WIN32_UTF8_WAPI=1)
else()
    set(BZIP2_DEFAULT 2)
endif()

# Dependency options
if(LDEF)
    set(ZLIB_DEFAULT 1)
else()
    set(ZLIB_DEFAULT 2)
endif()

set(ZLIB ${ZLIB_DEFAULT} CACHE STRING "ZLIB support (0=none, 1=source, 2=system)")
set(BZIP2 ${BZIP2_DEFAULT} CACHE STRING "BZIP2 support (0=none, 1=source, 2=system)")
set(LZMA 1 CACHE STRING "LZMA support (0=none, 1=source, 2=system)")
set(ZSTD 1 CACHE STRING "ZSTD support (0=none, 1=source, 2=system)")

# Validate options
if(BSD AND BZIP2 EQUAL 0)
    message(FATAL_ERROR "BSDIFF support requires BZIP2! Set BSD=OFF or BZIP2>0")
endif()

if(LDEF AND ZLIB EQUAL 2)
    message(FATAL_ERROR "libdeflate decompressor doesn't support -lz! Need zlib source code, set ZLIB=1")
endif()

# Set third-party directory
set(THIRD_PARTY_DIR ${CMAKE_CURRENT_SOURCE_DIR}/third_party)

# Compiler flags
set(CMAKE_C_FLAGS "${CMAKE_C_FLAGS} -O3 -DNDEBUG -D_LARGEFILE_SOURCE -D_FILE_OFFSET_BITS=64")
set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} -O3 -DNDEBUG -D_LARGEFILE_SOURCE -D_FILE_OFFSET_BITS=64")

if(M32)
    set(CMAKE_C_FLAGS "${CMAKE_C_FLAGS} -m32")
    set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} -m32")
endif()

if(MINS)
    set(CMAKE_C_FLAGS "${CMAKE_C_FLAGS} -s -Wno-error=format-security -fvisibility=hidden -ffunction-sections -fdata-sections -ffat-lto-objects -flto")
    set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} -fvisibility-inlines-hidden")
endif()

if(NOT ATOMIC_U64)
    add_definitions(-D_IS_NO_ATOMIC_U64=1)
endif()

# Base definitions
add_definitions(
    -D_IS_NEED_ALL_CompressPlugin=0
    -D_IS_NEED_DEFAULT_CompressPlugin=0
    -D_IS_NEED_ALL_ChecksumPlugin=0
    -D_IS_NEED_DEFAULT_ChecksumPlugin=0
)

# Feature definitions
if(DIR_DIFF)
    add_definitions(-D_IS_NEED_DIR_DIFF_PATCH=1)
    add_definitions(-D_ChecksumPlugin_fadler64)
else()
    add_definitions(-D_IS_NEED_DIR_DIFF_PATCH=0)
endif()

if(ZLIB GREATER 0)
    add_definitions(-D_CompressPlugin_zlib)
    if(DIR_DIFF)
        add_definitions(-D_ChecksumPlugin_crc32)
    endif()
endif()

if(LDEF)
    add_definitions(-D_CompressPlugin_ldef)
    if(ZLIB EQUAL 1)
        add_definitions(-D_CompressPlugin_ldef_is_use_zlib=1)
    else()
        add_definitions(-D_CompressPlugin_ldef_is_use_zlib=0)
    endif()
endif()

if(BSD)
    add_definitions(-D_IS_NEED_BSDIFF=1)
else()
    add_definitions(-D_IS_NEED_BSDIFF=0)
endif()

if(VCD)
    add_definitions(-D_IS_NEED_VCDIFF=1)
else()
    add_definitions(-D_IS_NEED_VCDIFF=0)
endif()

if(LZMA GREATER 0)
    add_definitions(-D_CompressPlugin_lzma -D_CompressPlugin_lzma2)
    if(VCD)
        add_definitions(-D_CompressPlugin_7zXZ)
    endif()
    if(ARM64ASM)
        add_definitions(-DZ7_LZMA_DEC_OPT)
    endif()
    if(USE_CRC_EMU)
        add_definitions(-DUSE_CRC_EMU)
    endif()
endif()

if(ZSTD GREATER 0)
    add_definitions(-D_CompressPlugin_zstd)
endif()

if(BZIP2 GREATER 0)
    add_definitions(-D_CompressPlugin_bz2)
endif()

if(MD5 AND DIR_DIFF)
    add_definitions(-D_ChecksumPlugin_md5)
endif()

if(XXH AND DIR_DIFF)
    add_definitions(-D_ChecksumPlugin_xxh3 -D_ChecksumPlugin_xxh128)
endif()

if(MT)
    add_definitions(-D_IS_USED_MULTITHREAD=1 -DZSTD_MULTITHREAD=1)
else()
    add_definitions(-DZ7_ST -D_IS_USED_MULTITHREAD=0)
endif()

# Third-party dependencies
include_directories(${CMAKE_CURRENT_SOURCE_DIR})

# ZLIB
if(ZLIB EQUAL 1)
    set(ZLIB_PATH ${THIRD_PARTY_DIR}/zlib)
    add_subdirectory(${ZLIB_PATH})
    include_directories(${ZLIB_PATH})
elseif(ZLIB EQUAL 2)
    find_package(ZLIB REQUIRED)
endif()

# BZIP2
if(BZIP2 EQUAL 1)
    set(BZIP2_PATH ${THIRD_PARTY_DIR}/bzip2)
    add_subdirectory(${BZIP2_PATH})
    include_directories(${BZIP2_PATH})
elseif(BZIP2 EQUAL 2)
    find_package(BZip2 REQUIRED)
endif()

# LZMA
if(LZMA GREATER 0)
    set(LZMA_PATH ${THIRD_PARTY_DIR}/lzma/C)
    if(LZMA EQUAL 1)
        add_subdirectory(${LZMA_PATH})
        include_directories(${LZMA_PATH})
    else()
        find_package(LibLZMA REQUIRED)
    endif()
endif()

# ZSTD
if(ZSTD GREATER 0)
    set(ZSTD_PATH ${THIRD_PARTY_DIR}/zstd/lib)
    if(ZSTD EQUAL 1)
        add_subdirectory(${ZSTD_PATH})
        include_directories(${ZSTD_PATH})
        include_directories(${ZSTD_PATH}/common)
        include_directories(${ZSTD_PATH}/compress)
        include_directories(${ZSTD_PATH}/decompress)
    else()
        find_package(zstd REQUIRED)
    endif()
endif()

# libdeflate
if(LDEF)
    set(LDEF_PATH ${THIRD_PARTY_DIR}/libdeflate)
    add_subdirectory(${LDEF_PATH})
    include_directories(${LDEF_PATH})
endif()

# MD5
if(MD5 AND DIR_DIFF)
    set(MD5_PATH ${THIRD_PARTY_DIR}/libmd5)
    add_subdirectory(${MD5_PATH})
    include_directories(${MD5_PATH})
endif()

# XXHash
if(XXH AND DIR_DIFF)
    set(XXH_PATH ${THIRD_PARTY_DIR}/xxHash)
    add_subdirectory(${XXH_PATH})
    include_directories(${XXH_PATH})
endif()

# Source files
set(HPATCH_SOURCES
    file_for_patch.c
    libHDiffPatch/HPatch/patch.c
)

if(MT)
    list(APPEND HPATCH_SOURCES
        libHDiffPatch/HPatch/hpatch_mt/_hcache_old_mt.c
        libHDiffPatch/HPatch/hpatch_mt/_hinput_mt.c
        libHDiffPatch/HPatch/hpatch_mt/_houtput_mt.c
        libHDiffPatch/HPatch/hpatch_mt/_hpatch_mt.c
        libHDiffPatch/HPatch/hpatch_mt/hpatch_mt.c
        libParallel/parallel_import_c.c
    )
endif()

if(DIR_DIFF)
    list(APPEND HPATCH_SOURCES
        dirDiffPatch/dir_patch/dir_patch.c
        dirDiffPatch/dir_patch/res_handle_limit.c
        dirDiffPatch/dir_patch/ref_stream.c
        dirDiffPatch/dir_patch/new_stream.c
        dirDiffPatch/dir_patch/dir_patch_tools.c
        dirDiffPatch/dir_patch/new_dir_output.c
        libHDiffPatch/HDiff/private_diff/limit_mem_diff/adler_roll.c
    )
endif()

if(BSD)
    list(APPEND HPATCH_SOURCES
        bsdiff_wrapper/bspatch_wrapper.c
    )
endif()

if(VCD)
    list(APPEND HPATCH_SOURCES
        vcdiff_wrapper/vcpatch_wrapper.c
    )
endif()

if(LZMA GREATER 0)
    if(VCD)
        list(APPEND HPATCH_SOURCES
            ${LZMA_PATH}/7zCrc.c
            ${LZMA_PATH}/7zCrcOpt.c
            ${LZMA_PATH}/Bra.c
            ${LZMA_PATH}/Bra86.c
            ${LZMA_PATH}/BraIA64.c
            ${LZMA_PATH}/Delta.c
            ${LZMA_PATH}/Sha256.c
            ${LZMA_PATH}/Sha256Opt.c
            ${LZMA_PATH}/Xz.c
            ${LZMA_PATH}/XzCrc64.c
            ${LZMA_PATH}/XzCrc64Opt.c
            ${LZMA_PATH}/XzDec.c
        )
    endif()
endif()

if(MD5 AND DIR_DIFF)
    list(APPEND HPATCH_SOURCES ${MD5_PATH}/md5.c)
endif()

if(XXH AND DIR_DIFF)
    list(APPEND HPATCH_SOURCES)
endif()

set(HDIFF_SOURCES
    hdiffz.cpp
    hdiffz_import_patch.c
    libHDiffPatch/HPatchLite/hpatch_lite.c
    libHDiffPatch/HDiff/diff.cpp
    libHDiffPatch/HDiff/match_block.cpp
    libHDiffPatch/HDiff/private_diff/bytes_rle.cpp
    libHDiffPatch/HDiff/private_diff/suffix_string.cpp
    libHDiffPatch/HDiff/private_diff/compress_detect.cpp
    libHDiffPatch/HDiff/private_diff/limit_mem_diff/digest_matcher.cpp
    libHDiffPatch/HDiff/private_diff/limit_mem_diff/stream_serialize.cpp
    libHDiffPatch/HDiff/private_diff/libdivsufsort/divsufsort64.cpp
    libHDiffPatch/HDiff/private_diff/libdivsufsort/divsufsort.cpp
    dirDiffPatch/dir_diff/dir_diff_tools.cpp
    ${HPATCH_SOURCES}
)

if(DIR_DIFF)
    list(APPEND HDIFF_SOURCES
        dirDiffPatch/dir_diff/dir_diff.cpp
        dirDiffPatch/dir_diff/dir_manifest.cpp
    )
else()
    list(APPEND HDIFF_SOURCES
        libHDiffPatch/HDiff/private_diff/limit_mem_diff/adler_roll.c
    )
endif()

if(BSD)
    list(APPEND HDIFF_SOURCES
        bsdiff_wrapper/bsdiff_wrapper.cpp
    )
endif()

if(MT)
    list(APPEND HDIFF_SOURCES
        libParallel/parallel_channel.cpp
        compress_parallel.cpp
    )
endif()

if(LZMA GREATER 0)
    list(APPEND HDIFF_SOURCES
        ${LZMA_PATH}/LzFind.c
        ${LZMA_PATH}/LzFindOpt.c
        ${LZMA_PATH}/LzmaEnc.c
        ${LZMA_PATH}/Lzma2Enc.c
    )
    if(MT)
        list(APPEND HDIFF_SOURCES
            ${LZMA_PATH}/LzFindMt.c
            ${LZMA_PATH}/MtCoder.c
        )
    endif()
    
    list(APPEND HPATCH_SOURCES
        ${LZMA_PATH}/LzmaDec.c
        ${LZMA_PATH}/Lzma2Dec.c
        ${LZMA_PATH}/7zStream.c
        ${LZMA_PATH}/CpuArch.c
        ${LZMA_PATH}/Alloc.c
    )
    if(MT)
        list(APPEND HPATCH_SOURCES
            ${LZMA_PATH}/MtDec.c
            ${LZMA_PATH}/Threads.c
        )
    endif()
    if(ARM64ASM)
        list(APPEND HPATCH_SOURCES ${LZMA_PATH}/../Asm/arm64/LzmaDecOpt.c)
    endif()
endif()

if(ZSTD EQUAL 1)
    list(APPEND HPATCH_SOURCES
        ${ZSTD_PATH}/common/debug.c
        ${ZSTD_PATH}/common/entropy_common.c
        ${ZSTD_PATH}/common/error_private.c
        ${ZSTD_PATH}/common/fse_decompress.c
        ${ZSTD_PATH}/common/xxhash.c
        ${ZSTD_PATH}/common/zstd_common.c
        ${ZSTD_PATH}/decompress/huf_decompress.c
        ${ZSTD_PATH}/decompress/zstd_ddict.c
        ${ZSTD_PATH}/decompress/zstd_decompress.c
        ${ZSTD_PATH}/decompress/zstd_decompress_block.c
    )
    
    list(APPEND HDIFF_SOURCES
        ${ZSTD_PATH}/compress/fse_compress.c
        ${ZSTD_PATH}/compress/hist.c
        ${ZSTD_PATH}/compress/huf_compress.c
        ${ZSTD_PATH}/compress/zstd_compress.c
        ${ZSTD_PATH}/compress/zstd_compress_literals.c
        ${ZSTD_PATH}/compress/zstd_compress_sequences.c
        ${ZSTD_PATH}/compress/zstd_compress_superblock.c
        ${ZSTD_PATH}/compress/zstd_preSplit.c
        ${ZSTD_PATH}/compress/zstd_double_fast.c
        ${ZSTD_PATH}/compress/zstd_fast.c
        ${ZSTD_PATH}/compress/zstd_lazy.c
        ${ZSTD_PATH}/compress/zstd_ldm.c
        ${ZSTD_PATH}/compress/zstd_opt.c
    )
    if(MT)
        list(APPEND HDIFF_SOURCES
            ${ZSTD_PATH}/common/pool.c
            ${ZSTD_PATH}/common/threading.c
            ${ZSTD_PATH}/compress/zstdmt_compress.c
        )
    endif()
endif()

if(BZIP2 EQUAL 1)
    list(APPEND HPATCH_SOURCES
        ${BZ2_PATH}/blocksort.c
        ${BZ2_PATH}/bzlib.c
        ${BZ2_PATH}/compress.c
        ${BZ2_PATH}/crctable.c
        ${BZ2_PATH}/decompress.c
        ${BZ2_PATH}/huffman.c
        ${BZ2_PATH}/randtable.c
    )
endif()

if(ZLIB EQUAL 1)
    list(APPEND HPATCH_SOURCES
        ${ZLIB_PATH}/adler32.c
        ${ZLIB_PATH}/crc32.c
        ${ZLIB_PATH}/inffast.c
        ${ZLIB_PATH}/inflate.c
        ${ZLIB_PATH}/inftrees.c
        ${ZLIB_PATH}/trees.c
        ${ZLIB_PATH}/zutil.c
    )
    list(APPEND HDIFF_SOURCES ${ZLIB_PATH}/deflate.c)
endif()

# Add zlib sources to hdiffpatch when using source zlib and libdeflate
if(ZLIB EQUAL 1 AND LDEF EQUAL 1)
    list(APPEND HDIFF_SOURCES
        ${ZLIB_PATH}/adler32.c
        ${ZLIB_PATH}/crc32.c
        ${ZLIB_PATH}/inffast.c
        ${ZLIB_PATH}/inflate.c
        ${ZLIB_PATH}/inftrees.c
        ${ZLIB_PATH}/trees.c
        ${ZLIB_PATH}/zutil.c
    )
endif()

if(LDEF)
    list(APPEND HPATCH_SOURCES
        ${LDEF_PATH}/lib/deflate_decompress.c
        ${LDEF_PATH}/lib/utils.c
        ${LDEF_PATH}/lib/x86/cpu_features.c
    )
    list(APPEND HDIFF_SOURCES ${LDEF_PATH}/lib/deflate_compress.c)
endif()

# Unit test sources
set(UNIT_TEST_SOURCES
    test/unit_test.cpp
    libHDiffPatch/HDiff/private_diff/match_inplace.cpp
    libhsync/sync_client/dir_sync_client.cpp
    libhsync/sync_client/match_in_old.cpp
    libhsync/sync_client/sync_client.cpp
    libhsync/sync_client/sync_diff_data.cpp
    libhsync/sync_client/sync_info_client.cpp
    libhsync/sync_make/dir_sync_make.cpp
    libhsync/sync_make/match_in_new.cpp
    libhsync/sync_make/sync_info_make.cpp
    libhsync/sync_make/sync_make.cpp
)

# Create static library
add_library(hdiffpatch STATIC ${HDIFF_SOURCES})

# Create executables
if(ZLIB EQUAL 1 AND LDEF EQUAL 1)
    # Add zlib sources directly to hpatchz executable when using source zlib and libdeflate
    add_executable(hpatchz 
        hpatchz.c
        ${ZLIB_PATH}/adler32.c
        ${ZLIB_PATH}/crc32.c
        ${ZLIB_PATH}/inffast.c
        ${ZLIB_PATH}/inflate.c
        ${ZLIB_PATH}/inftrees.c
        ${ZLIB_PATH}/trees.c
        ${ZLIB_PATH}/zutil.c
    )
    # Also add zlib sources to hdiffz executable and VCDIFF wrapper sources
    add_executable(hdiffz 
        hdiffz.cpp
        hdiffz_import_patch.c
        ${ZLIB_PATH}/adler32.c
        ${ZLIB_PATH}/crc32.c
        ${ZLIB_PATH}/inffast.c
        ${ZLIB_PATH}/inflate.c
        ${ZLIB_PATH}/inftrees.c
        ${ZLIB_PATH}/trees.c
        ${ZLIB_PATH}/zutil.c
    )
    if(VCD)
        target_sources(hdiffz PRIVATE vcdiff_wrapper/vcdiff_wrapper.cpp vcdiff_wrapper/vcpatch_wrapper.c)
    endif()
    if(ZSTD EQUAL 1)
        target_sources(hdiffz PRIVATE 
            ${ZSTD_PATH}/common/debug.c
            ${ZSTD_PATH}/common/entropy_common.c
            ${ZSTD_PATH}/common/error_private.c
            ${ZSTD_PATH}/common/fse_decompress.c
            ${ZSTD_PATH}/common/xxhash.c
            ${ZSTD_PATH}/common/zstd_common.c
            ${ZSTD_PATH}/decompress/huf_decompress.c
            ${ZSTD_PATH}/decompress/zstd_ddict.c
            ${ZSTD_PATH}/decompress/zstd_decompress.c
            ${ZSTD_PATH}/decompress/zstd_decompress_block.c
            ${ZSTD_PATH}/compress/fse_compress.c
            ${ZSTD_PATH}/compress/hist.c
            ${ZSTD_PATH}/compress/huf_compress.c
            ${ZSTD_PATH}/compress/zstd_compress.c
            ${ZSTD_PATH}/compress/zstd_compress_literals.c
            ${ZSTD_PATH}/compress/zstd_compress_sequences.c
            ${ZSTD_PATH}/compress/zstd_compress_superblock.c
            ${ZSTD_PATH}/compress/zstd_preSplit.c
            ${ZSTD_PATH}/compress/zstd_double_fast.c
            ${ZSTD_PATH}/compress/zstd_fast.c
            ${ZSTD_PATH}/compress/zstd_lazy.c
            ${ZSTD_PATH}/compress/zstd_ldm.c
            ${ZSTD_PATH}/compress/zstd_opt.c
        )
        if(MT)
            target_sources(hdiffz PRIVATE
                ${ZSTD_PATH}/common/pool.c
                ${ZSTD_PATH}/common/threading.c
                ${ZSTD_PATH}/compress/zstdmt_compress.c
            )
        endif()
    endif()
else()
    # For static builds, include source files directly to avoid DLL dependencies
    add_executable(hpatchz hpatchz.c)
    add_executable(hdiffz hdiffz.cpp)
    
    # Add source files directly for static linking when using source builds
    if(ZLIB EQUAL 1)
        target_sources(hpatchz PRIVATE 
            ${ZLIB_PATH}/adler32.c
            ${ZLIB_PATH}/crc32.c
            ${ZLIB_PATH}/inffast.c
            ${ZLIB_PATH}/inflate.c
            ${ZLIB_PATH}/inftrees.c
            ${ZLIB_PATH}/zutil.c
        )
        target_sources(hdiffz PRIVATE 
            ${ZLIB_PATH}/adler32.c
            ${ZLIB_PATH}/crc32.c
            ${ZLIB_PATH}/inffast.c
            ${ZLIB_PATH}/inflate.c
            ${ZLIB_PATH}/inftrees.c
            ${ZLIB_PATH}/trees.c
            ${ZLIB_PATH}/zutil.c
        )
    endif()
    
    if(BZIP2 EQUAL 1)
        target_sources(hpatchz PRIVATE 
            ${BZIP2_PATH}/blocksort.c
            ${BZIP2_PATH}/bzlib.c
            ${BZIP2_PATH}/compress.c
            ${BZIP2_PATH}/crctable.c
            ${BZIP2_PATH}/decompress.c
            ${BZIP2_PATH}/huffman.c
            ${BZIP2_PATH}/randtable.c
        )
        target_sources(hdiffz PRIVATE 
            ${BZIP2_PATH}/blocksort.c
            ${BZIP2_PATH}/bzlib.c
            ${BZIP2_PATH}/compress.c
            ${BZIP2_PATH}/crctable.c
            ${BZIP2_PATH}/decompress.c
            ${BZIP2_PATH}/huffman.c
            ${BZIP2_PATH}/randtable.c
        )
    endif()
    
    if(ZSTD EQUAL 1)
        target_sources(hpatchz PRIVATE 
            ${ZSTD_PATH}/common/debug.c
            ${ZSTD_PATH}/common/entropy_common.c
            ${ZSTD_PATH}/common/error_private.c
            ${ZSTD_PATH}/common/fse_decompress.c
            ${ZSTD_PATH}/common/xxhash.c
            ${ZSTD_PATH}/common/zstd_common.c
            ${ZSTD_PATH}/decompress/huf_decompress.c
            ${ZSTD_PATH}/decompress/zstd_ddict.c
            ${ZSTD_PATH}/decompress/zstd_decompress.c
            ${ZSTD_PATH}/decompress/zstd_decompress_block.c
        )
        target_sources(hdiffz PRIVATE 
            ${ZSTD_PATH}/common/debug.c
            ${ZSTD_PATH}/common/entropy_common.c
            ${ZSTD_PATH}/common/error_private.c
            ${ZSTD_PATH}/common/fse_decompress.c
            ${ZSTD_PATH}/common/xxhash.c
            ${ZSTD_PATH}/common/zstd_common.c
            ${ZSTD_PATH}/decompress/huf_decompress.c
            ${ZSTD_PATH}/decompress/zstd_ddict.c
            ${ZSTD_PATH}/decompress/zstd_decompress.c
            ${ZSTD_PATH}/decompress/zstd_decompress_block.c
            ${ZSTD_PATH}/compress/fse_compress.c
            ${ZSTD_PATH}/compress/hist.c
            ${ZSTD_PATH}/compress/huf_compress.c
            ${ZSTD_PATH}/compress/zstd_compress.c
            ${ZSTD_PATH}/compress/zstd_compress_literals.c
            ${ZSTD_PATH}/compress/zstd_compress_sequences.c
            ${ZSTD_PATH}/compress/zstd_compress_superblock.c
            ${ZSTD_PATH}/compress/zstd_preSplit.c
            ${ZSTD_PATH}/compress/zstd_double_fast.c
            ${ZSTD_PATH}/compress/zstd_fast.c
            ${ZSTD_PATH}/compress/zstd_lazy.c
            ${ZSTD_PATH}/compress/zstd_ldm.c
            ${ZSTD_PATH}/compress/zstd_opt.c
        )
        if(MT)
            target_sources(hpatchz PRIVATE
                ${ZSTD_PATH}/common/pool.c
                ${ZSTD_PATH}/common/threading.c
                ${ZSTD_PATH}/compress/zstdmt_compress.c
            )
            target_sources(hdiffz PRIVATE
                ${ZSTD_PATH}/common/pool.c
                ${ZSTD_PATH}/common/threading.c
                ${ZSTD_PATH}/compress/zstdmt_compress.c
            )
        endif()
    endif()
    
    if(VCD)
        target_sources(hdiffz PRIVATE vcdiff_wrapper/vcdiff_wrapper.cpp vcdiff_wrapper/vcpatch_wrapper.c)
    endif()
endif()
add_executable(unit_test ${UNIT_TEST_SOURCES})



# Link libraries
if(ZLIB EQUAL 2)
    target_link_libraries(hpatchz ZLIB::ZLIB)
    target_link_libraries(hdiffpatch ZLIB::ZLIB)
    target_link_libraries(hdiffz ZLIB::ZLIB)
endif()

# Only link system libraries for BZIP2 and ZSTD
if(BZIP2 EQUAL 2)
    target_link_libraries(hpatchz BZip2::BZip2)
    target_link_libraries(hdiffpatch BZip2::BZip2)
    target_link_libraries(hdiffz BZip2::BZip2)
endif()

if(ZSTD EQUAL 2)
    target_link_libraries(hpatchz zstd)
    target_link_libraries(hdiffpatch zstd)
    target_link_libraries(hdiffz zstd)
endif()

if(LZMA GREATER 0)
    target_link_libraries(hpatchz lzma)
    target_link_libraries(hdiffpatch lzma)
    target_link_libraries(hdiffz lzma)
endif()

if(LDEF EQUAL 2)
    target_link_libraries(hpatchz libdeflate_static)
    target_link_libraries(hdiffpatch libdeflate_static)
    target_link_libraries(hdiffz libdeflate_static)
    target_link_libraries(unit_test libdeflate_static)
endif()

if(MT)
    find_package(Threads REQUIRED)
    target_link_libraries(hpatchz Threads::Threads)
    target_link_libraries(hdiffpatch Threads::Threads)
    target_link_libraries(hdiffz Threads::Threads)
    target_link_libraries(unit_test Threads::Threads)
endif()

if(STATIC_CPP AND NOT WIN32)
    target_link_libraries(hdiffz -static-libstdc++)
    target_link_libraries(unit_test -static-libstdc++)
endif()

if(STATIC_C AND NOT WIN32)
    target_link_libraries(hpatchz -static)
    target_link_libraries(hdiffz -static)
    target_link_libraries(unit_test -static)
endif()

if(NOT PIE EQUAL 0)
    if(PIE EQUAL -1)
        target_link_libraries(hpatchz -no-pie)
        target_link_libraries(hdiffz -no-pie)
        target_link_libraries(unit_test -no-pie)
    endif()
endif()

# Link hdiffpatch library to executables
target_link_libraries(hpatchz hdiffpatch)
target_link_libraries(hdiffz hdiffpatch)
target_link_libraries(unit_test hdiffpatch)

# Set link libraries for hdiffpatch
if(LDEF)
    target_link_libraries(hdiffpatch libdeflate_static)
endif()

# Installation
install(TARGETS hdiffz hpatchz
    RUNTIME DESTINATION bin
)

install(TARGETS hdiffpatch
    ARCHIVE DESTINATION lib
)

# Print configuration summary
message(STATUS "HDiffPatch Configuration:")
message(STATUS "  Directory Diff: ${DIR_DIFF}")
message(STATUS "  Multi-threading: ${MT}")
message(STATUS "  libdeflate: ${LDEF}")
message(STATUS "  ZLIB: ${ZLIB} (0=none, 1=source, 2=system)")
message(STATUS "  BZIP2: ${BZIP2} (0=none, 1=source, 2=system)")
message(STATUS "  LZMA: ${LZMA} (0=none, 1=source, 2=system)")
message(STATUS "  ZSTD: ${ZSTD} (0=none, 1=source, 2=system)")
message(STATUS "  VCDIFF: ${VCD}")
message(STATUS "  BSDIFF: ${BSD}")
message(STATUS "  MD5: ${MD5}")
message(STATUS "  xxHash: ${XXH}")
message(STATUS "  ARM64 ASM: ${ARM64ASM}")
message(STATUS "  Minimum size: ${MINS}")
message(STATUS "  Static C++: ${STATIC_CPP}")
message(STATUS "  Static C: ${STATIC_C}")
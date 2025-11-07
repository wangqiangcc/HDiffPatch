# LZMA CMakeLists.txt
# Template for LZMA library
# Clone from: https://github.com/sisong/lzma.git

# Check if source files exist
if(EXISTS "${CMAKE_CURRENT_SOURCE_DIR}/LzmaDec.c")
    set(LZMA_SOURCES
        LzmaDec.c
        Lzma2Dec.c
        7zStream.c
        CpuArch.c
        Alloc.c
    )

    set(LZMA_ENCODER_SOURCES
        LzFind.c
        LzFindOpt.c
        LzmaEnc.c
        Lzma2Enc.c
    )

    set(LZMA_MT_SOURCES
        LzFindMt.c
        MtCoder.c
        MtDec.c
        Threads.c
    )

    set(LZMA_VCD_SOURCES
        7zCrc.c
        7zCrcOpt.c
        Bra.c
        Bra86.c
        BraIA64.c
        Delta.c
        Sha256.c
        Sha256Opt.c
        Xz.c
        XzCrc64.c
        XzCrc64Opt.c
        XzDec.c
        XzEnc.c
    )

    # Base LZMA library
    add_library(lzma STATIC ${LZMA_SOURCES})
    target_include_directories(lzma PUBLIC ${CMAKE_CURRENT_SOURCE_DIR})
    
    # LZMA encoder library
    add_library(lzma_enc STATIC ${LZMA_ENCODER_SOURCES})
    target_include_directories(lzma_enc PUBLIC ${CMAKE_CURRENT_SOURCE_DIR})
    
    # Multithreading support
    if(EXISTS "${CMAKE_CURRENT_SOURCE_DIR}/MtDec.c")
        target_sources(lzma PRIVATE ${LZMA_MT_SOURCES})
        target_sources(lzma_enc PRIVATE ${LZMA_MT_SOURCES})
    endif()
    
    # VCDIFF support
    if(EXISTS "${CMAKE_CURRENT_SOURCE_DIR}/7zCrc.c")
        target_sources(lzma PRIVATE ${LZMA_VCD_SOURCES})
        target_sources(lzma_enc PRIVATE ${LZMA_VCD_SOURCES})
    endif()
    
    # Set properties
    set_target_properties(lzma lzma_enc PROPERTIES
        C_STANDARD 99
        POSITION_INDEPENDENT_CODE ON
    )
    
    # Link libraries
    target_link_libraries(lzma_enc lzma)
else()
    message(WARNING "LZMA source files not found. Please clone the repository:")
    message(WARNING "git clone https://github.com/sisong/lzma.git ${CMAKE_CURRENT_SOURCE_DIR}/..")
    
    # Create dummy targets
    add_library(lzma INTERFACE)
    add_library(lzma_enc INTERFACE)
endif()
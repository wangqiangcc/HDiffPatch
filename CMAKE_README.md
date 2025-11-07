# HDiffPatch CMake Build System

This directory contains a CMake-based build system for HDiffPatch, providing an alternative to the traditional Makefile approach.

## Quick Start

```bash
# Clone the repository (if not already done)
git clone https://github.com/sisong/HDiffPatch.git
cd HDiffPatch

# Create build directory
mkdir build
cd build

# Configure with CMake
cmake ..

# Build
make -j$(nproc)

# Install (optional)
sudo make install
```

## Dependencies

The CMake build system supports both bundled (source) and system libraries for third-party dependencies. Dependencies are organized in the `third_party` directory.

### Automatic Dependency Download (Recommended)

```bash
# Download all recommended dependencies
cd third_party

# ZLIB
git clone https://github.com/sisong/zlib.git

# BZIP2  
git clone https://github.com/sisong/bzip2.git

# LZMA
git clone https://github.com/sisong/lzma.git

# ZSTD
git clone https://github.com/sisong/zstd.git

# libdeflate
git clone https://github.com/sisong/libdeflate.git

# MD5
git clone https://github.com/sisong/libmd5.git

# xxHash
git clone https://github.com/sisong/xxHash.git
```

### System Dependencies (Alternative)

Instead of building from source, you can use system packages:

```bash
# Ubuntu/Debian
sudo apt-get install zlib1g-dev libbz2-dev liblzma-dev libzstd-dev

# CentOS/RHEL/Fedora
sudo yum install zlib-devel bzip2-devel xz-devel libzstd-devel

# macOS
brew install zlib bzip2 xz zstd
```

## Configuration Options

The CMake build system provides all the configuration options available in the original Makefile:

### Core Features
- `DIR_DIFF`: Enable directory diff support (default: ON)
- `MT`: Enable multi-threading support (default: ON)
- `LDEF`: Use libdeflate (default: ON)
- `VCD`: Enable VCDIFF support (default: ON)
- `BSD`: Enable BSDIFF support (default: ON)
- `MD5`: Enable MD5 checksum support (default: ON)
- `XXH`: Enable xxHash checksum support (default: ON)

### Compression Libraries
- `ZLIB`: ZLIB support (0=none, 1=source, 2=system, default: auto)
- `BZIP2`: BZIP2 support (0=none, 1=source, 2=system, default: auto)
- `LZMA`: LZMA support (0=none, 1=source, 2=system, default: 1)
- `ZSTD`: ZSTD support (0=none, 1=source, 2=system, default: 1)

### Optimization Options
- `ARM64ASM`: Enable ARM64 assembly optimizations for LZMA (default: OFF)
- `USE_CRC_EMU`: Use software CRC for LZMA (default: OFF)
- `M32`: Build with -m32 flag (default: OFF)
- `MINS`: Build for minimum size (default: OFF)

### Linking Options
- `STATIC_CPP`: Static link C++ standard library (default: OFF)
- `STATIC_C`: Static link C runtime (default: OFF)
- `PIE`: Position independent executable (default: 0)
- `ATOMIC_U64`: Support atomic uint64 (default: ON)

## Build Examples

### Basic Build
```bash
cmake ..
make -j$(nproc)
```

### Build with Specific Features
```bash
cmake -DDIR_DIFF=ON -DMT=ON -DVCD=ON -DBSD=ON ..
make -j$(nproc)
```

### Build with System Libraries
```bash
cmake -DZLIB=2 -DBZIP2=2 -DLZMA=2 -DZSTD=2 ..
make -j$(nproc)
```

### Minimum Size Build
```bash
cmake -DMINS=ON -DSTATIC_CPP=ON -DSTATIC_C=ON ..
make -j$(nproc)
```

### Debug Build
```bash
cmake -DCMAKE_BUILD_TYPE=Debug ..
make -j$(nproc)
```

### Cross-Compilation
```bash
cmake -DCMAKE_TOOLCHAIN_FILE=../cmake/toolchain-arm64.cmake ..
make -j$(nproc)
```

## Output Files

After building, you'll find:
- `libhdiffpatch.a`: Static library
- `hpatchz`: Patch application tool
- `hdiffz`: Diff creation tool
- `unit_test`: Unit test executable

## Installation

```bash
# Install to system (default: /usr/local)
sudo make install

# Install to custom prefix
cmake -DCMAKE_INSTALL_PREFIX=/opt/hdiffpatch ..
make install
```

## Platform Support

The CMake build system supports:
- Linux (x86_64, ARM64, ARMv7)
- macOS (x86_64, Apple Silicon)
- Windows (MSVC, MinGW)
- FreeBSD
- Android (via NDK)
- iOS (via Xcode)

## Troubleshooting

### Missing Dependencies
If you see warnings about missing source files, make sure to clone the third-party repositories as shown above.

### System Library Issues
If CMake can't find system libraries, you may need to specify their locations:
```bash
cmake -DZLIB_ROOT=/opt/zlib -DLZMA_ROOT=/opt/lzma ..
```

### Build Errors
Check the CMake configuration output for any missing dependencies or configuration issues. The build system will provide helpful error messages for common problems.

## Migration from Makefile

The CMake build system is designed to be a drop-in replacement for the Makefile. All major features and options are supported. Key differences:

1. **Automatic dependency detection**: CMake automatically detects available system libraries
2. **Better cross-platform support**: Native Windows support via MSVC
3. **IDE integration**: Generate project files for Visual Studio, Xcode, etc.
4. **Package management**: Easy integration with package managers

## Contributing

When adding new features or dependencies:
1. Update the main CMakeLists.txt with new options
2. Add corresponding third-party CMakeLists.txt files
3. Test with both bundled and system libraries
4. Update this README with new configuration options

## License

This CMake build system maintains the same license as the original HDiffPatch project.
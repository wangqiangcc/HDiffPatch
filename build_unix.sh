#!/bin/bash
# HDiffPatch CMake Build Script for Unix/Linux/macOS
# This script helps build HDiffPatch using CMake

set -e

echo "HDiffPatch CMake Build Script"
echo "============================="
echo

# Check if CMake is available
if ! command -v cmake &> /dev/null; then
    echo "ERROR: CMake not found!"
    echo "Please install CMake:"
    echo "  Ubuntu/Debian: sudo apt-get install cmake"
    echo "  CentOS/RHEL: sudo yum install cmake"
    echo "  macOS: brew install cmake"
    echo "  Or download from: https://cmake.org/download/"
    exit 1
fi

echo "Found CMake:"
cmake --version
echo

# Check for C++ compiler
if ! command -v g++ &> /dev/null && ! command -v clang++ &> /dev/null; then
    echo "ERROR: No C++ compiler found!"
    echo "Please install GCC or Clang:"
    echo "  Ubuntu/Debian: sudo apt-get install build-essential"
    echo "  CentOS/RHEL: sudo yum groupinstall 'Development Tools'"
    echo "  macOS: Install Xcode Command Line Tools"
    exit 1
fi

# Create build directory
if [ ! -d "build" ]; then
    echo "Creating build directory..."
    mkdir build
fi

cd build

# Configure with CMake
echo "Configuring project with CMake..."

# Try to use Ninja if available, otherwise use Make
if command -v ninja &> /dev/null; then
    cmake .. -G Ninja
    BUILD_TOOL="ninja"
else
    cmake ..
    BUILD_TOOL="make"
fi

if [ $? -ne 0 ]; then
    echo
    echo "ERROR: CMake configuration failed!"
    echo
    echo "Troubleshooting:"
    echo "1. Install required third-party dependencies (see CMAKE_README.md)"
    echo "2. Check that all paths are correct"
    echo "3. Install development packages for system libraries"
    exit 1
fi

echo
echo "Configuration successful!"
echo

# Build the project
echo "Building project with $BUILD_TOOL..."
if [ "$BUILD_TOOL" = "ninja" ]; then
    ninja
else
    make -j$(nproc)
fi

if [ $? -ne 0 ]; then
    echo
    echo "ERROR: Build failed!"
    echo
    echo "Troubleshooting:"
    echo "1. Check the error messages above"
    echo "2. Make sure all dependencies are properly installed"
    echo "3. Try building with fewer parallel jobs: make -j1"
    exit 1
fi

echo
echo "✅ Build successful!"
echo
echo "Built files:"
echo "  - build/libhdiffpatch.a (static library)"
echo "  - build/hpatchz (patch application tool)"
echo "  - build/hdiffz (diff creation tool)"
echo "  - build/unit_test (unit tests)"
echo

# Optional: Run tests
if [ -f "unit_test" ]; then
    echo "Running unit tests..."
    ./unit_test
    echo
fi

echo "Installation (optional):"
echo "  sudo make install"
echo
echo "Build options for next time:"
echo "  - Debug build: cmake -DCMAKE_BUILD_TYPE=Debug .."
echo "  - With specific features: cmake -DDIR_DIFF=ON -DMT=ON .."
echo "  - With system libraries: cmake -DZLIB=2 -DBZIP2=2 .."
echo "  - Minimum size build: cmake -DMINS=ON -DSTATIC_CPP=ON .."
echo
echo "For more options, see CMAKE_README.md"
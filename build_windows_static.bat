@echo off
REM HDiffPatch CMake Build Script for Windows
REM This script helps build HDiffPatch using CMake on Windows

echo HDiffPatch CMake Build Script
echo =============================
echo.

REM Check if CMake is available
where cmake >nul 2>nul
if %errorlevel% neq 0 (
    echo ERROR: CMake not found!
    echo Please install CMake from: https://cmake.org/download/
    echo.
    echo You can also use Visual Studio 2019+ which includes CMake support.
    exit /b 1
)

echo Found CMake:
cmake --version
echo.

REM Create build_static directory
if not exist "build_static" (
    echo Creating build_static directory...
    mkdir build_static
)

cd build_static

REM Configure with CMake
echo Configuring project with CMake...
cmake .. -G "Visual Studio 16 2019" -A x64 -DMT=ON  -DSTATIC_CPP=ON -DSTATIC_C=ON -DZLIB=1 -DBZIP2=1 -DZSTD=1 -DLDEF=1

if %errorlevel% neq 0 (
    echo.
    echo ERROR: CMake configuration failed!
    echo.
    echo Troubleshooting:
    echo 1. Make sure you have Visual Studio 2019 or later installed
    echo 2. Install required third-party dependencies (see CMAKE_README.md)
    echo 3. Check that all paths are correct
    exit /b 1
)

echo.
echo Configuration successful!
echo.
echo To build the project:
echo   1. Open build\HDiffPatch.sln in Visual Studio
echo   2. Select Release configuration
echo   3. Build the solution (F7)
echo.
echo Or build from command line:
echo   cmake --build . --config Release
echo.
echo Build options:
echo   - Debug build: cmake --build . --config Debug
echo   - With specific features: cmake .. -DDIR_DIFF=ON -DMT=ON
echo   - With system libraries: cmake .. -DZLIB=2 -DBZIP2=2
echo.
echo For more options, see CMAKE_README.md
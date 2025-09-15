#!/bin/bash

# Exit immediately if a command exits with a non-zero status.
set -e
echo "-----System Update-----"
sudo apt-get update && sudo apt-get dist-upgrade -y

echo "--- Starting Blender ARM64 Portable Build ---"

# Navigate to the Blender source directory mounted inside the container
cd /blender-git/blender

echo "--- Step 1/6: Ensuring Git LFS files are present ---"
# Although you've cloned, this ensures any large file pointers are resolved
git lfs install
git lfs update --force
git lfs pull

echo "--- Step 2/6: Installing Linux package dependencies ---"
# Run the official script to install all system-level dependencies.
# This requires sudo, which is why our Docker user is configured for it.

sudo ./build_files/build_environment/install_linux_packages.py 
#sudo apt update
#sudo rm -rf /var/lib/apt/lists/* 
sudo apt-get clean && sudo apt-get autoclean
echo "--- Step 3/6: Downloading pre-compiled libraries ---"
# This fetches the libraries provided by the Blender Foundation
#make deps BUILD_CMAKE_ARGS=" -DWITH_CYCLES_CUDA_BINARIES=OFF -DWITH_CYCLES_DEVICE_CUDA=OFF -DWITH_CYCLES_DEVICE_OPTIX=OFF"
# Replace the make deps line with:
make deps BUILD_CMAKE_ARGS=" -DWITH_CYCLES_CUDA_BINARIES=OFF -DWITH_CYCLES_DEVICE_CUDA=OFF -DWITH_CYCLES_DEVICE_OPTIX=OFF -DWITH_OPENSSL_SYSTEM=ON"

# Fetch all submodules and dependencies (without using precompiled binaries)
#git submodule update --init --recursive

echo "--- Step 4/6: Configuring the build with CMake ---"
# Create the build directory and navigate into it
mkdir -p ../build_arm64
cd ../build_arm64

# Run CMake with flags to disable NVIDIA features and enable a portable build
cmake ../blender \
      -DWITH_CYCLES_DEVICE_CUDA=OFF \
      -DWITH_CYCLES_DEVICE_OPTIX=OFF \
      -DWITH_CYCLES_CUDA_BINARIES=OFF \
      -DWITH_NVIDIA_DRIVER_API=OFF \
      -DCMAKE_BUILD_TYPE=Release \
      -DWITH_LIBS_PRECOMPILED=OFF \
      -DWITH_INSTALL_PORTABLE=ON

echo "--- Step 5/6: Compiling Blender (this will take a while) ---"
# Compile using all available processor cores
make -j$(nproc)

echo "--- Step 6/6: Creating the portable installation package ---"
# This collects all necessary files into an 'install' subdirectory
make install

echo "--- Build Complete! ---"
echo "Your portable Blender can be found in the 'blender-git/build_arm64/install' directory on your host machine."

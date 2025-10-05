#!/bin/bash

# Exit immediately if a command exits with a non-zero status.
set -e
echo "-----System Setup-----"


# WorkAround Current version dont provide required stable config 
#mkdir -p /usr/share/wayland-protocols/stable/tablet/
#cp /usr/share/wayland-protocols/unstable/tablet/tablet-unstable-v2.xml /usr/share/wayland-protocols/stable/tablet/tablet-v2.xml
#cp /blender-git/glPatchTable.h /usr/local/include/opensubdiv/osd/glPatchTable.h
#cp /blender-git/glVertexBuffer.h /usr/local/include/opensubdiv/osd/glVertexBuffer.h

#export MATERIALX_ROOT_DIR="/blender-git/materialx"
#export MATERIALX_INCLUDE_DIR="/blender-git/materialx"
#export MATERIALX_LIBRARY="/blender-git/materialx/lib/"
export WITH_CYCLES_DEVICE_CUDA="OFF"
export WITH_CYCLES_DEVICE_OPTIX="OFF"
#export PATH="$PATH:/blender-git/materialx/lib/"


echo "-------------------------------------------------------------"

echo "1> Added Materialx Successfully"
export EMBREE_ROOT_DIR="/usr/local"
export PYTHON_NUMPY_INCLUDE_DIR=$(python3 -c "import numpy; print(numpy.get_include())")
export SPACENAV_LIBRARY="/usr/lib/aarch64-linux-gnu/libspnav.so"

#whereis embree
#whereis embree4
echo "Embree installed"


echo "-------------------------------------------------------------"
 
echo "------------Building Blender ARM64 Portable Build------------"

echo "--- Starting Blender ARM64 Portable Build ---"

# Navigate to the Blender source directory mounted inside the container
# Blender
#echo "--- Blender ARM64 Portable Build ---"
#git config --global --add safe.directory /blender-git/blender
 
if [ ! -d "/blender-git/blender" ] || [ -z "$(ls -A /blender-git/blender)" ]; then
    echo "Cloning Blender source code into /blender-git/blender..."
    git clone -b v4.5.3 https://projects.blender.org/blender/blender.git /blender-git/blender
    #cd /blender-git/blender
    #git checkout tags/v4.5.3 -b v4.5.3
else
    echo "Blender source already exists. Checking out to tag v4.5.3..."
    #cd /blender-git/blender
   # git fetch --all --tags
    #git checkout tags/v4.5.3 -b v4.5.3 || git checkout v4.5.3
fi

echo "--- Step 1: Ensuring Git LFS files ---"
cd /blender-git/blender
make update

echo "--- Step 2: Installing Linux dependencies ---"
# (Uncomment and adjust as needed)
# All ready installed
# sudo ./build_files/build_environment/install_linux_packages.py

echo "--- Step 3: Downloading pre-compiled libraries ---"


echo "--- Step 4: Configuring build ---"

make ninja  BUILD_CMAKE_ARGS="-DWITH_CYCLES_DEVICE_CUDA=OFF -DWITH_CYCLES_DEVICE_HIP=OFF -DWITH_CYCLES_DEVICE_OPTIX=OFF -DWITH_CYCLES_CUDA_BINARIES=OFF -DSDL2_INCLUDE_DIRS=/usr/include/SDL2/ -DSSE2NEON_INCLUDE_DIR=/usr/local/include/sse2neon  -DWITH_VULKAN_BACKEND=OFF -DPYTHON_NUMPY_INCLUDE_DIRS=/usr/local/lib/python3.11/site-packages/numpy/_core/include -DPYTHON_NUMPY_INCLUDE_DIR=/usr/local/lib/python3.11/site-packages/numpy/_core/include  -DWITH_INSTALL_PORTABLE=ON"
# This fetches the libraries provided by the Blender Foundation
#make deps BUILD_CMAKE_ARGS=" -DWITH_CYCLES_CUDA_BINARIES=OFF -DWITH_CYCLES_DEVICE_CUDA=OFF -DWITH_CYCLES_DEVICE_OPTIX=OFF"
# Replace the make deps line with:

#make deps BUILD_CMAKE_ARGS=" -DWITH_CYCLES_CUDA_BINARIES=OFF -DWITH_CYCLES_DEVICE_CUDA=OFF -DWITH_CYCLES_DEVICE_OPTIX=OFF -DWITH_NVIDIA_DRIVER_API=OFF -DWITH_OPENSSL_SYSTEM=ON"

# # Run CMake with flags to disable NVIDIA features and enable a portable build
# cmake ../blender \
#       -DWITH_CYCLES_DEVICE_CUDA=OFF \
#       -DWITH_CYCLES_DEVICE_OPTIX=OFF \
#       -DWITH_CYCLES_CUDA_BINARIES=OFF \
#       -DWITH_NVIDIA_DRIVER_API=OFF \
#       -DCMAKE_BUILD_TYPE=Release \
#       -DWITH_LIBS_PRECOMPILED=OFF \
#       -DWITH_INSTALL_PORTABLE=ON

echo "--- Step 5: Compiling Blender ---"
make -j$(nproc)

echo "--- Step 6: Creating portable install package ---"
make install

echo "--- Build Complete! ---"
echo "Portable Blender is in 'blender-git/build_arm64/install'." 
cmake --install .


echo "-------------------------------------------------------------"
  
echo "--- Build Complete! ---"
echo "Your portable Blender can be found in the 'blender-git/build_arm64/install' directory on your host machine."


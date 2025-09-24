#!/bin/bash

# Exit immediately if a command exits with a non-zero status.
set -e
echo "-----System Setup-----"
#sudo apt-get update && sudo apt-get dist-upgrade -y
whereis python

# echo "-----------------Added Materialx Pre BUild------------------"
# if [ ! -d "/blender-git/materialx" ]; then
#     echo "Cloning MaterialX"
#     wget https://github.com/AcademySoftwareFoundation/MaterialX/releases/download/v1.39.4/MaterialX_Linux_GCC_14_Python312.zip -O /tmp/materialx.zip

#     unzip /tmp/materialx.zip -d /blender-git/materialx
#     rm  /tmp/materialx.zip
# fi

export MaterialX_DIR="/blender-git/materialx/"



#export MATERIALX_ROOT_DIR="/blender-git/materialx"
#export MATERIALX_INCLUDE_DIR="/blender-git/materialx"
#export MATERIALX_LIBRARY="/blender-git/materialx/lib/"
export WITH_CYCLES_DEVICE_CUDA="OFF"
export WITH_CYCLES_DEVICE_OPTIX="OFF"
#export PATH="$PATH:/blender-git/materialx/lib/"
echo "1> Added Materialx Successfully"

#echo "-------------------------TBB---------------------------------"

# # TBB
# if [ ! -d "/blender-git/tbb" ]; then
#     echo "Cloning TBB"
#     git clone https://github.com/uxlfoundation/oneTBB --branch v2022.2.0 /blender-git/tbb
# fi
# cd /blender-git/tbb
# # Create build directory
# mkdir -p build && cd build
# # Configure (disable tests, set Release build, custom install prefix optional)
# cmake -DCMAKE_BUILD_TYPE=Release -DTBB_TEST=OFF -DCMAKE_INSTALL_PREFIX=/usr/local ..
# # Build
# cmake --build . -j$(nproc)
# # Install (may need sudo depending on prefix)
# cmake --install .
# #export TBB_ROOT_DIR="/blender-git/tbb"
echo "------------------------PipeWire-------------------------------------"
#pwd
#ls -A /blender-git/pipewire
#find /blender-git/pipewire
# PipeWire
if [ ! -d "/blender-git/pipewire" ] || [ -z "$(ls -A /blender-git/pipewire)" ]; then
    echo "Downloading PipeWire v1.4.8"
    git clone https://github.com/PipeWire/pipewire --branch 1.4.8 /blender-git/pipewire
fi

cd /blender-git/pipewire

# Create build directory
mkdir -p build && cd build

# Configure (set Release build, install prefix to /usr/local)
meson setup . .. --buildtype=release --prefix=/usr/local  -Dtests=disabled -Ddocs=disabled -Dexamples=disabled -Dinstalled_tests=disabled  \
    -Dlibcamera=disabled -Dcompress-offload=disabled -Djack=disabled  -Decho-cancel-webrtc=disabled \
    -Daudiotestsrc=disabled -Dsnap=disabled
    #
     #-Daudioconvert=disabled -Daudiomixer=disabled -Dspa-plugins=disabled \
     #-Dlibcamera=disabled -Dsystemd=disabled -Dbluez5=disabled  

 
#     
# Build
meson compile -C .

# Install (may need sudo depending on prefix)
meson install -C .

echo "-------------------------------------------------------------"
# Embree

# echo "--- Building Embree ---"
# if [ ! -d "/blender-git/embree" ]; then
#     git clone --branch v4.4.0 --single-branch https://github.com/RenderKit/embree.git /blender-git/embree
# fi
# cd /blender-git/embree
# mkdir -p build && cd build
# Interactive 
# ccmake ..
# Configure with cmake directly (non-interactive)
# cmake .. \
#   -DCMAKE_BUILD_TYPE=Release \
#   -DEMBREE_TUTORIALS=OFF \
#   -DEMBREE_ISPC_SUPPORT=OFF \
#   -DEMBREE_TUTORIALS_GLFW=OFF \  
#   -DCMAKE_CXX_COMPILER=g++ \
#   -DCMAKE_C_COMPILER=gcc
#  -DEMBREE_TESTING_INSTALL_TESTS=OFF \
#  -DCMAKE_INSTALL_PREFIX=/blender-git/embree/install \

# make -j8
# make install

export EMBREE_ROOT_DIR="/usr/local"
export PYTHON_NUMPY_INCLUDE_DIR=$(python3 -c "import numpy; print(numpy.get_include())")
export SPACENAV_LIBRARY="/usr/lib/aarch64-linux-gnu/libspnav.so"

whereis embree
whereis embree4
echo "Embree installed"


#export PYTHON_NUMPY_INCLUDE_DIRS=/usr/local/
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
# sudo ./build_files/build_environment/install_linux_packages.py

echo "--- Step 3: Downloading pre-compiled libraries ---"
# (Uncomment and adjust as needed)
# make deps BUILD_CMAKE_ARGS="..."
#ln -s /usr/local/lib/python3/dist-packages/numpy/ /usr/local/lib/python3/dist-packages/numpy/

echo "--- Step 4: Configuring build ---"
make ninja  BUILD_CMAKE_ARGS="-DWITH_CYCLES_DEVICE_CUDA=OFF -DWITH_CYCLES_DEVICE_HIP=OFF -DWITH_CYCLES_DEVICE_OPTIX=OFF -DWITH_CYCLES_CUDA_BINARIES=OFF -DSDL2_INCLUDE_DIRS=/usr/include/SDL2/  -DPYTHON_NUMPY_INCLUDE_DIRS=/usr/local/lib/python3.11/site-packages/numpy/_core/include  -DWITH_INSTALL_PORTABLE=ON"
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


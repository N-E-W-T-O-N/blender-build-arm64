#!/bin/bash

#docker run -it -v $(pwd)/install_usd.sh:/install.sh:rw -v $(pwd)/OpenUSD:/OpenUSD --workdir / --entrypoint /install.sh --platform linux/arm64  newton2022/blender-builder:merge

if [ ! -d /OpenUSD ]; then
    git clone https://github.com/PixarAnimationStudios/OpenUSD.git -b v25.11 --depth=1 /OpenUSD
fi

mkdir -p /OpenUSD/build
cd /OpenUSD/build

# cd /OpenUSD
# /opt/venv/bin/python /OpenUSD/build_scripts/build_usd.py \
#   --build-monolithic \
#   --python \
#   --no-usdview \
#   --no-tools \
#   --no-examples \
#   --no-tests \
#   --no-tutorials \
#   --no-docs \
#   --no-python-docs \
#   --no-alembic \
#   --no-openvdb \
#   --materialx \
#   --no-draco \
#   --no-prman \
#   --no-ptex \
#   --no-vulkan \
#   --embree \
#   --openimageio \
#   --opencolorio \
#   --cmake-build-args="-DCMAKE_CXX_FLAGS=-Wno-error=stringop-overflow" \
#   --jobs $(nproc) \
#   /usr/local





cmake --build . && cmake --install .
  
# -DEMBREE_INCLUDE_DIR=/usr/local/include/embree3
#-DEMBREE_LIBRARY=/usr/local/lib/libembree4.so
# cmake .. -GNinja -DCMAKE_INSTALL_PREFIX=/usr/local -DCMAKE_CXX_FLAGS="-Wno-error=stringop-overflow " -DCMAKE_BUILD_TYPE=Release -DBUILD_SHARED_LIBS=ON -DTBB_ROOT=/usr/local  \
#   -DMaterialX_ROOT=/usr/local -DPXR_BUILD_USD_TOOLS=OFF -DPXR_ENABLE_GL_SUPPORT=ON -DPXR_BUILD_EMBREE_PLUGIN=ON -DPXR_BUILD_ALEMBIC_PLUGIN=ON -DPXR_ENABLE_PYTHON_SUPPORT=ON \
#  -DPXR_ENABLE_OPENVDB_SUPPORT=ON -DPXR_BUILD_OPENCOLORIO_PLUGIN=ON -DPXR_ENABLE_MATERIALX_SUPPORT=ON -DPXR_BUILD_OPENIMAGEIO_PLUGIN=ON -DPXR_BUILD_EXEC=OFF -DPXR_BUILD_TESTS=OFF -DPXR_BUILD_ANIMX_TESTS=OFF -DPXR_BUILD_DRACO_PLUGIN=OFF \
#  -DPXR_BUILD_PRMAN_PLUGIN=OFF -DPXR_BUILD_USDVIEW=OFF -DPXR_BUILD_EXAMPLES=OFF -DPXR_BUILD_TUTORIALS=OFF -DPXR_ENABLE_OSL_SUPPORT=OFF -DPXR_BUILD_DOCUMENTATION=OFF -DPXR_BUILD_USD_VALIDATION=OFF -DPXR_BUILD_HTML_DOCUMENTATION=OFF \
#  -DPXR_BUILD_PYTHON_DOCUMENTATION=OFF -DPXR_ENABLE_HDF5_SUPPORT=OFF -DPXR_ENABLE_METAL_SUPPORT=OFF -DPXR_ENABLE_PRECOMPILED_HEADERS=OFF -DPXR_ENABLE_PTEX_SUPPORT=OFF -DPXR_ENABLE_VULKAN_SUPPORT=OFF -DPXR_HEADLESS_TEST_MODE=OFF \
#  -DPXR_PREFER_SAFETY_OVER_SPEED=OFF -DPXR_STRICT_BUILD_MODE=OFF

# cmake --build .

# cmake --install .

# rm -rf /tmp/OpenSubdiv
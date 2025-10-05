# Stage 1: Use your existing blender-build as base
FROM newton2022/blender-builder:pre AS blender-base



# No need to build Imath: libimath-dev is already installed and will be found by CMake
# ---------------------------------------------------------------------- 
# 16 OpenUSd
# Build OpenUSD v25.05.01 with cache mount
#RUN echo "Building OpenUSD v25.08" && \
#    git clone https://github.com/PixarAnimationStudios/OpenUSD/ -b v25.08 --depth=1 /tmp/OpenUSD && \
#    mkdir -p /tmp/OpenUSD/build
    
RUN --mount=type=bind,source=build/OpenUSD,target=/tmp/OpenUSD,rw \ 
      cd /tmp/OpenUSD/build && \    
      cmake .. -GNinja -DCMAKE_INSTALL_PREFIX=/usr/local \
      -DCMAKE_CXX_FLAGS="-Wno-error=stringop-overflow " \
      -DCMAKE_BUILD_TYPE=Release \
      -DBUILD_SHARED_LIBS=ON \
      -DTBB_ROOT=/usr/local \
      -DEMBREE_INCLUDE_DIR=/usr/local/include/embree3 \
      -DEMBREE_LIBRARY=/usr/local/lib/libembree4.so \
      -DMaterialX_ROOT=/usr/local \
      -DPXR_BUILD_USD_TOOLS=ON  \
      -DPXR_ENABLE_GL_SUPPORT=ON \
      -DPXR_BUILD_EMBREE_PLUGIN=ON \
      -DPXR_BUILD_ALEMBIC_PLUGIN=ON \
      -DPXR_ENABLE_PYTHON_SUPPORT=ON \
      -DPXR_ENABLE_OPENVDB_SUPPORT=ON \
      -DPXR_BUILD_OPENCOLORIO_PLUGIN=ON \
      -DPXR_ENABLE_MATERIALX_SUPPORT=ON  \      
      -DPXR_BUILD_OPENIMAGEIO_PLUGIN=ON   \
      -DPXR_BUILD_EXEC=OFF \      
      -DPXR_BUILD_TESTS=OFF \
      -DPXR_BUILD_ANIMX_TESTS=OFF \
      -DPXR_BUILD_DRACO_PLUGIN=OFF \
      -DPXR_BUILD_PRMAN_PLUGIN=OFF  \
      -DPXR_BUILD_USDVIEW=OFF \
      -DPXR_BUILD_EXAMPLES=OFF \
      -DPXR_BUILD_TUTORIALS=OFF \
      -DPXR_ENABLE_OSL_SUPPORT=OFF \      
      -DPXR_BUILD_DOCUMENTATION=OFF \
      -DPXR_BUILD_USD_VALIDATION=OFF \
      -DPXR_BUILD_HTML_DOCUMENTATION=OFF  \
      -DPXR_BUILD_PYTHON_DOCUMENTATION=OFF \
      -DPXR_ENABLE_HDF5_SUPPORT=OFF \
      -DPXR_ENABLE_METAL_SUPPORT=OFF \
      -DPXR_ENABLE_PRECOMPILED_HEADERS=OFF \
      -DPXR_ENABLE_PTEX_SUPPORT=OFF \
      -DPXR_ENABLE_VULKAN_SUPPORT=OFF \
      -DPXR_HEADLESS_TEST_MODE=OFF \
      -DPXR_PREFER_SAFETY_OVER_SPEED=OFF \
      -DPXR_STRICT_BUILD_MODE=OFF \
      -DCMAKE_VERBOSE_MAKEFILE=ON \
    && cmake --build . \
    && cmake --install . \
    && echo "OpenUSD build complete"
    
     # -DEMBREE_ROOT=/usr/local \
     # -DOPENSUBDIV_ROOT_DIR=/usr/local \    

WORKDIR /blender-git

# Create non-root user
RUN useradd --create-home --shell /bin/bash builder && \
    adduser builder sudo && \
    echo 'builder ALL=(ALL) NOPASSWD:ALL' >> /etc/sudoers
    
# Copy any additional files if needed
COPY --chown=blender-base:blender-base compile.sh /compile.sh
RUN chmod +x /compile.sh

# Set the entrypoint
ENTRYPOINT ["/compile.sh"]




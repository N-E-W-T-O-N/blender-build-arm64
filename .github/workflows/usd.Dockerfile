#FROM ubuntu:24.04
FROM newton2022/blender-builder:24-prebuilder

ARG USD_VERSION=v25.11
WORKDIR /tmp

# 12. OpenSubdiv
RUN echo "Building OpenSubdiv" && \
    git clone --depth=1 https://github.com/PixarAnimationStudios/OpenSubdiv OpenSubdiv && \
    mkdir OpenSubdiv/build && cd OpenSubdiv/build && \
    cmake .. -GNinja -DCMAKE_BUILD_TYPE=Release -DCMAKE_INSTALL_PREFIX=/usr/local \
             -DTBB_ROOT=/usr/local \
             -DNO_TBB=0 -DNO_OPENCL=0 -DNO_OPENGL=0 \
             -DNO_OMP=1 -DNO_CUDA=1 \             
             -DNO_DOC=1 -DNO_EXAMPLES=1 -DNO_REGRESSION=1 -DNO_PTEX=1 \
             -DOSD_PATCH_SHADER_SOURCE_MSL=0 -DOSD_PATCH_SHADER_SOURCE_GLSL=1 -DOSD_PATCH_SHADER_SOURCE_HLSL=1 \
             && \
    cmake --build . && cmake --install . && rm -rf OpenSubdiv


RUN git clone --branch ${USD_VERSION} --depth=1 https://github.com/PixarAnimationStudios/OpenUSD/ OpenUSD && \
    mkdir OpenUSD/build && cd OpenUSD/build && \
    cmake .. -GNinja \
    -DCMAKE_INSTALL_PREFIX=/usr/local \
    -DCMAKE_BUILD_TYPE=Release \
    -DCMAKE_CXX_FLAGS="-Wno-error=stringop-overflow" \
    -DTBB_ROOT=/usr/local \
    -DPXR_BUILD_MONOLITHIC=ON \
    -DPXR_ENABLE_GL_SUPPORT=ON \
    -DMaterialX_ROOT=/usr/local \
    -DPXR_BUILD_EMBREE_PLUGIN=ON \
    -DPXR_BUILD_ALEMBIC_PLUGIN=OFF \
    -DPXR_ENABLE_PYTHON_SUPPORT=ON \
    -DPXR_ENABLE_OPENVDB_SUPPORT=OFF \
    -DPXR_BUILD_OPENCOLORIO_PLUGIN=ON \
    -DPXR_ENABLE_MATERIALX_SUPPORT=OFF \
    -DPXR_BUILD_OPENIMAGEIO_PLUGIN=ON \
    -DPXR_BUILD_EXEC=OFF \
    -DPXR_BUILD_TESTS=OFF \
    -DPXR_BUILD_USDVIEW=OFF \
    -DPXR_BUILD_EXAMPLES=OFF \
    -DPXR_BUILD_USD_TOOLS=OFF \
    -DPXR_BUILD_TUTORIALS=OFF \
    -DPXR_BUILD_DRACO_PLUGIN=OFF \
    -DPXR_BUILD_PRMAN_PLUGIN=OFF \
    -DPXR_ENABLE_PTEX_SUPPORT=OFF \
    -DPXR_ENABLE_METAL_SUPPORT=OFF \
    -DPXR_ENABLE_VULKAN_SUPPORT=OFF \
    -DPXR_ENABLE_OSL_SUPPORT=OFF \
    -DPXR_BUILD_DOCUMENTATION=OFF \
    -DPXR_BUILD_HTML_DOCUMENTATION=OFF \
    -DPXR_BUILD_PYTHON_DOCUMENTATION=OFF \
    -DPXR_ENABLE_PRECOMPILED_HEADERS=OFF \
    -DPXR_STRICT_BUILD_MODE=OFF \
    -DCMAKE_VERBOSE_MAKEFILE=ON && \
    cmake --build . && cmake --install .

    # -DEMBREE_INCLUDE_DIR=/usr/local/include/embree3 \
    # -DEMBREE_LIBRARY=/usr/local/lib/libembree4.so \
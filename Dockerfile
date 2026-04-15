# syntax=docker/dockerfile:1.4
# Blender Builder - ARM64 Optimized with Cache Mounts
# MaterialX with cache mount

ARG BUILD_CACHE=/tmp/build-cache
# Use an official ARM64 Ubuntu LTS image as the base.
# The --platform flag ensures the correct architecture is pulled.
FROM python:3.11-bookworm

# Set frontend to noninteractive to avoid prompts during package installation
ENV DEBIAN_FRONTEND=noninteractive

## -j$(nproc) is removed as it cause issues
# Install essential build tools and dependencies with cache mounts
RUN --mount=type=cache,target=/var/cache/apt,sharing=locked \
    --mount=type=cache,target=/var/lib/apt,sharing=locked \
    apt update && \
    #apt install -y software-properties-common && apt update && \
    apt install -y \
    # Core build tools
    # gcc-14 g++-14 \
    build-essential git git-lfs ninja-build meson pkg-config subversion \
    autoconf automake bison libtool yasm tcl patchelf wget tar \
    python3.11-dev alembic libpython3-dev libhpdf-dev libsystemd-dev dpkg \
    # python3-alembic python3-mako 
    # python3.11  \
    \
    # System libraries
    libc6 libstdc++6 libstdc++-11-dev libstdc++-12-dev libc6-dev linux-libc-dev libfftw3-dev opencollada-dev libimath-dev \
    libusb-1.0-0-dev hydra libboost-all-dev libpugixml-dev clang clang-format libclang-dev llvm-dev \
    # libbtbb-dev\
   #  python3-numpy python3-charset-normalizer python3-urllib3 python3-zstandard python3-requests python3-idna python3-certifi\
   \
   # Compression and crypto
    zlib1g-dev libzstd-dev libssl-dev libssl3 openssl libbrotli-dev libdeflate-dev libclipper2 \
    # Memory & testing
    libjemalloc-dev valgrind libpystring-dev libneon-2-sse-dev \
    \
    # Wayland / X11 / Display
    libwayland-dev wayland-protocols \
    libx11-dev libxt-dev xauth libxcursor-dev libxi-dev libxrandr-dev libxinerama-dev libxkbcommon-dev \
    libxxf86vm-dev libxfixes-dev libxrender-dev xorg libx11-dev \
    libfontconfig1-dev libdbus-1-dev \
    \
    # OpenGL / GLES / Vulkan stack
    libepoxy-dev libvulkan-dev libshaderc-dev libshaderc1 \
    libgl1-mesa-dev libegl1-mesa-dev libegl-dev mesa-utils \
    libgles-dev libgles1 libgles2 libgles2-mesa-dev \
    libglfw3-dev libglew-dev opensubdiv-tools \
    # libembree3-3 libembree-dev  embree-tools 
    libopenxr-dev libopenxr-loader1 libopenxr-utils \
    \
    # Image I/O
    libjpeg-dev libjpeg62-turbo-dev libpng-dev libtiff-dev libopenexr-dev libopencolorio-dev libfreetype6-dev \
    libopenimageio-dev openimageio-tools libopengl0 libopengl-dev libpotrace-dev libopenjp2-7-dev \
    # Audio / Multimedia
    ffmpeg libswresample-dev libavdevice-dev libffado-dev libavformat-dev libavfilter-dev libopenal-dev libswscale-dev libsdl2-dev \
    libsndfile1-dev libjack-jackd2-dev libgstreamer1.0-0 libgstreamer1.0-dev libgstreamer-plugins-base1.0-dev \
    gstreamer1.0-x gstreamer1.0-pulseaudio gstreamer1.0-alsa libspnav-dev libopenvdb-dev libopenvdb-ax-dev \
    libpulse-dev gstreamer1.0-adapter-pulseeffects libavahi-client-dev libcanberra-dev libwebrtc-audio-processing-dev\
     liblilv-dev libebur128-dev libmysofa-dev libcap-dev     \
    #  libpipewire-0.3-dev
    \
    # Clean up
    && rm -rf /var/lib/apt/lists/* && \
    apt -qq clean

# Install Python packages via pip with cache mount
RUN --mount=type=cache,target=/root/.cache/pip \
    pip install --upgrade pip && \
    pip install numpy charset-normalizer urllib3 zstandard requests idna certifi alembic mako jinja2

# ---------------------------------------------------------------------- 
# Install CMake with cache mount
RUN mkdir -p /opt/cmake \
  && wget https://github.com/Kitware/CMake/releases/download/v4.1.1/cmake-4.1.1-linux-aarch64.sh -O /tmp/cmake-install.sh \
  && chmod +x /tmp/cmake-install.sh \
  && /tmp/cmake-install.sh --skip-license --prefix=/opt/cmake \
  && ln -s /opt/cmake/bin/* /usr/local/bin/ \
  && rm /tmp/cmake-install.sh \
  && echo "Done Installing CMake"
#RUN cmake --version

# ---------------------------------------------------------------------- 


RUN --mount=type=cache,target=${BUILD_CACHE},sharing=locked \
    echo "Cloning MaterialX" && \
    git clone https://github.com/AcademySoftwareFoundation/MaterialX.git \
      -b v1.39.4 --depth=1 --recursive ${BUILD_CACHE}/materialx && \
    mkdir -p ${BUILD_CACHE}/materialx/build && \
    cd ${BUILD_CACHE}/materialx/build && \
    cmake -DCMAKE_BUILD_TYPE=Release \
          -DCMAKE_INSTALL_PREFIX=/usr/local \
          -DMATERIALX_BUILD_GRAPH_EDITOR=OFF \
          -DMATERIALX_BUILD_PYTHON=ON \
          -DMATERIALX_BUILD_TESTS=OFF \
          -DMATERIALX_BUILD_VIEWER=OFF \
          -DCMAKE_CXX_FLAGS="-Wno-error=stringop-overflow" \
          .. && \
    cmake --build . && \
    cmake --install . && \
    rm -rf ${BUILD_CACHE}/materialx && \
    echo "Done Installing MaterialX"

#ENV MaterialX_DIR="/blender-git/materialx/"

# ---------------------------------------------------------------------- 
# Install SSE2NEON headers with cache mount
RUN echo "Installing SSE2NEON headers" && \
    git clone --depth=1 https://github.com/DLTcollab/sse2neon.git /tmp/sse2neon && \
    mkdir -p /usr/local/include/sse2neon && \
    cp /tmp/sse2neon/sse2neon.h /usr/local/include/sse2neon/ && \
    rm -rf /tmp/sse2neon && \
    echo "SSE2NEON headers installed"

# ---------------------------------------------------------------------- 
# Clone, build, and install oneTBB v2022.2.0 with cache mount
RUN --mount=type=cache,target=/tmp/build-cache,sharing=locked \
    echo "Building TBB" && \
    if [ ! -d /tmp/build-cache/tbb ]; then \
        git clone https://github.com/uxlfoundation/oneTBB --branch v2022.2.0 /tmp/build-cache/tbb; \
    fi && \
    cd /tmp/build-cache/tbb && \
    mkdir -p build && cd build && \
    cmake -DCMAKE_BUILD_TYPE=Release -DTBB_TEST=OFF -DCMAKE_INSTALL_PREFIX=/usr/local \
    # -DTBB_WERROR=OFF \
    -DCMAKE_INTERPROCEDURAL_OPTIMIZATION=OFF -DCMAKE_CXX_FLAGS="-Wno-error=stringop-overflow" .. && \
    cmake --build . && \
    cmake --install . && \
    rm -rf /tmp/build-cache/tbb && \
    echo "Done Installing TBB"

ENV TBB_ROOT_DIR=/usr/local

# ---------------------------------------------------------------------- 
# Build OpenPGL v0.7.1 ARM64 with cache mount
RUN --mount=type=cache,target=/tmp/build-cache,sharing=locked \
    echo "Building OpenPGL (direct CMake build)" && \
    if [ ! -d /tmp/build-cache/openpgl ]; then \
        git clone --single-branch https://github.com/RenderKit/openpgl --branch v0.7.1 /tmp/build-cache/openpgl; \
    fi && \
    cd /tmp/build-cache/openpgl && \
    mkdir -p build && cd build && \
    cmake .. \
      -DCMAKE_BUILD_TYPE=Release \
      -DCMAKE_INSTALL_PREFIX=/usr/local \
      -DCMAKE_POLICY_DEFAULT_CMP0074=NEW \
      -DOPENPGL_ISA_NEON=ON \
      -DOPENPGL_BUILD_TOOLS=OFF \
      -DOPENPGL_EF_IMAGE_SPACE_GUIDING_BUFFER=OFF \
      -DOPENPGL_TBB_ROOT=/usr/local \
      -GNinja && \
    cmake --build . -- -j1 && \
    cmake --install . && \
    rm -rf /tmp/build-cache/openpgl && \
    echo "OpenPGL direct build complete"

# ----------------------------------------------------------------------
# Build OpenSubdiv with cache mount
RUN --mount=type=cache,target=/tmp/build-cache,sharing=locked \
    echo "Building OpenSubdiv" && \
    if [ ! -d /tmp/build-cache/OpenSubdiv ]; then \
        git clone https://github.com/PixarAnimationStudios/OpenSubdiv.git --depth=1 /tmp/build-cache/OpenSubdiv; \
    fi && \
    cd /tmp/build-cache/OpenSubdiv && \
    mkdir -p build && cd build && \
    cmake .. \
      -G Ninja \
      -DCMAKE_BUILD_TYPE=Release \
      -DCMAKE_INSTALL_PREFIX=/usr/local \
      -DTBB_ROOT=/usr/local \
      -DNO_DOC=1 \
      -DNO_EXAMPLES=1 \
      -DNO_REGRESSION=1 \
      -DNO_TUTORIALS=1 \
      -DNO_PTEX=1 \
      -DNO_OMP=1 \
      -DNO_CUDA=1 \
      -DNO_OPENCL=1 \
      -DNO_CLEW=1 \
      -DNO_OPENGL=1 \
      -DNO_METAL=1 \
      -DOSD_PATCH_SHADER_SOURCE_GLSL=1 \
      -DOSD_PATCH_SHADER_SOURCE_HLSL=1 \
      -DOSD_PATCH_SHADER_SOURCE_MSL=0 && \
    cmake --build . && \
    cmake --install . && \
    rm -rf /tmp/build-cache/OpenSubdiv




# ---------------------------------------------------------------------- 
# Build Manifold v3.2.1 with cache mount
RUN --mount=type=cache,target=/tmp/build-cache,sharing=locked \
    echo "Building Manifold v3.2.1" && \
    if [ ! -d /tmp/build-cache/manifold ]; then \
        git clone https://github.com/elalish/manifold -b v3.2.1 --single-branch /tmp/build-cache/manifold; \
    fi && \
    cd /tmp/build-cache/manifold && \
    mkdir -p build && cd build && \
    cmake .. \
      -G Ninja \
      -DCMAKE_BUILD_TYPE=Release \
      -DCMAKE_INSTALL_PREFIX=/usr/local \
      -DBUILD_SHARED_LIBS=ON \
      -DBUILD_TESTING=OFF \
    #  -DBUILD_GMOCK=OFF \
      -DMANIFOLD_TEST=OFF \
      -DMANIFOLD_DEBUG=OFF \
      -DMANIFOLD_STRICT=ON \
      -DMANIFOLD_PAR=ON \
      -DMANIFOLD_CROSS_SECTION=ON \
      -DMANIFOLD_CBIND=ON \
      -DMANIFOLD_PYBIND=ON \
      -DMANIFOLD_EXPORT=OFF \
      -DMANIFOLD_DOWNLOADS=ON \
      -DMANIFOLD_USE_BUILTIN_TBB=OFF \
      -DMANIFOLD_USE_BUILTIN_CLIPPER2=ON \
      -DMANIFOLD_USE_BUILTIN_NANOBIND=OFF \
      -DClipper2_DIR=/usr/lib/aarch64-linux-gnu/cmake/Clipper2 \
      #  -DFETCHCONTENT_SOURCE_DIR_TBB=/usr/local \
      #   -DTBB_ROOT=/usr/local \
      #  -DTBB_DIR=/usr/local/lib/cmake/TBB \
      -DCMAKE_CXX_FLAGS="-Wno-error=stringop-overflow" \
      -DFETCHCONTENT_DOWNLOADS=OFF \
      -DFETCHCONTENT_QUIET=ON && \
    cmake --build . && \
    cmake --install . && \
    rm -rf /tmp/build-cache/manifold

# ---------------------------------------------------------------------- 
# Build Embree with cache mount
RUN --mount=type=cache,target=/tmp/build-cache,sharing=locked \
    echo "Building Embree" && \
    if [ ! -d /tmp/build-cache/embree ]; then \
        git clone --branch v4.4.0 --single-branch https://github.com/RenderKit/embree.git /tmp/build-cache/embree; \
    fi && \
    cd /tmp/build-cache/embree && \
    mkdir -p build && cd build && \
    cmake .. \
    -DCMAKE_BUILD_TYPE=Release \
    -DCMAKE_CXX_FLAGS="-Wno-error=stringop-overflow" \
    -DEMBREE_TUTORIALS=OFF \
    -DEMBREE_SYCL_SUPPORT=OFF \
    -DEMBREE_ISPC_SUPPORT=OFF \
    -DCMAKE_CXX_COMPILER=g++ \
    -DCMAKE_C_COMPILER=gcc \
    -DEMBREE_TESTING_INSTALL_TESTS=OFF && \
    make && \
    make install && \
    rm -rf /tmp/build-cache/embree


# ---------------------------------------------------------------------- 
# Build Alembic 1.8.8 with cache mount
RUN --mount=type=cache,target=/tmp/build-cache,sharing=locked \
    echo "Building Alembic" && \
    if [ ! -d /tmp/build-cache/alembic ]; then \
        git clone https://github.com/alembic/alembic/ -b 1.8.8 --depth=1 /tmp/build-cache/alembic; \
    fi && \
    cd /tmp/build-cache/alembic && \
    mkdir -p build && cd build && \
    cmake .. \
      -DCMAKE_BUILD_TYPE=Release \
      -DCMAKE_INSTALL_PREFIX=/usr/local \
      -DUSE_TESTS=OFF \
      -DALEMBIC_DEBUG_WARNINGS_AS_ERRORS=OFF \
      -DCMAKE_CXX_FLAGS="-O2 -fno-lto" \
      -DCMAKE_INTERPROCEDURAL_OPTIMIZATION=OFF && \
    cmake --build . && \
    cmake --install . && \
    rm -rf /tmp/build-cache/alembic


# ---------------------------------------------------------------------- 
# Build PipeWire v1.4.8 with cache mount
RUN --mount=type=cache,target=/tmp/build-cache,sharing=locked \
    echo "Building PipeWire v1.4.8" && \
    if [ ! -d /tmp/build-cache/pipewire ]; then \
        git clone https://github.com/PipeWire/pipewire --branch 1.4.8 --depth=1 /tmp/build-cache/pipewire; \
    fi && \
    cd /tmp/build-cache/pipewire && \
    mkdir -p build && cd build && \
    meson setup . .. --buildtype=release --backend=ninja --Dprefix=/usr/local -Dtests=disabled -Ddocs=disabled -Dexamples=disabled \
        -Dinstalled_tests=disabled -Dlibcamera=disabled -Dcompress-offload=disabled -Djack=disabled -Decho-cancel-webrtc=disabled \
        -Daudiotestsrc=disabled -Dsnap=disabled && \
    #-Daudioconvert=disabled -Daudiomixer=disabled -Dspa-plugins=disabled \
    #-Dlibcamera=disabled -Dsystemd=disabled -Dbluez5=disabled \ 
    #  meson configure  .. Check COnfig 
    # Build
    meson compile -C . && \
    meson install -C . && \
    rm -rf /tmp/build-cache/pipewire


# No need to build Imath: libimath-dev is already installed and will be found by CMake
# ---------------------------------------------------------------------- 
# Build OpenUSD v25.05.01 with cache mount
RUN --mount=type=cache,target=/tmp/build-cache,sharing=locked \
    echo "Building OpenUSD v25.05.01" && \
    if [ ! -d /tmp/build-cache/usd ]; then \
        git clone https://github.com/PixarAnimationStudios/OpenUSD/ -b v25.05.01 --depth=1 /tmp/build-cache/usd; \
    fi && \
    cd /tmp/build-cache/usd && \
    mkdir -p build && cd build && \
    cmake .. \
      -G Ninja \
      -DCMAKE_CXX_FLAGS="-Wno-error=stringop-overflow" \
      -DCMAKE_BUILD_TYPE=Release \
      -DCMAKE_INSTALL_PREFIX=/usr/local \
      -DBUILD_SHARED_LIBS=ON \
      -DTBB_ROOT=/usr/local \
     # -DEMBREE_ROOT=/usr/local \
      -DEMBREE_INCLUDE_DIR=/usr/local/include/embree4 \
      -DEMBREE_LIBRARY=/usr/local/lib/libembree4.so \
      -DMaterialX_ROOT=/usr/local \
     # -DOPENSUBDIV_ROOT_DIR=/usr/local \
      \ 
      -DPXR_BUILD_ANIMX_TESTS=OFF \ 
      -DPXR_BUILD_DRACO_PLUGIN=OFF \
      -DPXR_BUILD_EMBREE_PLUGIN=ON \
      -DPXR_BUILD_ALEMBIC_PLUGIN=ON \
      -DPXR_BUILD_OPENCOLORIO_PLUGIN=ON \
      -DPXR_BUILD_OPENIMAGEIO_PLUGIN=ON \
      -DPXR_ENABLE_MATERIALX_SUPPORT=ON \
      -DPXR_ENABLE_OPENVDB_SUPPORT=ON \
      -DPXR_BUILD_USD_TOOLS=ON \
      \
      -DPXR_BUILD_PRMAN_PLUGIN=OFF \
      -DPXR_BUILD_USDVIEW=OFF \
      -DPXR_BUILD_EXAMPLES=OFF \
      -DPXR_BUILD_TUTORIALS=OFF \
      -DPXR_BUILD_TESTS=OFF \
      -DPXR_BUILD_DOCUMENTATION=OFF \
      -DPXR_BUILD_HTML_DOCUMENTATION=OFF \
      -DPXR_BUILD_PYTHON_DOCUMENTATION=OFF \
      -DPXR_BUILD_EXEC=ON \
      -DPXR_BUILD_USD_VALIDATION=ON \
      -DPXR_ENABLE_GL_SUPPORT=ON \
      -DPXR_ENABLE_HDF5_SUPPORT=OFF \
      -DPXR_ENABLE_METAL_SUPPORT=OFF \
      -DPXR_ENABLE_OSL_SUPPORT=OFF \
      -DPXR_ENABLE_PRECOMPILED_HEADERS=OFF \
      -DPXR_ENABLE_PTEX_SUPPORT=OFF \
      -DPXR_ENABLE_PYTHON_SUPPORT=ON \
      -DPXR_ENABLE_VULKAN_SUPPORT=OFF \
      -DPXR_HEADLESS_TEST_MODE=OFF \
      \
      -DPXR_PREFER_SAFETY_OVER_SPEED=OFF \
      \
      -DPXR_STRICT_BUILD_MODE=OFF && \
    cmake --build . && \
    cmake --install . && \
    rm -rf /tmp/build-cache/usd \
    echo "OpenUSD build complete"


# In case depot_tools expects pip-installed deps, ensure it’s covered:
#RUN pip install --no-cache-dir httplib2 httplib2[socks] PySocks six pyasn1 pyasn1-modules urllib3
# Create a non-root user for the build process for security
# and grant passwordless sudo privileges.
RUN useradd --create-home --shell /bin/bash builder && \
    adduser builder sudo && \
    echo 'builder ALL=(ALL) NOPASSWD:ALL' >> /etc/sudoers

# Switch to the non-root user
#USER builder
WORKDIR /blender-git

# Copy the compile script into the container and make it executable
COPY --chown=builder:builder compile.sh /compile.sh
RUN chmod +x /compile.sh

# Set the entrypoint to our compile script
ENTRYPOINT ["/compile.sh"]

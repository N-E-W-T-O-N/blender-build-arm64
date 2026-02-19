# syntax=docker/dockerfile:1.4

################################################################################
# Stage 1: Builder
# - Installs all build dependencies
# - Builds all components under /usr/local
################################################################################
#FROM python:3.11-bookworm AS builder
FROM newton2022/blender-builder:usd AS usd
#FROM newton2022/ubuntu-python:24_3.11 AS builder
FROM ubuntu:24.04 AS builder
# Set frontend to noninteractive and terminal
ENV DEBIAN_FRONTEND=noninteractive
ENV TERM=xterm

# Install build tools & dependencies with cache mounts
RUN --mount=type=cache,target=/var/cache/apt \
    --mount=type=cache,target=/var/lib/apt \
    apt-get update && \
    apt-get install -y software-properties-common ca-certificates && \
    #add-apt-repository ppa:deadsnakes/ppa -y && \
    apt-get update && \
    apt-get install -y \
    cmake ninja-build ccache \
    build-essential git git-lfs meson pkg-config subversion \
    autoconf automake bison libtool yasm tcl patchelf wget tar curl \
    #python3.11 python3.11-dev python3.11-venv python3.11-distutils \
    python3.12 python3.12-dev libpython3-dev pybind11-dev \
    python3.12-full cython3 \
    alembic libhpdf-dev libyaml-cpp-dev libsystemd-dev dpkg \
    \
    # System libraries
    libc6 libstdc++6 libstdc++-11-dev libstdc++-12-dev libc6-dev linux-libc-dev libfftw3-dev opencollada-dev libimath-dev \
    libusb-1.0-0-dev hydra libboost-all-dev libboost-python-dev libboost-numpy-dev libpugixml-dev clang clang-format libclang-dev llvm-dev robin-map-dev\
   \
   # Compression and crypto
    zlib1g-dev libzstd-dev libssl-dev libssl3 openssl libbrotli-dev libdeflate-dev libclipper2 \
    # Memory & testing
    libjemalloc-dev valgrind libpystring-dev \
    \
    # Wayland / X11 / Display
    libwayland-dev  libx11-dev libxt-dev libxcursor-dev libxi-dev libxrandr-dev \
    libxkbcommon-dev libxxf86vm-dev libxfixes-dev libxrender-dev xorg \
    libxinerama-dev libfontconfig1-dev libdbus-1-dev xauth libuhd-dev\
    wayland-protocols \
    \
    # OpenGL / GLES / Vulkan stack
    libepoxy-dev libvulkan-dev libshaderc-dev libshaderc1 \
    libgl1-mesa-dev libegl1-mesa-dev libegl-dev mesa-utils libpipewire-0.3-dev \
    libgles-dev libgles1 libgles2 libgles2-mesa-dev \
    libglfw3-dev libglew-dev  \
    # libembree3-3 libembree-dev  embree-tools  opensubdiv-tools
    libopenxr-dev libopenxr-loader1 libopenxr-utils \
    \
    # Image I/O
    libjpeg-dev libjpeg-turbo8-dev libpng-dev libtiff-dev libopenexr-dev libfreetype6-dev  \
    libopengl0 libopengl-dev libjpeg-tools libpotrace-dev libopenjp2-7-dev libwebp-dev\
    # libopenimageio-dev openimageio-tools \
    # Audio / Multimedia
    ffmpeg libswresample-dev libavdevice-dev libffado-dev libavformat-dev libavfilter-dev libopenal-dev libswscale-dev libsdl2-dev \
    libsndfile1-dev libjack-jackd2-dev libgstreamer1.0-0 libgstreamer1.0-dev libgstreamer-plugins-base1.0-dev \
    gstreamer1.0-x gstreamer1.0-pulseaudio gstreamer1.0-alsa libspnav-dev libopenvdb-dev libopenvdb-ax-dev \
    libpulse-dev gstreamer1.0-adapter-pulseeffects libavahi-client-dev libcanberra-dev libwebrtc-audio-processing-dev \
    liblilv-dev libebur128-dev libmysofa-dev libcap-dev \
    libxcb1-dev \
      libxcb-util-dev \
      libxcb-util0-dev \
      libxcb-image0-dev \
      libxcb-keysyms1-dev \
      libxcb-randr0-dev \
      libxcb-render0-dev \
      libxcb-shape0-dev \
      libxcb-shm0-dev \
      libxcb-sync-dev \
      libxcb-xfixes0-dev \
      software-properties-common \
      libembree-dev \
      libpipewire-0.3-dev \
      libspa-0.2-dev \
      libopenimageio-dev \
      libspa-0.2-modules \
      libpipewire-0.3-dev \
      libxcb-xinerama0-dev \
      libxcb-xinput-dev \
      libxcb-xkb-dev \
      libxcb-icccm4-dev \
      libxcb-ewmh-dev \
      libxcb-present-dev \
      libxcb-dri2-0-dev \
      libxcb-dri3-dev \
      libxcb-glx0-dev \
      libxcb-record0-dev \
      libxcb-res0-dev \
      libxkbcommon-x11-dev \
      libxcb-render-util0-dev \
      libxcb-screensaver0-dev \
      libxcb-xtest0-dev \
      libxcb-xv0-dev \
      libxcb-xvmc0-dev \
      libxkbcommon-dev \
      libxkbfile-dev
    # \
    # # Clean up
    # && rm -rf /var/lib/apt/lists/* && apt -qq clean

# Install Python packages with pip cache
RUN python3.12 -m venv /opt/venv && \
    /opt/venv/bin/pip install --upgrade pip setuptools wheel \
      numpy charset-normalizer zstandard cython \
      requests idna certifi alembic mako jinja2 packaging

ENV PATH="/opt/venv/bin:$PATH"
# Prepare build workspace
WORKDIR /tmp

# 1. SSE2NEON headers
RUN echo "Installing SSE2NEON headers" && \
    git clone --depth=1 https://github.com/DLTcollab/sse2neon.git /tmp/sse2neon && \
    mkdir -p /usr/local/include/sse2neon && \
    cp /tmp/sse2neon/sse2neon.h /usr/local/include/sse2neon/ 

# 2. CMake
# RUN mkdir -p /opt/cmake && \
#     wget -q https://github.com/Kitware/CMake/releases/download/v4.1.2/cmake-4.1.2-linux-aarch64.sh \
#     -O /tmp/cmake-install.sh && \
#     chmod +x /tmp/cmake-install.sh && \
#     /tmp/cmake-install.sh --skip-license --prefix=/opt/cmake && \
#     ln -s /opt/cmake/bin/* /usr/local/bin/ && rm /tmp/cmake-install.sh

# 3. Wayland Protocols
# RUN echo "Building Wayland-Protocols" && \
#     git clone https://gitlab.freedesktop.org/wayland/wayland-protocols -b 1.44 /tmp/wayland && \
#     cd /tmp/wayland && mkdir build && cd build && \
#     meson setup . .. --buildtype=release -Dprefix=/usr/local -Dtests=false && \
#     meson compile -C . && meson install -C . && rm -rf /tmp/wayland

# 4. ISPC
#4. ISPC
RUN echo "Add ISPC" && mkdir -p /opt/ispc && \
    wget -q https://github.com/ispc/ispc/releases/download/v1.29.1/ispc-v1.29.1-linux.aarch64.tar.gz \
        -O ispc.tar.gz && \
    tar -xzf ispc.tar.gz -C /opt/ispc --strip-components=1 && \
    rm ispc.tar.gz
# 5. TBB
RUN echo "Building TBB" && \
    git clone --branch v2022.3.0 https://github.com/uxlfoundation/oneTBB /tmp/tbb && \
    cd /tmp/tbb && mkdir build && cd build && \
    cmake -DCMAKE_BUILD_TYPE=Release -DCMAKE_INSTALL_PREFIX=/usr/local \
          -DCMAKE_INTERPROCEDURAL_OPTIMIZATION=OFF -DTBB_TEST=OFF -DTBB_STRICT=OFF \
          -DCMAKE_CXX_FLAGS="-Wno-error=stringop-overflow" .. && \
    cmake --build . && cmake --install .  

# 6 Vulkan-Header
# RUN echo "Add Vulkan Header" && \
#     git clone --depth=1 -b v1.3.296 https://github.com/KhronosGroup/Vulkan-Headers.git /tmp/vulkan && \
#     cd /tmp/vulkan && \
#     cmake -S . -B build -DVULKAN_HEADERS_ENABLE_TESTS=OFF && \
#     cmake --install build && rm -rf /tmp/vulkan

# 7 OCIO
RUN echo "Build OpenColorIO" && \
    git clone --branch v2.5.1 --depth=1 https://github.com/AcademySoftwareFoundation/OpenColorIO /tmp/ocio && \
    mkdir -p /tmp/ocio/build && cd /tmp/ocio/build && \
    cmake .. -GNinja -DCMAKE_BUILD_TYPE=Release \
      -DCMAKE_INSTALL_PREFIX=/usr/local \
      -DBUILD_SHARED_LIBS=ON \
      -DBUILD_DOCS=OFF \
      -DOCIO_INSTALL_EXT_PACKAGES=MISSING \
      -DOCIO_BUILD_APPS=OFF \
      -DOCIO_USE_OIIO_FOR_APPS=OFF \
      -DOCIO_BUILD_PYTHON=ON \
      -DOCIO_BUILD_OPENFX=OFF \
      -DOCIO_USE_SIMD=ON \
      -DOCIO_USE_SSE2=ON \
      -DOCIO_BUILD_TESTS=OFF \
      -DOCIO_BUILD_GPU_TESTS=OFF \
      -DOCIO_USE_HEADLESS=OFF \
      -DOCIO_WARNING_AS_ERROR=OFF \
      -DOCIO_BUILD_DOCS=OFF && \
    cmake --build . && cmake --install . && echo "Done Installing OpenColorIO." 

# 8 OIIO
RUN echo "Build OpenImageIO" && \
    git clone --branch v3.1.10.0 --depth=1 https://github.com/AcademySoftwareFoundation/OpenImageIO /tmp/oiio && \
    cd /tmp/oiio && mkdir -p build && cd build && \
    cmake .. -GNinja -DCMAKE_BUILD_TYPE=Release \
      -DCMAKE_INSTALL_PREFIX=/usr/local \
      -DBUILD_SHARED_LIBS=ON \
      -DUSE_OPENCOLORIO=ON \
      -DUSE_WEBP=ON \
      -DUSE_TBB=ON \
      -DUSE_PYTHON=ON \
      -DUSE_OPENJPEG=ON \
      -DOpenColorIO_DIR=/usr/local \
      -DOpenImageIO_BUILD_MISSING_DEPS=all \
      -DBUILD_DOCS=OFF \
      -DUSE_OPENVDB=OFF \
      -DUSE_FREETYPE=OFF \
      -DUSE_DCMTK=OFF \
      -DUSE_LIBHEIF=OFF \
      -DOIIO_BUILD_TESTS=OFF \
      -DBUILD_TESTING=OFF \
      -DSTOP_ON_WARNING=OFF \
      -DUSE_QT=OFF \
      -DUSE_GIF=OFF \
      -DUSE_OPENCV=OFF \
      -DUSE_FFMPEG=OFF \
      -DUSE_PTEX=OFF \
      -DUSE_LIBRAW=OFF \
      -DUSE_JXL=OFF && \
    cmake --build . && cmake --install . && echo "Done Installing OpenImageIO."  

# 9 OIDN
RUN echo "Build Image Denoiser Oidn" && \
    wget --show-progress -q https://github.com/RenderKit/oidn/releases/download/v2.4.1/oidn-2.4.1.src.tar.gz -O oidn.tar.gz && \
    mkdir -p /tmp/oidn && \
    tar -xvf oidn.tar.gz -C /tmp/oidn --strip-components=1 && rm oidn.tar.gz && \
    cd /tmp/oidn && mkdir build && cd build && \
    cmake .. -GNinja \
      -DCMAKE_BUILD_TYPE=Release \
      -DOIDN_APPS=OFF \
      -DOIDN_DEVICE_HIP=OFF \
      -DOIDN_DEVICE_CUDA=OFF \
      -DOIDN_DEVICE_SYCL=OFF \
      -DOIDN_DEVICE_METAL=OFF \
      -DOIDN_INSTALL_DEPENDENCIES=ON \
      -DCMAKE_INSTALL_PREFIX=/usr/local \
      -DISPC_EXECUTABLE=/opt/ispc/bin/ispc && \
    cmake --build . && cmake --install . && echo "Done installing Oidn"  
    
################################################################################
# Stage 2: Mid-Builder
# - Adds MaterialX, OpenPGL, OpenSubdiv, Manifold, Embree, Alembic, PipeWire
#
################################################################################
FROM builder AS midbuilder

WORKDIR /tmp

# 10 MaterialX
RUN echo "Cloning MaterialX" && \
    git clone -b v1.39.4 --depth=1 https://github.com/AcademySoftwareFoundation/MaterialX.git /tmp/materialx && \
    mkdir -p /tmp/materialx/build && cd /tmp/materialx/build && \
    cmake .. -GNinja -DCMAKE_BUILD_TYPE=Release \
      -DCMAKE_INSTALL_PREFIX=/usr/local \
      -DMATERIALX_BUILD_PYTHON=ON \      
      -DMATERIALX_BUILD_TESTS=OFF \
      -DMATERIALX_BUILD_VIEWER=OFF \
      -DMATERIALX_BUILD_GRAPH_EDITOR=OFF \      
      -DCMAKE_CXX_FLAGS="-Wno-error=stringop-overflow" && \
    cmake --build . && cmake --install . && echo "Done Installing MaterialX" 

# 11 OpenPGL
RUN echo "Building OpenPGL" && \
    git clone --branch v0.7.1 --single-branch https://github.com/RenderKit/openpgl /tmp/openpgl && \
    cd /tmp/openpgl && mkdir build && cd build && \
    cmake .. -GNinja -DCMAKE_BUILD_TYPE=Release \
      -DCMAKE_INSTALL_PREFIX=/usr/local \
      -DOPENPGL_ISA_NEON=ON \
      -DOPENPGL_BUILD_TOOLS=OFF \
      -DOPENPGL_EF_IMAGE_SPACE_GUIDING_BUFFER=OFF \
      -DOPENPGL_TBB_ROOT=/usr/local  && \
    cmake --build . && cmake --install . && echo "OpenPGL build complete" 

# 12 OpenSubdiv
RUN echo "Building OpenSubdiv" && \
    git clone --depth=1 https://github.com/PixarAnimationStudios/OpenSubdiv.git /tmp/OpenSubdiv && \
    cd /tmp/OpenSubdiv && mkdir build && cd build && \
    cmake .. -GNinja \
      -DCMAKE_BUILD_TYPE=Release \
      -DCMAKE_INSTALL_PREFIX=/usr/local \
      -DTBB_ROOT=/usr/local \
      -DNO_TBB=0 -DNO_OPENCL=0 -DNO_OPENGL=0 -DOSD_PATCH_SHADER_SOURCE_MSL=0 \
      -DNO_DOC=1 -DNO_EXAMPLES=1 -DNO_REGRESSION=1 -DNO_PTEX=1 -DNO_OMP=1 -DNO_CUDA=1 \
      -DOSD_PATCH_SHADER_SOURCE_GLSL=1 -DOSD_PATCH_SHADER_SOURCE_HLSL=1 \
    && \
    cmake --build . && cmake --install . && echo "Done Installing OpenSubdiv"  

# 13 Manifold
RUN echo "Building Manifold v3.3.2" && \
    git clone -b v3.3.2 --single-branch https://github.com/elalish/manifold /tmp/manifold && \
    cd /tmp/manifold && mkdir build && cd build && \
    cmake .. -GNinja \
      -DCMAKE_BUILD_TYPE=Release \
      -DCMAKE_INSTALL_PREFIX=/usr/local \
      -DBUILD_SHARED_LIBS=ON \
      -DBUILD_TESTING=OFF \
      -DMANIFOLD_TEST=OFF \
      -DMANIFOLD_DEBUG=OFF \
      -DMANIFOLD_STRICT=ON \
      -DMANIFOLD_PAR=ON \
      -DMANIFOLD_CROSS_SECTION=ON \
      -DMANIFOLD_CBIND=ON \
      -DMANIFOLD_PYBIND=ON \
      -DMANIFOLD_DOWNLOADS=ON \
      -DFETCHCONTENT_DOWNLOADS=OFF \
      -DFETCHCONTENT_QUIET=ON \
      -DMANIFOLD_USE_BUILTIN_TBB=OFF \
      -DMANIFOLD_USE_BUILTIN_CLIPPER2=ON \
      -DMANIFOLD_USE_BUILTIN_NANOBIND=OFF \
      -DClipper2_DIR=/usr/lib/aarch64-linux-gnu/cmake/Clipper2 \
      -DCMAKE_CXX_FLAGS="-Wno-error=stringop-overflow" \
       && \
    cmake --build . && cmake --install . && echo "Done Installing Manifold" 

# 14.A Embree4
# RUN echo "Building Embree4" && \
#     git clone --branch v4.4.0 --single-branch https://github.com/RenderKit/embree.git /tmp/embree && \
#     mkdir -p /tmp/embree/build && cd /tmp/embree/build && \
#     cmake .. -DCMAKE_BUILD_TYPE=Release \
#     -DCMAKE_CXX_FLAGS="-Wno-error=stringop-overflow" \
#     -DEMBREE_TUTORIALS=OFF \
#     -DEMBREE_SYCL_SUPPORT=OFF \
#     -DEMBREE_ISPC_SUPPORT=ON \
#     -DCMAKE_CXX_COMPILER=g++ \
#     -DCMAKE_C_COMPILER=gcc \
#     -DEMBREE_ISPC_EXECUTABLE=/opt/ispc/bin/ispc \
#     -DEMBREE_TESTING_INSTALL_TESTS=OFF && \
#     make && make install && echo "Done Installing Embree4" && rm -rf /tmp/embree


# 15 Alembic
RUN echo "Building Alembic" && \
    git clone -b 1.8.10 --depth=1 https://github.com/alembic/alembic.git /tmp/alembic && \
    cd /tmp/alembic && mkdir build && cd build && \
    cmake .. -GNinja -DCMAKE_BUILD_TYPE=Release \
      -DCMAKE_INSTALL_PREFIX=/usr/local \
      -DUSE_TESTS=OFF \
      -DALEMBIC_DEBUG_WARNINGS_AS_ERRORS=OFF \
      -DCMAKE_CXX_FLAGS="-O2 -fno-lto" \
      -DCMAKE_INTERPROCEDURAL_OPTIMIZATION=OFF && \
    cmake --build . && cmake --install . && echo "Done Installing Alembic" 

# 16 PipeWire
#RUN echo "Building PipeWire v1.4.8" && \
    # git clone --branch 1.4.8 --depth=1 https://github.com/PipeWire/pipewire /tmp/pipewire && \
    # cd /tmp/pipewire && mkdir build && cd build && \
    # meson setup . .. --buildtype=release -Dprefix=/usr/local --backend=ninja \
    #  -Dtests=disabled -Ddocs=disabled -Dexamples=disabled \
    #  -Dinstalled_tests=disabled -Dlibcamera=disabled -Dcompress-offload=disabled \
    #  -Djack=disabled -Decho-cancel-webrtc=disabled \
    #     -Daudiotestsrc=disabled -Dsnap=disabled  && \
    # meson compile -C . && meson install -C . && echo "Done Installing PipeWire" && rm -rf /tmp/pipewire

# OpenUSD have dependency of embree3 WorkArround
#RUN ln -s /usr/local/include/embree4 /usr/local/include/embree3

FROM midbuilder AS finalbuilder

COPY --from=usd /OpenUSD /OpenUSD/
WORKDIR /OpenUSD/build/
RUN cmake --install . && rm -rf /OpenUSD

# Copy entrypoint script
COPY --chown=builder:builder compile.sh /compile.sh
RUN chmod +x /compile.sh
ENTRYPOINT ["/compile.sh"]


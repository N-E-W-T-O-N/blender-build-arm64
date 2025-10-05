# syntax=docker/dockerfile:1.4

# Blender Builder - ARM64 Optimized with Cache Mounts
# Use an official ARM64 Ubuntu LTS image as the base.
# The --platform flag ensures the correct architecture is pulled.
# MaterialX with cache mount

FROM python:3.11-bookworm

# Set frontend to noninteractive to avoid prompts during package installation
ENV DEBIAN_FRONTEND=noninteractive
# Set PYTHONPATH to custom site-packages directory
#ENV PYTHONPATH="/usr/local/lib/python3.11/dist-packages:${PYTHONPATH}"

## -j$(nproc) is removed as it cause issues
# Install essential build tools and dependencies with cache mounts
RUN --mount=type=cache,target=/var/cache/apt \
    --mount=type=cache,target=/var/lib/apt \
    apt update && \
    #apt install -y software-properties-common && apt update && \
    apt install -y \
    # Core build tools
    # gcc-14 g++-14 \
    build-essential git git-lfs ninja-build meson pkg-config subversion \
    autoconf automake bison libtool yasm tcl patchelf wget tar \
    python3.11-dev pybind11-dev alembic libpython3-dev libhpdf-dev libyaml-cpp-dev libsystemd-dev dpkg \
    # python3-alembic python3-mako 
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
    libwayland-dev  libx11-dev libxt-dev libxcursor-dev libxi-dev libxrandr-dev \
    libxkbcommon-dev libxxf86vm-dev libxfixes-dev libxrender-dev xorg \
    libxinerama-dev libfontconfig1-dev libdbus-1-dev xauth libuhd-dev\
    # wayland-protocols \
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
    libjpeg-dev libjpeg62-turbo-dev libpng-dev libtiff-dev libopenexr-dev libopencolorio-dev libfreetype6-dev  \
    opencolorio-tools libopengl0 libopengl-dev libpotrace-dev libopenjp2-7-dev \
    # libopenimageio-dev openimageio-tools \
    # Audio / Multimedia
    ffmpeg libswresample-dev libavdevice-dev libffado-dev libavformat-dev libavfilter-dev libopenal-dev libswscale-dev libsdl2-dev \
    libsndfile1-dev libjack-jackd2-dev libgstreamer1.0-0 libgstreamer1.0-dev libgstreamer-plugins-base1.0-dev \
    gstreamer1.0-x gstreamer1.0-pulseaudio gstreamer1.0-alsa libspnav-dev libopenvdb-dev libopenvdb-ax-dev \
    libpulse-dev gstreamer1.0-adapter-pulseeffects libavahi-client-dev libcanberra-dev libwebrtc-audio-processing-dev \
    liblilv-dev libebur128-dev libmysofa-dev libcap-dev \
    #  libpipewire-0.3-dev
    \
    # Clean up
    && rm -rf /var/lib/apt/lists/*  \
    && apt -qq clean

# Install Python packages via pip with cache mount
RUN --mount=type=cache,target=/root/.cache/pip \
    pip install --upgrade pip && \
    pip install numpy charset-normalizer urllib3 zstandard requests idna certifi alembic mako jinja2

RUN wget -q https://github.com/libjpeg-turbo/libjpeg-turbo/releases/download/3.1.2/libjpeg-turbo-official_3.1.2_arm64.deb &&\
 dpkg -i libjpeg-turbo-official_3.1.2_arm64.deb && rm libjpeg-turbo-official_3.1.2_arm64.deb
 
RUN mkdir -p /tmp/build_linux
WORKDIR /tmp/build_linux

# ---------------------------------------------------------------------- 
# 1 Sse2Neon
# Install SSE2NEON headers with cache mount
RUN echo "Installing SSE2NEON headers" && \
    git clone --depth=1 https://github.com/DLTcollab/sse2neon.git /tmp/sse2neon && \
    mkdir -p /usr/local/include/sse2neon && \
    cp /tmp/sse2neon/sse2neon.h /usr/local/include/sse2neon/ && \
    rm -rf /tmp/sse2neon && \
    echo "SSE2NEON headers installed"


# ---------------------------------------------------------------------- 
# 2 Cmake
# Install CMake with cache mount
RUN mkdir -p /opt/cmake \
  && wget -q https://github.com/Kitware/CMake/releases/download/v4.1.2/cmake-4.1.2-linux-aarch64.sh -O /tmp/cmake-install.sh \
  && chmod +x /tmp/cmake-install.sh \
  && /tmp/cmake-install.sh --skip-license --prefix=/opt/cmake \
  && ln -s /opt/cmake/bin/* /usr/local/bin/ \
  && rm /tmp/cmake-install.sh \
  && echo "Done Installing CMake"
#RUN cmake --version

# ---------------------------------------------------------------------- 
# 3 Wayland-Protocol
RUN echo "Building Wayland-Protocols" && \
    git clone https://gitlab.freedesktop.org/wayland/wayland-protocols -b 1.44 /tmp/wayland && \
    cd /tmp/wayland && mkdir -p build && cd build && \
    meson setup . .. --buildtype=release -Dprefix=/usr/local -Dtests=false && \
    meson compile -C . && \
    meson install -C . && \
    rm -rf /tmp/wayland && \
    echo "Done Installing wayland-protocols"

# ---------------------------------------------------------------------- 
# 4 ISPC
RUN echo "Add Ispc" && mkdir -p /opt/ispc && \
    wget -q https://github.com/ispc/ispc/releases/download/v1.28.2/ispc-v1.28.2-linux.aarch64.tar.gz -O /tmp/ispc.tar.gz && \
    tar -xvf /tmp/ispc.tar.gz -C /opt/ispc --strip-components=1 && \
    rm /tmp/ispc.tar.gz
   
# ---------------------------------------------------------------------- 
# 5 OIIO        
RUN --mount=type=cache,target=/tmp/build_linux \
    echo "Build OpenImageIO" && \
    if [ ! -d oiio ]; then \
      git clone --branch  v3.0.6.1 --depth=1 https://github.com/AcademySoftwareFoundation/OpenImageIO  oiio; \
    fi && \
    cd oiio && mkdir -p build && cd build && \
    # Configure
    cmake  .. \
      -DCMAKE_BUILD_TYPE=Release \
      -DCMAKE_INSTALL_PREFIX=/usr/local \
      -DBUILD_SHARED_LIBS=ON\ 
      -DBUILD_DOCS=OFF\
      #-DOCIO_BUILD_NUKE=OFF\
      #-DOCIO_BUILD_JAVA=OFF\
      #-DOCIO_BUILD_GPU_TESTS=OFF\
      -DUSE_OPENVDB=OFF\
      -DUSE_FREETYPE=OFF\
      -DUSE_DCMTK=OFF\
      -DUSE_LIBHEIF=OFF\
      -DOIIO_BUILD_TESTS=OFF\
      -DBUILD_TESTING=OFF\
      -DSTOP_ON_WARNING=OFF \
      -DUSE_QT=OFF\
      -DUSE_GIF=OFF\
      -DUSE_OPENCV=OFF\
      -DUSE_FFMPEG=OFF\
      -DUSE_PTEX=OFF\
      -DUSE_LIBRAW=OFF\
      -DUSE_JXL=OFF\
      -DUSE_OPENCOLORIO=ON\
      -DUSE_WEBP=ON\
      -DUSE_TBB=ON\
      -DUSE_PYTHON=ON\      
      -DUSE_OPENJPEG=ON\
      -DOpenColorIO_DIR=/usr/share/cmake \
      -Dlibjpeg-turbo_DIR=/opt/libjpeg-turbo/lib64/cmake/libjpeg-turbo\
      -DYAML_CPP_DIR=/usr/lib/aarch64-linux-gnu/cmake/yaml-cpp\
      -DOpenImageIO_BUILD_MISSING_DEPS=all\
# Build & install
      && \
     cmake --build . && \
     cmake --install . && \

# ----------------------------------------------------------------------     
# 6 Denoise 
# Build OIDN
RUN --mount=type=cache,target=/tmp/build_linux \
    echo "Build Image Denoiser Odin by Intel" && \
    if [ ! -d oidn ]; then \
      git clone --branch v2.3.3 --depth=1 https://github.com/RenderKit/oidn.git oidn; \
    fi && \
    cd oidn && \
    GIT_DISCOVERY_ACROSS_FILESYSTEM=1 git submodule update --init --recursive --remote external/mkl-dnn weights && \
    mkdir -p build && cd build && \
    cmake .. -GNinja -v \
      -DCMAKE_C_COMPILER=clang \
      -DCMAKE_CXX_COMPILER=clang++ \
      -DCMAKE_BUILD_TYPE=Release \
      -DCMAKE_INSTALL_PREFIX=/usr/local \
      -DISPC_EXECUTABLE=/opt/ispc/bin/ispc \
      -DOIDN_APPS=OFF \
      -DOIDN_DEVICE_HIP=OFF \
      -DOIDN_DEVICE_CUDA=OFF \
      -DOIDN_DEVICE_SYCL=OFF  \
      -DOIDN_DEVICE_METAL=OFF  \
      -DOIDN_DEVICE_CPU=ON \
      -DOIDN_INSTALL_DEPENDENCIES=OFF \
      && \
    cmake --build . && \
    cmake --install . && \


    
# ---------------------------------------------------------------------- 
# 7 MaterialX
RUN --mount=type=cache,target=/tmp/build_linux \
    echo "Cloning MaterialX" && \
    if [ ! -d materialx ]; then \
        git clone https://github.com/AcademySoftwareFoundation/MaterialX.git -b v1.39.4 --depth=1 materialx; \
    fi && \
    mkdir -p materialx/build && cd materialx/build && \
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
    echo "Done Installing MaterialX"

#ENV MaterialX_DIR="/blender-git/materialx/"

# ---------------------------------------------------------------------- 
# 8 TBB
# Clone, build, and install oneTBB v2022.2.0 with cache mount
RUN --mount=type=cache,target=/tmp/build_linux \
    echo "Building TBB" && \
    if [ ! -d tbb ]; then \
        git clone https://github.com/uxlfoundation/oneTBB --branch v2022.2.0 tbb; \
    fi && \
    mkdir -p tbb/build && cd tbb/build && \
    cmake -DCMAKE_BUILD_TYPE=Release -DCMAKE_INSTALL_PREFIX=/usr/local \  
        # -DTBB_STRICT=OFF \
         -DCMAKE_INTERPROCEDURAL_OPTIMIZATION=OFF -DCMAKE_CXX_FLAGS="-Wno-error=stringop-overflow" .. && \
    cmake --build .  && \
    cmake --install . && \
    echo "Done Installing TBB"
ENV TBB_ROOT_DIR=/usr/local

# ----------------------------------------------------------------------
# 9 OpenPGL

RUN --mount=type=cache,target=/tmp/build_linux \
    echo "Building OpenPGL (direct CMake build)" && \
    if [ ! -d openpgl ]; then \
        git clone --single-branch https://github.com/RenderKit/openpgl --branch v0.7.1 openpgl; \
    fi && \
    mkdir -p openpgl/build && cd openpgl/build && \
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
    echo "OpenPGL direct build complete"
# ----------------------------------------------------------------------
# 10 OpenSubDiv
# Build OpenSubdiv with cache mount
RUN --mount=type=cache,target=/tmp/build_linux \
    echo "Building OpenSubdiv" && \
    if [ ! -d OpenSubdiv ]; then \
        git clone https://github.com/PixarAnimationStudios/OpenSubdiv.git --depth=1 OpenSubdiv; \
    fi && \
    mkdir -p OpenSubdiv/build && cd OpenSubdiv/build && \
    cmake .. \
      -G Ninja \
      -DCMAKE_BUILD_TYPE=Release \
      -DCMAKE_INSTALL_PREFIX=/usr/local \
      -DTBB_ROOT=/usr/local \
      -DNO_TBB=0 \
      -DNO_OPENCL=0 \
      -DNO_OPENGL=0 \
      -DNO_DOC=1 \
      -DNO_EXAMPLES=1 \
      -DNO_REGRESSION=1 \
      -DNO_TUTORIALS=1 \
      -DNO_PTEX=1 \
      -DNO_OMP=1 \
      -DNO_CUDA=1 \
      -DNO_CLEW=1 \
      -DNO_METAL=1 \
      -DOSD_PATCH_SHADER_SOURCE_GLSL=1 \
      -DOSD_PATCH_SHADER_SOURCE_HLSL=1 \
      -DOSD_PATCH_SHADER_SOURCE_MSL=0 && \
    cmake --build . && \
    cmake --install . 

# ---------------------------------------------------------------------- 
# 11 Manifold
# Build Manifold v3.2.1 with cache mount
RUN --mount=type=cache,target=/tmp/build_linux\ 
    echo "Building Manifold v3.2.1" && \
    if [ ! -d manifold ]; then \
        git clone https://github.com/elalish/manifold -b v3.2.1 --single-branch manifold; \
    fi && \
    mkdir -p manifold/build && cd manifold/build && \
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
    cmake --install .

# ---------------------------------------------------------------------- 
# 12 EMbree
# Build Embree with cache mount
RUN --mount=type=cache,target=/tmp/build_linux \ 
    echo "Building Embree" && \
    if [ ! -d embree ]; then \
        git clone --branch v4.4.0 --single-branch https://github.com/RenderKit/embree.git embree ; \
    fi && \
    mkdir -p embree/build && cd embree/build && \
    cmake .. \
    -DCMAKE_BUILD_TYPE=Release \
    -DCMAKE_CXX_FLAGS="-Wno-error=stringop-overflow" \
    -DEMBREE_TUTORIALS=OFF \
    -DEMBREE_SYCL_SUPPORT=OFF \
    -DEMBREE_ISPC_SUPPORT=ON \
    -DCMAKE_CXX_COMPILER=g++ \
    -DCMAKE_C_COMPILER=gcc \
    -DEMBREE_TESTING_INSTALL_TESTS=OFF && \
    make && \
    make install


# ---------------------------------------------------------------------- 
# 13 Alembic
# Build Alembic 1.8.8 with cache mount
RUN --mount=type=cache,target=/tmp/build_linux \ 
    echo "Building Alembic" && \
    if [ ! -d alembic ]; then \
            git clone https://github.com/alembic/alembic/ -b 1.8.8 --depth=1 alembic; \
    fi && \
    mkdir -p alembic/build && cd alembic/build && \
    cmake .. \
      -DCMAKE_BUILD_TYPE=Release \
      -DCMAKE_INSTALL_PREFIX=/usr/local \
      -DUSE_TESTS=OFF \
      -DALEMBIC_DEBUG_WARNINGS_AS_ERRORS=OFF \
      -DCMAKE_CXX_FLAGS="-O2 -fno-lto" \
      -DCMAKE_INTERPROCEDURAL_OPTIMIZATION=OFF && \
    cmake --build . && \
    cmake --install . 


# ---------------------------------------------------------------------- 
# 14 PipeWire
# Build PipeWire v1.4.8 with cache mount
RUN --mount=type=cache,target=/tmp/build_linux \ 
    echo "Building PipeWire v1.4.8" && \
    if [ ! -d pipewire ]; then \
                git clone https://github.com/PipeWire/pipewire --branch 1.4.8 --depth=1 pipewire; \
    fi && \
    mkdir -p pipewire/build && cd pipewire/build && \
    meson setup . .. --buildtype=release --backend=ninja --Dprefix=/usr/local -Dtests=disabled -Ddocs=disabled -Dexamples=disabled \
        -Dinstalled_tests=disabled -Dlibcamera=disabled -Dcompress-offload=disabled -Djack=disabled -Decho-cancel-webrtc=disabled \
        -Daudiotestsrc=disabled -Dsnap=disabled && \
    #-Daudioconvert=disabled -Daudiomixer=disabled -Dspa-plugins=disabled \
    #-Dlibcamera=disabled -Dsystemd=disabled -Dbluez5=disabled \ 
    #  meson configure  .. Check COnfig 
    # Build
    meson compile -C . && \
    meson install -C .

# ---------------------------------------------------------------------- 
#15 Vulkan-Header
RUN echo "Add Vulkan Header" &&\
    git clone https://github.com/KhronosGroup/Vulkan-Headers.git --detpth=1 -d v1.3.296 /tmp/vulkan && \ 
# Configure the project
    cmake -S . -B build -DVULKAN_HEADERS_ENABLE_TESTS=OFF && \
# Because Vulkan-Headers is header only we don't need to build anything.
# Users can install it where they need to.
    cmake --install build && \
    rm -rf /tmp/vulkan


# No need to build Imath: libimath-dev is already installed and will be found by CMake
# ---------------------------------------------------------------------- 
# 16 OpenUSd
# Build OpenUSD v25.05.01 with cache mount
RUN --mount=type=cache,target=/tmp/build_linux \ 
    echo "Building OpenUSD v25.05.01" && \
    if [ ! -d OpenUSD ]; then \
        git clone https://github.com/PixarAnimationStudios/OpenUSD/ -b v25.05.01 --depth=1 OpenUSD; \
    fi && \
    cd OpenUSD && mkdir -p build && cd build && \
    cmake .. \
      -G Ninja \
      -DCMAKE_CXX_FLAGS="-Wno-error=stringop-overflow" \
      -DCMAKE_BUILD_TYPE=Release \
      -DCMAKE_INSTALL_PREFIX=/usr/local \
      -DBUILD_SHARED_LIBS=ON \
      -DTBB_ROOT=/usr/local \
      -DEMBREE_INCLUDE_DIR=/usr/local/include/embree4 \
      -DEMBREE_LIBRARY=/usr/local/lib/libembree4.so \
      -DMaterialX_ROOT=/usr/local \
      \
      -DPXR_BUILD_EXEC=ON \
      -DPXR_BUILD_USD_VALIDATION=ON \
      -DPXR_ENABLE_MATERIALX_SUPPORT=ON \
      -DPXR_ENABLE_OPENVDB_SUPPORT=ON \
      -DPXR_ENABLE_GL_SUPPORT=ON \
      -DPXR_BUILD_EMBREE_PLUGIN=ON \
      -DPXR_BUILD_ALEMBIC_PLUGIN=ON \
      -DPXR_BUILD_OPENCOLORIO_PLUGIN=ON \
      -DPXR_BUILD_OPENIMAGEIO_PLUGIN=ON \
      -DPXR_BUILD_USD_TOOLS=ON \
      \
      -DPXR_BUILD_ANIMX_TESTS=OFF \
      -DPXR_BUILD_DRACO_PLUGIN=OFF \
      -DPXR_BUILD_PRMAN_PLUGIN=OFF \
      -DPXR_BUILD_USDVIEW=OFF \
      -DPXR_BUILD_EXAMPLES=OFF \
      -DPXR_BUILD_TUTORIALS=OFF \
      -DPXR_BUILD_TESTS=OFF \
      -DPXR_BUILD_DOCUMENTATION=OFF \
      -DPXR_BUILD_HTML_DOCUMENTATION=OFF \
      -DPXR_BUILD_PYTHON_DOCUMENTATION=OFF \
      -DPXR_ENABLE_HDF5_SUPPORT=OFF \
      -DPXR_ENABLE_METAL_SUPPORT=OFF \
      -DPXR_ENABLE_OSL_SUPPORT=OFF \
      -DPXR_ENABLE_PRECOMPILED_HEADERS=OFF \
      -DPXR_ENABLE_PTEX_SUPPORT=OFF \
      -DPXR_ENABLE_PYTHON_SUPPORT=ON \
      -DPXR_ENABLE_VULKAN_SUPPORT=OFF \
      -DPXR_HEADLESS_TEST_MODE=OFF \
      -DPXR_PREFER_SAFETY_OVER_SPEED=OFF \
           # -DEMBREE_ROOT=/usr/local \
     # -DOPENSUBDIV_ROOT_DIR=/usr/local \
      -DPXR_STRICT_BUILD_MODE=OFF && \
    cmake --build . && \
    cmake --install . && \
    echo "OpenUSD build complete"

RUN --mount=type=cache,target=/tmp/build_linux \
    rm -rf  /tmp/build_linux

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


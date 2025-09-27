# Use an official ARM64 Ubuntu LTS image as the base.
# The --platform flag ensures the correct architecture is pulled.

# Blender
#FROM ubuntu:24.04
FROM python:3.11-bookworm

# Set frontend to noninteractive to avoid prompts during package installation
ENV DEBIAN_FRONTEND=noninteractive
# Set PYTHONPATH to custom site-packages directory
#ENV PYTHONPATH="/usr/local/lib/python3.11/dist-packages:${PYTHONPATH}"

## -j$(nproc) is removed as it cause issues

# Install essential build tools and dependencies
RUN apt update && \
    #apt install -y software-properties-common && apt update && \
    apt install -y \
    # Core build tools
    # gcc-14 g++-14 \
    build-essential git git-lfs ninja-build meson pkg-config subversion\
    autoconf automake bison libtool yasm tcl patchelf wget tar\
    python3.11-dev alembic libpython3-dev  libhpdf-dev libsystemd-dev dpkg\
    # python3-alembic python3-mako 
    # python3.11  \
    \
    # System libraries
    libc6 libstdc++6 libstdc++-11-dev libstdc++-12-dev libc6-dev linux-libc-dev libfftw3-dev  opencollada-dev libimath-dev\
    libusb-1.0-0-dev hydra libboost-all-dev libpugixml-dev  clang clang-format libclang-dev llvm-dev \
    # libbtbb-dev\
   #  python3-numpy python3-charset-normalizer python3-urllib3 python3-zstandard python3-requests python3-idna python3-certifi\
    \
    # Compression and crypto
    zlib1g-dev libzstd-dev libssl-dev libssl3 openssl libbrotli-dev libdeflate-dev libclipper2\
    \
    # Memory & testing
    libjemalloc-dev  valgrind libpystring-dev libneon-2-sse-dev\
    \
    # Wayland / X11 / Display
    libwayland-dev wayland-protocols\
    libx11-dev libxt-dev xauth libxcursor-dev libxi-dev libxrandr-dev libxinerama-dev libxkbcommon-dev\
    libxxf86vm-dev libxfixes-dev libxrender-dev xorg libx11-dev\
    libfontconfig1-dev libdbus-1-dev\
    \
    # OpenGL / GLES / Vulkan stack
    libepoxy-dev libvulkan-dev libshaderc-dev libshaderc1 \
    libgl1-mesa-dev libegl1-mesa-dev libegl-dev mesa-utils \
    libgles-dev libgles1 libgles2 libgles2-mesa-dev \
    libglfw3-dev libglew-dev opensubdiv-tools\
    # libembree3-3 libembree-dev  embree-tools 
    libopenxr-dev libopenxr-loader1 libopenxr-utils\ 
    \
    # Image I/O
    libjpeg-dev libjpeg62-turbo-dev libpng-dev libtiff-dev libopenexr-dev libopencolorio-dev libfreetype6-dev libopenimageio-dev openimageio-tools libopengl0 libopengl-dev libpotrace-dev libopenjp2-7-dev\
    \
    # Audio / Multimedia
    ffmpeg libswresample-dev libavdevice-dev libffado-dev libavformat-dev libavfilter-dev libopenal-dev libswscale-dev libsdl2-dev libsndfile1-dev libjack-jackd2-dev \
    libgstreamer1.0-0 libgstreamer1.0-dev libgstreamer-plugins-base1.0-dev gstreamer1.0-x gstreamer1.0-pulseaudio gstreamer1.0-alsa  libspnav-dev libopenvdb-dev  libopenvdb-ax-dev \
    libpulse-dev gstreamer1.0-adapter-pulseeffects libavahi-client-dev libcanberra-dev libwebrtc-audio-processing-dev liblilv-dev libebur128-dev libmysofa-dev libcap-dev\
    #  libpipewire-0.3-dev\
    \
    # Clean up
    && rm -rf /var/lib/apt/lists/* && \
    apt -qq clean

# Install Python packages via pip
RUN pip install --no-cache-dir --upgrade pip && \
    pip install --no-cache-dir numpy charset-normalizer urllib3 zstandard requests idna certifi alembic mako jinja2

# ---------------------------------------------------------------------- 

RUN mkdir -p /opt/cmake \
  && wget https://github.com/Kitware/CMake/releases/download/v4.1.1/cmake-4.1.1-linux-aarch64.sh -O /tmp/cmake-install.sh \
  && chmod +x /tmp/cmake-install.sh \
  && /tmp/cmake-install.sh --skip-license --prefix=/opt/cmake \
  && ln -s /opt/cmake/bin/* /usr/local/bin/ \
  && rm /tmp/cmake-install.sh \
  && echo "Done Installing CMake"
RUN cmake --version

# ---------------------------------------------------------------------- 

RUN  echo "Cloning MaterialX" && \
    git clone https://github.com/AcademySoftwareFoundation/MaterialX -b v1.39.4 --depth=1 --recursive /tmp/materialx && \
    mkdir -p /tmp/materialx/build && cd /tmp/materialx/build && \
    cmake -DCMAKE_BUILD_TYPE=Release -DCMAKE_INSTALL_PREFIX=/usr/local -DMATERIALX_BUILD_GRAPH_EDITOR=OFF -DMATERIALX_BUILD_PYTHON=ON \
	-DMATERIALX_BUILD_TESTS=OFF -DMATERIALX_BUILD_VIEWER=OFF -DCMAKE_CXX_FLAGS="-Wno-error=stringop-overflow" .. && \
    cmake --build .  && \
    cmake --install . && \
    rm -rf /tmp/materialx && \
    echo "Done Installing MaterialX"
#ENV MaterialX_DIR="/blender-git/materialx/"

# ----------------------------------------------------------------------
# Install SSE2NEON headers
RUN echo "Installing SSE2NEON headers" && \
    git clone --depth=1 https://github.com/DLTcollab/sse2neon.git /tmp/sse2neon && \
    mkdir -p /usr/local/include/sse2neon && \
    cp /tmp/sse2neon/sse2neon.h /usr/local/include/sse2neon/ && \
    rm -rf /tmp/sse2neon && \
    echo "SSE2NEON headers installed"
# ----------------------------------------------------------------------

# Clone, build, and install oneTBB v2022.2.0  -DTBB_WERROR=OFF 
RUN echo "Building TBB" && \
    git clone https://github.com/uxlfoundation/oneTBB --branch v2022.2.0 /tmp/tbb && \
    mkdir -p /tmp/tbb/build && cd /tmp/tbb/build && \
    cmake -DCMAKE_BUILD_TYPE=Release -DTBB_TEST=OFF -DCMAKE_INSTALL_PREFIX=/usr/local -DCMAKE_INTERPROCEDURAL_OPTIMIZATION=OFF -DCMAKE_CXX_FLAGS="-Wno-error=stringop-overflow" .. && \
    cmake --build .  && \
    cmake --install . && \
    rm -rf /tmp/tbb && \
    echo "Done Installing TBB"
ENV TBB_ROOT_DIR=/usr/local

# ----------------------------------------------------------------------

#RUN find /usr -name "*tbb*"
# Build OpenPGL v0.7.1 ARM64
#   -DBUILD_JOBS=4 \
# Build OpenPGL v0.7.1 for ARM64 without superbuild
RUN echo "Building OpenPGL (direct CMake build)" && \
    git clone --single-branch https://github.com/RenderKit/openpgl --branch v0.7.1 /tmp/openpgl && \
    mkdir -p /tmp/openpgl/build && cd /tmp/openpgl/build && \
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
    rm -rf /tmp/openpgl && \
    echo "OpenPGL direct build complete"



# ----------------------------------------------------------------------

RUN echo "Building OpenSubdiv" && \
    git clone https://github.com/PixarAnimationStudios/OpenSubdiv.git --depth=1 /tmp/OpenSubdiv && \
    mkdir -p /tmp/OpenSubdiv/build && cd /tmp/OpenSubdiv/build && \
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
    rm -rf /tmp/OpenSubdiv


# ----------------------------------------------------------------------
# Build Manifold v3.2.1 using system Clipper2 and existing TBB
RUN echo "Building Manifold v3.2.1" && \
    git clone https://github.com/elalish/manifold -b v3.2.1 --single-branch /tmp/manifold && \
    cd /tmp/manifold && mkdir -p build && cd build && \
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
    #  -DTBB_DIR=/usr/local/lib/cmake/TBB \
      -DCMAKE_CXX_FLAGS="-Wno-error=stringop-overflow" \
    #  -DFETCHCONTENT_DOWNLOADS=OFF \
      -DFETCHCONTENT_QUIET=OFF && \
    cmake --build . && \
    cmake --install . && \
    rm -rf /tmp/manifold
# ----------------------------------------------------------------------


# Tag v4.3.2-blender
RUN echo "Building Embree"
RUN git clone --branch v4.4.0 --single-branch https://github.com/RenderKit/embree.git /tmp/embree &&\
    mkdir -p /tmp/embree/build && cd /tmp/embree/build &&\
    # Interactive 
    #ccmake ..
    # Configure with cmake directly (non-interactive)
    cmake .. \
    -DCMAKE_BUILD_TYPE=Release \
    -DCMAKE_CXX_FLAGS="-Wno-error=stringop-overflow" \
    -DEMBREE_TUTORIALS=OFF \
    -DEMBREE_SYCL_SUPPORT=OFF \
    -DEMBREE_ISPC_SUPPORT=OFF \
    -DCMAKE_CXX_COMPILER=g++ \
    -DCMAKE_C_COMPILER=gcc \
    -DEMBREE_TESTING_INSTALL_TESTS=OFF \
    \
    && make  &&\
    make install
    
#    -DEMBREE_TUTORIALS_GLFW=OFF  -DEMBREE_BUILD_GLFW_FROM_SOURCE=OFF \-DCMAKE_INSTALL_PREFIX=/blender-git/embree/install\    
# ----------------------------------------------------------------------
# Build Alembic 1.8.8
RUN echo "Building Alembic" && \
git clone https://github.com/alembic/alembic/ -b 1.8.8 --depth=1 /tmp/alembic && \
mkdir -p /tmp/alembic/build && cd /tmp/alembic/build && \
cmake .. \
  -DCMAKE_BUILD_TYPE=Release \
  -DCMAKE_INSTALL_PREFIX=/usr/local \
  -DUSE_TESTS=OFF \
  -DALEMBIC_DEBUG_WARNINGS_AS_ERRORS=OFF \
  -DCMAKE_CXX_FLAGS="-O2 -fno-lto" \
  -DCMAKE_INTERPROCEDURAL_OPTIMIZATION=OFF && \    
cmake --build .  && \
cmake --install . && \
rm -rf /tmp/alembic

# No need to build Imath: libimath-dev is already installed and will be found by CMake
# ----------------------------------------------------------------------

#RUN find /usr -name "*embree*"  
# Build OpenUSD v25.08
#-DOpenSubdiv_DIR=/usr/lib/aarch64-linux-gnu/cmake/OpenSubdiv \
#-DTBB_DIR=/usr/lib/aarch64-linux-gnu/cmake/TBB \
RUN --mount=type=cache,target=usd echo "Building OpenUSD v25.05.01 " && \
    git clone https://github.com/PixarAnimationStudios/OpenUSD/ -b v25.05.01 --depth=1 /tmp/usd && \
    mkdir -p /tmp/usd/build && cd /tmp/usd/build && \
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
    #  -DPXR_BUILD_EMBREE_PLUGIN=OFF \
      -DPXR_BUILD_EMBREE_PLUGIN=ON \
          -DPXR_BUILD_ALEMBIC_PLUGIN=ON \
    #  -DPXR_BUILD_ALEMBIC_PLUGIN=OFF \
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
      -DPXR_PREFER_SAFETY_OVER_SPEED=ON \
      -DPXR_STRICT_BUILD_MODE=OFF && \
    cmake --build . && \
    cmake --install . && \
    rm -rf /tmp/usd && \
    echo "OpenUSD build complete"


#"------------------------PipeWire-------------------------------------"
#pwd
#ls -A /blender-git/pipewire
#find /blender-git/pipewire
# PipeWire
RUN echo "Building PipeWire v1.4.8 " &&\
    git clone https://github.com/PipeWire/pipewire --branch 1.4.8 --depth=1 /blender-git/pipewire &&\
    mkdir -p /tmp/pipewire/build && cd /tmp/pipewire/build && \
    # Configure (set Release build, install prefix to /usr/local)
    meson setup . .. --buildtype=release --backend=ninja --Dprefix=/usr/local  -Dtests=disabled -Ddocs=disabled -Dexamples=disabled \
        -Dinstalled_tests=disabled -Dlibcamera=disabled -Dcompress-offload=disabled -Djack=disabled  -Decho-cancel-webrtc=disabled \
        -Daudiotestsrc=disabled -Dsnap=disabled &&\
         #-Daudioconvert=disabled -Daudiomixer=disabled -Dspa-plugins=disabled \
     #-Dlibcamera=disabled -Dsystemd=disabled -Dbluez5=disabled \ 
   #  meson configure  .. Check COnfig 
    # Build
   meson compile -C . && \
  # Install (may need sudo depending on prefix)
   meson install -C .


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

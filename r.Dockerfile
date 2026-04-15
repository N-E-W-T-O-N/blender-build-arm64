#syntax=docker/dockerfile:1.4

################################################################################
# Stage "builder" – installs build dependencies and builds core libraries
################################################################################
FROM rockylinux:9 AS builder

ENV DEBIAN_FRONTEND=noninteractive
ENV TERM=xterm

# Enable EPEL and update
# Install core build tools, libraries, and RPMs for OpenColorIO, OpenSubdiv, and Manifold
RUN dnf install -y epel-release && \
    dnf config-manager --set-enabled crb devel && \
    dnf groupinstall -y "Development Tools"  "Multimedia"  && \
    dnf install -y \
    git git-lfs ninja-build meson pkgconfig subversion cmake \
    autoconf automake bison libtool yasm tcl patchelf wget tar \
    python3-devel pybind11-devel alembic systemd-devel yaml-cpp-devel hpdf-devel \
    dpkg-libdpkg-devel \
    fftw-devel openCOLLADA-devel imath-devel \
    libusb1-devel boost-devel pugixml-devel clang clang-tools-extra llvm-devel \
    robin-map-devel \
    zlib-devel libzstd-devel openssl-devel brotli-devel libdeflate-devel \
    jemalloc-devel valgrind pystring-devel \
    wayland-devel libX11-devel libXcursor-devel libXrandr-devel libxkbcommon-devel \
    libXfixes-devel libXinerama-devel fontconfig-devel dbus-devel xorg-x11-server-utils \
    libepoxy-devel vulkan-loader-devel shaderc-devel mesa-libGL-devel mesa-libEGL-devel \
    mesa-libGLES-devel glfw-devel glew-devel \
    libopenxr-devel openxr-loader-devel \
    libjpeg-turbo-devel libpng-devel libtiff-devel openexr-devel freetype-devel \
    potrace-devel libwebp-devel \
    ffmpeg-devel SDL2-devel libsndfile-devel jack-audio-connection-kit-devel \
    gstreamer1-devel gstreamer1-plugins-base-devel \
    pulseaudio-libs-devel avahi-devel libcanberra-devel libwebrtc-audio-processing-devel \
    lilv-devel ebur128-devel mysofa-devel libcap-devel \
    rpm-build rpm-devel alembic-devel \
    # Install OpenColorIO and OpenSubdiv from RPM URLs
    OpenColorIO-devel OpenSubdiv-devel \
    manifold-devel \
    && dnf clean all

# Install Python packages via pip (cache)
RUN python3 -m pip install --upgrade pip && \
    python3 -m pip install --no-cache-dir \
    numpy charset-normalizer urllib3 zstandard requests idna certifi alembic mako jinja2

# Prepare build workspace
WORKDIR /tmp

# 1. SSE2NEON headers
RUN git clone --depth=1 https://github.com/DLTcollab/sse2neon.git sse2neon && \
    install -Dm644 sse2neon/sse2neon.h /usr/local/include/sse2neon/sse2neon.h && \
    rm -rf sse2neon

# 2. Wayland-Protocols
RUN git clone -b 1.44 https://gitlab.freedesktop.org/wayland/wayland-protocols wayland && \
    mkdir -p wayland/build && cd wayland/build && \
    meson setup build .. --buildtype=release -Dprefix=/usr/local -Dtests=false && \
    meson compile -C build && meson install -C build && rm -rf wayland

# 3. ISPC
RUN mkdir -p /opt/ispc && \
    wget -q https://github.com/ispc/ispc/releases/download/v1.28.2/ispc-v1.28.2-linux.aarch64.tar.gz -O ispc.tar.gz && \
    tar -xzf ispc.tar.gz -C /opt/ispc --strip-components=1 && \
    rm ispc.tar.gz

# 4. TBB
RUN git clone --branch v2022.2.0 https://github.com/uxlfoundation/oneTBB tbb && \
    cd tbb && mkdir build && cd build && \
    cmake -DCMAKE_BUILD_TYPE=Release -DCMAKE_INSTALL_PREFIX=/usr/local \
    -DCMAKE_INTERPROCEDURAL_OPTIMIZATION=OFF \
    -DCMAKE_CXX_FLAGS="-Wno-error=stringop-overflow" .. && \
    cmake --build . && cmake --install . && rm -rf tbb

# 5. Vulkan-Headers
RUN git clone --depth=1 -b v1.3.296 https://github.com/KhronosGroup/Vulkan-Headers.git vulkan && \
    cd vulkan && cmake -S . -B build -DVULKAN_HEADERS_ENABLE_TESTS=OFF && \
    cmake --install build && rm -rf vulkan

FROM builder AS midbuilder    

# 6. OpenColorIO v2.5.0
RUN git clone --branch v2.5.0 --depth=1 https://github.com/AcademySoftwareFoundation/OpenColorIO ocio && \
    mkdir -p ocio/build && cd ocio/build && \
    cmake .. -GNinja -DCMAKE_BUILD_TYPE=Release -DCMAKE_INSTALL_PREFIX=/usr/local \
    -DBUILD_SHARED_LIBS=ON -DBUILD_DOCS=OFF -DOCIO_INSTALL_EXT_PACKAGES=MISSING \
    -DOCIO_BUILD_PYTHON=ON -DOCIO_USE_SIMD=ON -DOCIO_USE_SSE2=ON \
    -DOCIO_WARNING_AS_ERROR=OFF && \
    cmake --build . && cmake --install . && rm -rf ocio

# 7. OpenImageIO v3.0.6.1
RUN git clone --branch v3.0.6.1 --depth=1 https://github.com/AcademySoftwareFoundation/OpenImageIO oiio && \
    mkdir -p oiio/build && cd oiio/build && \
    cmake .. -GNinja -DCMAKE_BUILD_TYPE=Release -DCMAKE_INSTALL_PREFIX=/usr/local \
    -DUSE_OPENCOLORIO=ON -DUSE_WEBP=ON -DUSE_TBB=ON -DUSE_PYTHON=ON \
    -DUSE_OPENJPEG=ON -DOpenColorIO_DIR=/usr/local \
    -DOIIO_BUILD_MISSING_DEPS=all -DBUILD_DOCS=OFF -DUSE_OPENVDB=OFF \
    -DSTOP_ON_WARNING=OFF && \
    cmake --build . && cmake --install . && rm -rf oiio

# 8. Intel OIDN v2.3.3
RUN wget -q https://github.com/RenderKit/oidn/releases/download/v2.3.3/oidn-2.3.3.src.tar.gz -O oidn.tar.gz && \
    mkdir oidn && tar -xzf oidn.tar.gz -C oidn --strip-components=1 && rm oidn.tar.gz && \
    cd oidn && mkdir build && cd build && \
    cmake .. -GNinja -DCMAKE_BUILD_TYPE=Release \
    -DOIDN_APPS=OFF -DOIDN_DEVICE_CUDA=OFF -DOIDN_DEVICE_SYCL=OFF \
    -DOIDN_INSTALL_DEPENDENCIES=ON -DCMAKE_INSTALL_PREFIX=/usr/local \
    -DISPC_EXECUTABLE=/opt/ispc/bin/ispc && \
    cmake --build . && cmake --install . && rm -rf /tmp/oidn

################################################################################
# Stage "midbuilder" – adds MaterialX, OpenPGL, OpenSubdiv, Manifold, Embree4,
# Alembic and PipeWire
################################################################################
FROM midbuilder AS postbuilder

WORKDIR /tmp

# 9. MaterialX v1.39.4
RUN git clone -b v1.39.4 --depth=1 https://github.com/AcademySoftwareFoundation/MaterialX.git materialx && \
    mkdir materialx/build && cd materialx/build && \
    cmake .. -GNinja -DCMAKE_BUILD_TYPE=Release -DCMAKE_INSTALL_PREFIX=/usr/local \
    -DMATERIALX_BUILD_PYTHON=ON -DMATERIALX_BUILD_TESTS=OFF \
    -DCMAKE_CXX_FLAGS="-Wno-error=stringop-overflow" && \
    cmake --build . && cmake --install . && rm -rf materialx

# 10. OpenPGL v0.7.1
RUN git clone --branch v0.7.1 --single-branch https://github.com/RenderKit/openpgl openpgl && \
    mkdir openpgl/build && cd openpgl/build && \
    cmake .. -GNinja -DCMAKE_BUILD_TYPE=Release -DCMAKE_INSTALL_PREFIX=/usr/local \
    -DOPENPGL_ISA_NEON=ON -DOPENPGL_TBB_ROOT=/usr/local && \
    cmake --build . && cmake --install . && rm -rf openpgl

# 11. OpenSubdiv (RPM-installed) – skip source build

# 12. Manifold (RPM-installed) – skip source build

# 13. Embree4 v4.4.0
RUN git clone --branch v4.4.0 --single-branch https://github.com/RenderKit/embree.git embree && \
    mkdir embree/build && cd embree/build && \
    cmake .. -DCMAKE_BUILD_TYPE=Release \
    -DEMBREE_ISPC_SUPPORT=ON -DEMBREE_ISPC_EXECUTABLE=/opt/ispc/bin/ispc \
    -DCMAKE_INSTALL_PREFIX=/usr/local && \
    cmake --build . && cmake --install . && rm -rf embree

# 14. Alembic v1.8.8
# RUN git clone -b 1.8.8 --depth=1 https://github.com/alembic/alembic alembic && \
#     mkdir alembic/build && cd alembic/build && \
#     cmake .. -GNinja -DCMAKE_BUILD_TYPE=Release -DCMAKE_INSTALL_PREFIX=/usr/local \
#     -DUSE_TESTS=OFF -DALEMBIC_DEBUG_WARNINGS_AS_ERRORS=OFF && \
#     cmake --build . && cmake --install . && rm -rf alembic

# 15. PipeWire v1.4.8
RUN git clone --branch 1.4.8 --depth=1 https://github.com/PipeWire/pipewire pipewire && \
    mkdir pipewire/build && cd pipewire/build && \
    meson setup . .. --buildtype=release -Dprefix=/usr/local --backend=ninja \
    -Dtests=disabled -Ddocs=disabled -Dexamples=disabled && \
    meson compile -C . && meson install -C . && rm -rf pipewire

################################################################################
# Stage “final” – uses midbuilder as base and compiles OpenUSD v25.08
################################################################################
FROM postbuilder AS final

WORKDIR /tmp

RUN git clone --branch v25.08 --depth=1 https://github.com/PixarAnimationStudios/OpenUSD OpenUSD && \
    mkdir OpenUSD/build && cd OpenUSD/build && \
    cmake .. -GNinja -DCMAKE_INSTALL_PREFIX=/usr/local \
    -DCMAKE_BUILD_TYPE=Release \
    -DCMAKE_CXX_FLAGS="-Wno-error=stringop-overflow" \
    -DTBB_ROOT=/usr/local \
    -DEMBREE_INCLUDE_DIR=/usr/local/include/embree3 \
    -DEMBREE_LIBRARY=/usr/local/lib/libembree4.so \
    -DPXR_BUILD_MONOLITHIC=ON \
    -DPXR_ENABLE_GL_SUPPORT=ON \
    -DMaterialX_ROOT=/usr/local \
    -DPXR_BUILD_EMBREE_PLUGIN=ON \
    -DPXR_ENABLE_PYTHON_SUPPORT=ON \
    -DPXR_BUILD_OPENCOLORIO_PLUGIN=ON \
    -DPXR_BUILD_OPENIMAGEIO_PLUGIN=ON \
    -DPXR_BUILD_TESTS=OFF \
    -DPXR_BUILD_USDVIEW=OFF \
    -DPXR_BUILD_EXEC=OFF \
    -DPXR_ENABLE_OPENVDB_SUPPORT=OFF \
    -DPXR_ENABLE_METAL_SUPPORT=OFF \
    -DPXR_ENABLE_VULKAN_SUPPORT=OFF \
    -DPXR_ENABLE_OSL_SUPPORT=OFF \
    -DPXR_BUILD_DOCUMENTATION=OFF \
    -DPXR_ENABLE_PRECOMPILED_HEADERS=OFF \
    -DPXR_STRICT_BUILD_MODE=OFF \
    -DCMAKE_VERBOSE_MAKEFILE=ON && \
    cmake --build . && cmake --install . && rm -rf OpenUSD

# Common final steps
WORKDIR /blender-git
RUN useradd --create-home --shell /bin/bash builder && \
    usermod -aG wheel builder && \
    echo 'builder ALL=(ALL) NOPASSWD:ALL' >> /etc/sudoers

COPY --chown=builder:builder compile.sh /compile.sh
RUN chmod +x /compile.sh

ENTRYPOINT ["/compile.sh"]

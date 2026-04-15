# syntax=docker/dockerfile:1

# Blender Builder - ARM64 Optimized with Cache Mounts
# Use an official Fedora image as the base.
# The --platform flag ensures the correct architecture is pulled.
# MaterialX with cache mount

FROM fedora:42 AS builder

# Install essential build tools and dependencies with cache mounts
# This single RUN command consolidates all system dependencies to optimize layer caching.
# Set frontend to noninteractive equivalent and TERM
#ENV TERM=xterm
# Note: Fedora doesn't use DEBIAN_FRONTEND, dnf handles non-interactive mode differently

# Install essential build tools and dependencies with cache mounts
# This single RUN command consolidates all system dependencies to optimize layer caching.
# Configure dnf and use a reliable mirror
#RUN echo -e '[main]\nfastestmirror=True\nmax_parallel_downloads=1\nskip_if_unavailable=True\nip_resolve=4' > /etc/dnf/dnf.conf 
# Install dependencies with caching

RUN --mount=type=cache,target=/var/cache/libdnf5/  \
    getent group cgred >/dev/null || groupadd cgred && \
    dnf -y update && \
    # Core build tools (equivalent to build-essential)
    dnf install -y dnf-plugins-core @c-development @development-tools @graphics \
    \
    # --- Core Development & Build Tools ---
    git git-lfs ninja-build meson pkgconf subversion python3.11 python3.11-devel binutils-gold  python3.11-libs python3.11-pip \
    autoconf automake bison libtool yasm patchelf wget tar binutils-gold \
    cmake gcc-c++ patch rpm-build \
    \
    # --- System & Math Libraries ---
    glibc glibc-devel libstdc++-devel kernel-devel \
    gmp-devel fftw-devel  sse2neon-devel\
    \
    # --- VFX & Rendering Core Libraries ---
    alembic-devel openvdb-devel opensubdiv-devel \
    openshadinglanguage-devel \
    OpenImageIO-utils openexr-devel imath-devel \
    embree-devel openpgl-devel \
    potrace-devel harfbuzz-devel \
    # Added missing core VFX libraries
    OpenColorIO-devel OpenImageIO-devel openCOLLADA-devel \
    \
    # --- Graphics, Windowing & Display (X11/Wayland) ---
    wayland-devel wayland-protocols-devel libdecor-devel \
    libX11-devel libXt-devel libXcursor-devel libXi-devel \
    libXrandr-devel libxkbcommon-devel libXxf86vm-devel \
    libXfixes-devel libXrender-devel libXinerama-devel \
    fontconfig-devel systemd-libs dbus-devel xorg-x11-server-Xorg xorg-x11-xauth \
    \
    # --- GPU & Shading APIs (OpenGL/Vulkan) ---
    mesa-libGL-devel mesa-libEGL-devel egl-wayland-devel \
    mesa-dri-drivers mesa-libGLES-devel libepoxy-devel \
    glew-devel glfw-devel openxr-devel libshaderc-devel \
    vulkan-headers vulkan-loader-devel vulkan-devel openvdb-devel \
    \
    # --- Image I/O & Formats ---
    libjpeg-turbo-devel libpng-devel libtiff-devel \
    openjpeg2-devel libwebp-devel libharu-devel \
    \
    # --- Audio & Multimedia ---
    ffmpeg-free-devel libavcodec-free-devel libavdevice-free-devel libswresample-free-devel \
    libavformat-free-devel libavfilter-free-devel libswscale-free-devel \
    openal-soft-devel SDL2-devel libsndfile-devel  pulseaudio-libs-devel \
    jack-audio-connection-kit-devel gstreamer1-devel gstreamer1-plugins-base-devel \
    \
    # --- Utility & Helper Libraries ---
    boost-devel pugixml-devel yaml-cpp-devel pystring-devel \
    zlib-devel libzstd-devel openssl-devel openssl brotli-devel \
    libdeflate-devel jemalloc-devel blosc-devel \
    clang-devel llvm-devel clang clang-tools-extra \
     libusb1-devel \
    # Added missing utility libraries from original request
    dpkg-devel robin-map-devel \
    \
    # --- Miscellaneous Libraries ---
    libspnav-devel avahi-devel libcanberra-devel \
    webrtc-audio-processing-devel lilv-devel libebur128-devel \
    libmysofa-devel libcap-devel hydra valgrind uhd-devel \
    --skip-broken --skip-unavailable  --setopt=tsflags=nocontexts,noscripts systemd-udev usbmuxd
    # Clean up dnf cache to reduce image size
    # && dnf clean all

# Configure Python 3.11 as the default 'python3'
RUN update-alternatives --install /usr/bin/python3 python3 /usr/bin/python3.11 100

# Configure Python 3.11 as the default 'python'
RUN update-alternatives --install /usr/bin/python python /usr/bin/python3.11 100

# Install remaining Python packages via pip with cache mount
# Only packages not available in Fedora repositories are installed here.

RUN --mount=type=cache,target=/root/.cache/pip \
    python3.11 -m ensurepip --upgrade  && \
    python3.11 -m pip install --no-cache-dir numpy charset-normalizer urllib3 zstandard requests \
        idna certifi alembic cython mako jinja2 nanobind fastjsonschema  cattrs pybind11

#RUN  --mount=type=cache,target=/var/cache/dnf \
#    --mount=type=cache,target=/var/lib/dnf \
#    dnf install -y \
#    python3-pybind11 python3-numpy \
#    python3-requests python3-certifi python3-idna python3-urllib3 \
#    python3-charset-normalizer python3-zstandard python3-cattrs  \
#    python3-cython python3-fastjsonschema 
    
# oneapi-level-zero-devel opencollada-devel
# Set PYTHONPATH to custom site-packages directory (adjusted for Fedora paths)
#ENV PYTHONPATH="/usR/lib/python3.11/site-packages:${PYTHONPATH}"



# Fix for SSL certificate issues by pointing standard ENV VARS to certifi's bundle.
# This resolves the CMake warning about not finding "certifi/cacert.pem".
# RUN CERTIFI_PATH=$(python3.11 -c "import certifi; print(certifi.where())") && \
#     echo "export REQUESTS_CA_BUNDLE=${CERTIFI_PATH}" >> /etc/profile.d/certifi.sh && \
#     echo "export SSL_CERT_FILE=${CERTIFI_PATH}" >> /etc/profile.d/certifi.sh


# --- Python Ecosystem ---

    
# RUN echo "Add ISPC" && mkdir -p /opt/ispc && \
#     wget -q https://github.com/ispc/ispc/releases/download/v1.28.2/ispc-v1.28.2-linux.aarch64.tar.gz \
#             -O ispc.tar.gz && \
#     tar -xzf ispc.tar.gz -C /opt/ispc --strip-components=1 && \
#     rm ispc.tar.gz

# # TBB
# RUN  --mount=type=bind,target=/tmp/tbb,source=tbb,rw \    
#     cd /tmp/tbb/build &&  cmake --build . && cmake --install .   

# Oidn
#RUN  --mount=type=bind,target=/tmp/oidn,source=oidn,rw \    
#    cd /tmp/oidn/build && cmake --build . && cmake --install . 

# RUN git clone -b Clipper2_1.5.4 https://github.com/AngusJohnson/Clipper2 /tmp/clipper && \
#     mkdir -p /tmp/clipper/CPP/build && cd /tmp/clipper/CPP/build && \
#     cmake .. -DCMAKE_BUILD_TYPE=Release  -DCMAKE_INSTALL_PREFIX=/usr/local -DCLIPPER2_EXAMPLES=OFF -DCLIPPER2_TESTS=OFF  \
#     && cmake --build . && cmake --install .

# RUN echo "Building Manifold v3.2.1" && \
#     git clone https://github.com/elalish/manifold -b v3.2.1 --single-branch /tmp/manifold && \
#     cd /tmp/build_linux/manifold && mkdir -p build && cd build && \
#     cmake .. \
#       -G Ninja \
#       -DCMAKE_BUILD_TYPE=Release \
#       -DCMAKE_INSTALL_PREFIX=/usr/local \
#       -DBUILD_SHARED_LIBS=ON \
#       -DBUILD_TESTING=OFF \
#       -DMANIFOLD_TEST=OFF \
#       -DMANIFOLD_DEBUG=OFF \
#       -DMANIFOLD_STRICT=ON \
#       -DMANIFOLD_PAR=ON \
#       -DMANIFOLD_CROSS_SECTION=ON \
#       -DMANIFOLD_CBIND=ON \
#       -DMANIFOLD_PYBIND=ON \
#       -DMANIFOLD_EXPORT=OFF \
#       -DMANIFOLD_DOWNLOADS=ON \
#       -DMANIFOLD_USE_BUILTIN_TBB=OFF \
#       -DMANIFOLD_USE_BUILTIN_CLIPPER2=ON \
#       -DMANIFOLD_USE_BUILTIN_NANOBIND=OFF \
#       -DClipper2_DIR=/usr/lib/aarch64-linux-gnu/cmake/Clipper2 \
#       -DCMAKE_CXX_FLAGS="-Wno-error=stringop-overflow" \
#       -DFETCHCONTENT_DOWNLOADS=OFF \
#       -DFETCHCONTENT_QUIET=ON && \
#       && cmake --build . && \
#       cmake --install . && rm /tmp/manifold 

      
# In case depot_tools expects pip-installed deps, ensure it’s covered:
#RUN pip install --no-cache-dir httplib2 httplib2[socks] PySocks six pyasn1 pyasn1-modules urllib3
# Create a non-root user for the build process for security
# and grant passwordless sudo privileges.
#RUN useradd --create-home --shell /bin/bash builder && \
#    adduser builder sudo && \
#    echo 'builder ALL=(ALL) NOPASSWD:ALL' >> /etc/sudoers


# Switch to the non-root user
#USER builder
#WORKDIR /blender-git

# Copy the compile script into the container and make it executable
#COPY --chown=builder:builder compile.sh /compile.sh
#RUN chmod +x /compile.sh

# Set the entrypoint to our compile script
#ENTRYPOINT ["/compile.sh"]

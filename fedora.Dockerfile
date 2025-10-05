# syntax=docker/dockerfile:1

# Blender Builder - ARM64 Optimized with Cache Mounts
# Use an official Fedora image as the base.
# The --platform flag ensures the correct architecture is pulled.
# MaterialX with cache mount

FROM fedora:42

# Set frontend to noninteractive equivalent and TERM
#ENV TERM=xterm
# Note: Fedora doesn't use DEBIAN_FRONTEND, dnf handles non-interactive mode differently

# Install essential build tools and dependencies with cache mounts
# This single RUN command consolidates all system dependencies to optimize layer caching.
RUN --mount=type=cache,target=/var/cache/dnf \
    --mount=type=cache,target=/var/lib/dnf \
    dnf update -y && \
    # Core build tools (equivalent to build-essential)
    dnf install -y dnf-plugins-core @c-development @development-tools\
    \
    # --- Core Development & Build Tools ---
    git git-lfs ninja-build meson pkgconf subversion \
    autoconf automake bison libtool yasm patchelf wget tar \
    cmake gcc-c++ patch rpm-build \
    \
    # --- System & Math Libraries ---
    glibc glibc-devel libstdc++-devel kernel-devel \
    gmp-devel fftw-devel tbb-devel tbb sse2neon-devel\
    \
    # --- Python Ecosystem ---
    python3-devel python3-libs python3-pybind11 python3-numpy \
    python3-requests python3-certifi python3-idna python3-urllib3 \
    python3-charset-normalizer python3-zstandard python3-cattrs \
    python3-cython python3-fastjsonschema \
    \
    # --- VFX & Rendering Core Libraries ---
    alembic-devel usd usd-devel openvdb-devel opensubdiv-devel \
    openshadinglanguage-devel \
    OpenImageIO-utils openexr-devel imath-devel \
    embree-devel openpgl-devel \
    potrace-devel harfbuzz-devel \
    \
    # --- Graphics, Windowing & Display (X11/Wayland) ---
    wayland-devel wayland-protocols-devel libdecor-devel \
    libX11-devel libXt-devel libXcursor-devel libXi-devel \
    libXrandr-devel libxkbcommon-devel libXxf86vm-devel \
    libXfixes-devel libXrender-devel libXinerama-devel \
    fontconfig-devel dbus-devel xorg-x11-server-Xorg xorg-x11-xauth \
    \
    # --- GPU & Shading APIs (OpenGL/Vulkan) ---
    mesa-libGL-devel mesa-libEGL-devel egl-wayland-devel \
    mesa-dri-drivers mesa-libGLES-devel libepoxy-devel \
    glew-devel glfw-devel openxr-devel libshaderc-devel \
    vulkan-headers vulkan-loader-devel vulkan-devel \

    \
    # --- Image I/O & Formats ---
    libjpeg-turbo-devel libpng-devel libtiff-devel \
    openjpeg2-devel libwebp-devel libharu-devel \
    \
    # --- Audio & Multimedia ---
    ffmpeg-free-devel libswresample-free-devel libavdevice-free-devel \
    libavformat-free-devel libavfilter-free-devel libswscale-free-devel \
    openal-soft-devel SDL2-devel libsndfile-devel \
    jack-audio-connection-kit-devel gstreamer1-devel gstreamer1-plugins-base-devel \
    pulseaudio-libs-devel  \
    # --- Utility & Helper Libraries ---
    boost-devel pugixml-devel yaml-cpp-devel pystring-devel \
    zlib-devel libzstd-devel openssl-devel openssl brotli-devel \
    libdeflate-devel jemalloc-devel blosc-devel \
    clang-devel llvm-devel clang clang-tools-extra \
    ispc ispc-devel systemd-devel libusb1-devel \
    \
    # --- Miscellaneous Libraries ---
    libspnav-devel avahi-devel libcanberra-devel \
    webrtc-audio-processing-devel lilv-devel libebur128-devel \
    libmysofa-devel libcap-devel hydra valgrind uhd-devel \
    --skip-broken --skip-unavailable \
    # Clean up dnf cache to reduce image size
    && dnf clean all
    
# oneapi-level-zero-devel opencollada-devel
# Set PYTHONPATH to custom site-packages directory (adjusted for Fedora paths)
ENV PYTHONPATH="/usr/local/lib/python3.11/site-packages:${PYTHONPATH}"

# Install remaining Python packages via pip with cache mount
# Only packages not available in Fedora repositories are installed here.
RUN --mount=type=cache,target=/root/.cache/pip \
    pip install --upgrade pip && \
    pip install numpy charset-normalizer urllib3 zstandard requests idna certifi alembic mako jinja2


# Install Nix and required packages
RUN mkdir /nix && \
    sh <(curl -L https://nixos.org/nix/install) --no-daemon && \
    nix-channel --add https://nixos.org/channels/nixpkgs-unstable nixpkgs && \
    nix-channel --update && \
    nix-env -iA \
      nixpkgs.materialx \
      nixpkgs.openvdb \
      nixpkgs.openimageio nixpkgs.pipewire \
      nixpkgs.openimagedenoise

ENV PATH=/root/.nix-profile/bin:/nix/var/nix/profiles/default/bin:$PATH

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

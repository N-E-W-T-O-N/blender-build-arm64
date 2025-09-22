# Use an official ARM64 Ubuntu LTS image as the base.
# The --platform flag ensures the correct architecture is pulled.

# Blender
#FROM ubuntu:24.04
FROM python:3.11-bookworm

# Set frontend to noninteractive to avoid prompts during package installation
ENV DEBIAN_FRONTEND=noninteractive
# Set PYTHONPATH to custom site-packages directory
#ENV PYTHONPATH="/usr/local/lib/python3.11/dist-packages:${PYTHONPATH}"

# Install essential build tools and dependencies
RUN apt update && \
    #apt install -y software-properties-common && apt update && \
    apt install -y \
    # Core build tools
    # gcc-14 g++-14 \
    build-essential git git-lfs ninja-build meson pkg-config subversion\
    autoconf automake bison libtool yasm tcl patchelf wget tar\
    python3.11-dev alembic  libhpdf-dev dpkg\
    # python3-alembic python3-mako 
    # python3.11  \
    \
    # System libraries
    libc6 libstdc++6 linux-libc-dev libfftw3-dev  opencollada-dev libimath-dev\
    libusb-dev hydra libboost-all-dev libpugixml-dev libbtbb-dev clang clang-format libclang-dev llvm-dev\
   #  python3-numpy python3-charset-normalizer python3-urllib3 python3-zstandard python3-requests python3-idna python3-certifi\
    \
    # Compression and crypto
    zlib1g-dev libzstd-dev libssl-dev libssl3 openssl libbrotli-dev libdeflate-dev\
    \
    # Memory & testing
    libjemalloc-dev libtbb-dev valgrind libpystring-dev\
    \
    # Wayland / X11 / Display
    libwayland-dev wayland-protocols\
    libx11-dev libxt-dev xauth libxcursor-dev libxi-dev libxrandr-dev libxinerama-dev libxkbcommon-dev\
    libxxf86vm-dev libxfixes-dev libxrender-dev xorg\
    libfontconfig1-dev libdbus-1-dev\
    \
    # OpenGL / GLES / Vulkan stack
    libepoxy-dev libvulkan-dev libshaderc-dev libshaderc1 \
    libgl1-mesa-dev libegl1-mesa-dev libegl-dev mesa-utils \
    libgles-dev libgles1 libgles2 libgles2-mesa-dev \
    libglfw3-dev libglew-dev libembree3-3 libembree-dev embree-tools opensubdiv-tools\
    libopenxr-dev libopenxr-loader1 libopenxr-utils\
    \
    # Image I/O
    libjpeg-dev libjpeg62-turbo-dev libpng-dev libtiff-dev libopenexr-dev libopencolorio-dev libfreetype6-dev libopenimageio-dev openimageio-tools libopengl0 libopengl-dev libpotrace-dev libopenjp2-7-dev\
    \
    # Audio / Multimedia
    ffmpeg libswresample-dev libavdevice-dev libavformat-dev libavfilter-dev libopenal-dev libswscale-dev libsdl2-dev libsndfile1-dev libjack-jackd2-dev spacenavd libopenvdb-dev libopenvdb-ax-dev libpipewire-0.3-dev libpulse-dev\
    \
    # Clean up
    && rm -rf /var/lib/apt/lists/* && \
    apt -qq clean

# Install Python packages via pip
RUN pip install --no-cache-dir --upgrade pip && \
    pip install --no-cache-dir numpy charset-normalizer urllib3 zstandard requests idna certifi alembic mako


RUN mkdir -p /opt/cmake \
  && wget https://github.com/Kitware/CMake/releases/download/v4.1.1/cmake-4.1.1-linux-aarch64.sh -O /tmp/cmake-install.sh \
  && chmod +x /tmp/cmake-install.sh \
  && /tmp/cmake-install.sh --skip-license --prefix=/opt/cmake \
  && ln -s /opt/cmake/bin/* /usr/local/bin/ \
  && rm /tmp/cmake-install.sh

RUN cmake --version

# In case depot_tools expects pip-installed deps, ensure it’s covered:
#RUN pip install --no-cache-dir httplib2 httplib2[socks] PySocks six pyasn1 pyasn1-modules urllib3
# Create a non-root user for the build process for security
# and grant passwordless sudo privileges.
RUN useradd --create-home --shell /bin/bash builder && \
    adduser builder sudo && \
    echo 'builder ALL=(ALL) NOPASSWD:ALL' >> /etc/sudoers

# Switch to the non-root user
#USER builder
WORKDIR /builder-git

# Copy the compile script into the container and make it executable
COPY --chown=builder:builder compile.sh /compile.sh
RUN chmod +x /compile.sh

# Set the entrypoint to our compile script
ENTRYPOINT ["/compile.sh"]

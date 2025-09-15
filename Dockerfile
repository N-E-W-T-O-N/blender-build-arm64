# Use an official ARM64 Ubuntu LTS image as the base.
# The --platform flag ensures the correct architecture is pulled.

# Blender
FROM ubuntu:22.04

# Set frontend to noninteractive to avoid prompts during package installation
ENV DEBIAN_FRONTEND=noninteractive

# Install essential build tools and dependencies
RUN apt-get update && apt-get install -y \
    build-essential git git-lfs cmake \
    libx11-dev libxxf86vm-dev libxcursor-dev libxi-dev libxrandr-dev libxinerama-dev libgl1-mesa-dev \
    libegl-dev libwayland-dev wayland-protocols libxkbcommon-dev libfontconfig1-dev libdbus-1-dev \
    linux-libc-dev autoconf automake bison libtool yasm tcl ninja-build meson python3-mako patchelf pkg-config \
    libssl-dev libssl3 openssl \
    pkg-config python3 subversion sudo && \
    rm -rf /var/lib/apt/lists/* && \
    apt-get -qq clean


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

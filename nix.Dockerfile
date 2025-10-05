# syntax=docker/dockerfile:1

############################################################
# Builder stage: Install and build dependencies
############################################################
FROM nixos/nix:latest-arm64 AS builder

# Configure Nix: enable flakes, disable sandbox
# Configure Nix: enable flakes, disable sandbox (temporary workaround)
RUN mkdir -p /etc/nix && \
    printf '%s\n' \
      'filter-syscalls = false' \
      'experimental-features = nix-command flakes' \
    >> /etc/nix/nix.conf && \
    nix-channel --add https://nixos.org/channels/nixpkgs-unstable nixpkgs && \
    nix-channel --update

# WORKAROUND: Disable Nix's seccomp-based syscall filtering.
# This is necessary to prevent the "unable to load seccomp BPF program" error
# when building in a cross-architecture emulated environment (e.g., QEMU).
# See: https://github.com/NixOS/nix/issues/5258
#RUN echo "filter-syscalls = false" >> /etc/nix/nix.conf
# Add and update the unstable channel


WORKDIR /workspace

# Install all required packages from nixpkgs
RUN nix-env -iA \
      nixpkgs.buildPackages.gcc                   \   
      # build-essential
      nixpkgs.gitMinimal                  \
      nixpkgs.git-lfs                             \
      nixpkgs.buildPackages.ninja                 \
      nixpkgs.buildPackages.meson                 \
      nixpkgs.pkg-config                          \
      nixpkgs.subversion                          \
      nixpkgs.autoconf                            \
      nixpkgs.automake                            \
      nixpkgs.bison                               \
      nixpkgs.libtool                            \
      nixpkgs.yasm                                \
      nixpkgs.patchelf                            \
      nixpkgs.wget                                \
      nixpkgs.gnutar                             \
      nixpkgs.tcl                                 \
      nixpkgs.python311                           \   
      # python3.11-dev
      nixpkgs.python311Packages.pybind11          \
      nixpkgs.alembic                             \
      nixpkgs.yaml-cpp                            \
      nixpkgs.systemd                            \
      nixpkgs.dpkg                                \
                                                   \
      # System libraries                        \
      nixpkgs.glibc                              \
      nixpkgs.gcc                                 \
      nixpkgs.libgcc                             \
      nixpkgs.libsigcxx                          \
      nixpkgs.gccNGPackages_15.libstdcxx         \ 
      nixpkgs.libcxx                             \
      nixpkgs.fftw                               \
      nixpkgs.opencollada                        \
      nixpkgs.imath                              \
      nixpkgs.libusb1                            \
      nixpkgs.hydra                              \
      nixpkgs.boost                              \
      nixpkgs.pugixml                            \
      nixpkgs.llvm                               \
      nixpkgs.robin-map                         \
      nixpkgs.sse2neon                           \
                                                \
      # Compression & crypto                   \
      nixpkgs.zlib                               \
      nixpkgs.zstd                               \
      nixpkgs.openssl                            \
      nixpkgs.brotli                             \
      nixpkgs.libdeflate                         \
                                                   \
      # Memory & testing                       \
      nixpkgs.jemalloc                           \
      nixpkgs.valgrind                           \
      nixpkgs.pystring                           \
                                                   \
      # Wayland / X11 / Display                \
      nixpkgs.wayland                            \
      nixpkgs.wayland-protocols                  \
      nixpkgs.xorg.libX11                        \
      nixpkgs.xorg.libXi                         \
      nixpkgs.xorg.libXcursor                    \
      nixpkgs.libxkbcommon                       \
      nixpkgs.xorg.libXxf86vm                    \
      nixpkgs.xorg.libXfixes                     \
      nixpkgs.xorg.libXrender                    \
      nixpkgs.xorg.libXinerama                   \
      nixpkgs.fontconfig                         \
      nixpkgs.xorg.xorgserver                    \
      nixpkgs.xorg.xauth                         \
      nixpkgs.uhd                                \
                                                   \
      # OpenGL/GLES/Vulkan                     \
      nixpkgs.libepoxy                           \
      nixpkgs.vulkan-loader                      \
      nixpkgs.shaderc                            \
      nixpkgs.mesa                               \
      nixpkgs.glew                               \
      nixpkgs.glfw                               \
      nixpkgs.openxr-loader                      \
                                                   \
      # Image I/O                              \
      nixpkgs.libjpeg                            \
      nixpkgs.libpng                             \
      nixpkgs.libtiff                            \
      nixpkgs.openexr                            \
      nixpkgs.opencolorio                        \
      nixpkgs.freetype                           \
      nixpkgs.potrace                            \
      nixpkgs.libwebp                            \
      nixpkgs.openusd                            \
                                                \
      # Audio/Multimedia                        \
      nixpkgs.ffmpeg                             \
      nixpkgs.openal                             \
      nixpkgs.SDL2                               \
      nixpkgs.libsndfile                         \
      nixpkgs.jack2                              \
      nixpkgs.ocamlPackages.gstreamer            \
      nixpkgs.pipewire                           \
      nixpkgs.pulseaudio                         \
      nixpkgs.avahi                              \
      nixpkgs.libcanberra                        \
      nixpkgs.webrtc-audio-processing            \
                                                   \
      # VFX & Rendering                        \
      nixpkgs.openvdb                            \
      nixpkgs.opensubdiv                         \
      nixpkgs.osl                                \
      nixpkgs.openimageio                        \
      nixpkgs.embree                             \
      nixpkgs.openimagedenoise                   \
      nixpkgs.materialx                          \
      nixpkgs.libspnav                          \
                                                   \
      # Utilities                              \
      nixpkgs.zstd                          \
      nixpkgs.ispc                               \      
      nixpkgs.brotli                             \
      nixpkgs.jemalloc                           \
                                                   \
 && nix-store --gc --print-live

# Set PATH and default shell
ENV PATH=/root/.nix-profile/bin:/nix/var/nix/profiles/default/bin:${PATH}


#ENV PYTHONPATH="/usr/local/lib/python3.11/site-packages:${PYTHONPATH}"

# Install remaining Python packages via pip with cache mount
# Only packages not available in Fedora repositories are installed here.
      # Python Environment and Packages (managed by Nix)
# RUN nix-env -iA \
#       nixpkgs.python311Packages.pip \
#       nixpkgs.python311Packages.numpy \
#       nixpkgs.python311Packages.charset-normalizer \
#       nixpkgs.python311Packages.urllib3 \
#       nixpkgs.python311Packages.zstandard \
#       nixpkgs.python311Packages.requests \
#       nixpkgs.python311Packages.idna \
#       nixpkgs.python311Packages.certifi \
#       nixpkgs.python311Packages.alembic \
#       nixpkgs.python311Packages.mako \
#       nixpkgs.python311Packages.jinja2 \
#       nixpkgs.python311Packages.pybind11 \
#       && nix-store --gc --print-live

RUN nix-env -iA  busybox && nix-store --gc --print-live

RUN addgroup -g 1001 appgroup && \
    adduser -u 1001 -G appgroup -s /bin/sh -D appuser
USER appuser


SHELL ["/bin/sh", "-c"]

# Default entrypoint: interactive shell
ENTRYPOINT ["sh"]


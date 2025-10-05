# This file declaratively defines all packages for the build environment.
{ pkgs? import <nixpkgs> {} }:

pkgs.buildEnv {
  name = "blender-build-env";
  paths = with pkgs;))

    # System Libraries
    glibc
    gcc
    libgcc
    libsigcxx
    gccNGPackages_15.libstdcxx
    libcxx
    fftw
    opencollada
    imath
    libusb1
    hydra
    boost
    pugixml
    llvm
    robin-map
    sse2neon
    yaml-cpp

    # Compression & Crypto
    zlib
    zstd
    openssl
    brotli
    libdeflate

    # Memory & Testing
    jemalloc
    valgrind
    pystring

    # Wayland / X11 / Display
    wayland
    wayland-protocols
    xorg.libX11
    xorg.libXi
    xorg.libXcursor
    libxkbcommon
    xorg.libXxf86vm
    xorg.libXfixes
    xorg.libXrender
    xorg.libXinerama
    fontconfig
    xorg.xorgserver
    xorg.xauth
    uhd

    # OpenGL/GLES/Vulkan
    libepoxy
    vulkan-loader
    shaderc
    mesa
    glew
    glfw
    openxr-loader
    libspnav

    # Image I/O
    libjpeg
    libpng
    libtiff
    openexr
    opencolorio
    freetype
    potrace
    libwebp
    openusd

    # Audio/Multimedia
    ffmpeg
    openal
    SDL2
    libsndfile
    jack2
    ocamlPackages.gstreamer
    pipewire
    pulseaudio
    avahi
    libcanberra
    webrtc-audio-processing

    # VFX & Rendering
    openvdb
    opensubdiv
    osl
    openimageio
    embree
    openimagedenoise
    materialx

    # Utilities
    ispc
  ];
}
  #... (other packages)

# Python Environment and Packages (managed by Nix)
(python311.withPackages (ps: with ps; [
  pip
  numpy
  charset-normalizer
  urllib3
  zstandard
  requests
  idna
  certifi
  alembic
  mako
  jinja2
  pybind11
]))



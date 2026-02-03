# --------------------------------------------------
# Base prebuilder (shared)
# --------------------------------------------------
FROM newton2022/blender-builder:24-prebuilder AS prebuilder

ENV DEBIAN_FRONTEND=noninteractive
WORKDIR /tmp
RUN apt-get update && apt-get install -y cmake ninja-build git libtbb-dev
# --------------------------------------------------
# MaterialX 1.39.4
# --------------------------------------------------
FROM prebuilder AS build_materialx

ARG MaterialX_VERSION=v1.39.4

RUN git clone -b ${MaterialX_VERSION} --single-branch --depth=1 \
    https://github.com/AcademySoftwareFoundation/MaterialX.git materialx && \
    cmake -S materialx -B materialx/build -GNinja \
      -DCMAKE_BUILD_TYPE=Release \
      -DCMAKE_INSTALL_PREFIX=/usr/local \
      -DMATERIALX_BUILD_PYTHON=ON \
      -DMATERIALX_BUILD_TESTS=OFF \
      -DMATERIALX_BUILD_VIEWER=OFF \
      -DMATERIALX_BUILD_GRAPH_EDITOR=OFF \
      -DCMAKE_CXX_FLAGS="-Wno-error=stringop-overflow" && \
    cmake --build materialx/build && \
    cmake --install materialx/build

    RUN echo "Cloning MaterialX" && \
    git clone  --depth=1 https://github.com/AcademySoftwareFoundation/MaterialX.git materialx && \
    mkdir materialx/build && cd materialx/build && \
    cmake .. -GNinja -DCMAKE_BUILD_TYPE=Release -DCMAKE_INSTALL_PREFIX=/usr/local \
             -DMATERIALX_BUILD_PYTHON=ON -DMATERIALX_BUILD_TESTS=OFF \
             -DMATERIALX_BUILD_VIEWER=OFF -DMATERIALX_BUILD_GRAPH_EDITOR=OFF \
             -DCMAKE_CXX_FLAGS="-Wno-error=stringop-overflow" && \
    cmake --build . && cmake --install . 
# --------------------------------------------------
# OpenPGL 0.7.1 (ARM64 NEON)
# --------------------------------------------------
FROM prebuilder AS build_openpgl

ARG OPENPGL_VERSION=v0.7.1
RUN git clone -b ${OPENPGL_VERSION} --single-branch --depth=1 \
    https://github.com/RenderKit/openpgl openpgl && \
    cmake -S openpgl -B openpgl/build -GNinja \
      -DCMAKE_BUILD_TYPE=Release \
      -DCMAKE_INSTALL_PREFIX=/usr/local \
      -DOPENPGL_ISA_NEON=ON \
      -DOPENPGL_BUILD_TOOLS=OFF \
      -DOPENPGL_EF_IMAGE_SPACE_GUIDING_BUFFER=OFF \
      -DTBB_DIR=/usr/lib/aarch64-linux-gnu/cmake/TBB && \
      cmake --build openpgl/build && \
      cmake --install openpgl/build

#     -DOPENPGL_TBB_ROOT=/usr/local && \
# --------------------------------------------------
# Manifold 3.2.1
# --------------------------------------------------
FROM prebuilder AS build_manifold
Arg MANIFOLD_VERSION=v3.3.2
RUN git clone -b ${MANIFOLD_VERSION} --single-branch --depth=1 \
    https://github.com/elalish/manifold manifold && \
    cmake -S manifold -B manifold/build -GNinja \
      -DCMAKE_BUILD_TYPE=Release \
      -DCMAKE_INSTALL_PREFIX=/usr/local \
      -DBUILD_SHARED_LIBS=ON \
      -DBUILD_TESTING=OFF \
      -DMANIFOLD_DEBUG=OFF \
      -DMANIFOLD_STRICT=ON \
      -DMANIFOLD_PAR=ON \
      -DMANIFOLD_CBIND=ON \
      -DMANIFOLD_PYBIND=ON \
      -DMANIFOLD_DOWNLOADS=ON \
      -DMANIFOLD_CROSS_SECTION=ON \
      -DMANIFOLD_USE_BUILTIN_TBB=OFF \
      -DMANIFOLD_USE_BUILTIN_NANOBIND=OFF \
      -DMANIFOLD_USE_BUILTIN_CLIPPER2=ON \
      -DClipper2_DIR=/usr/lib/aarch64-linux-gnu/cmake/Clipper2 \
      -DCMAKE_CXX_FLAGS="-Wno-error=stringop-overflow" && \
    cmake --build manifold/build && \
    cmake --install manifold/build

# --------------------------------------------------
# Alembic 1.8.10
# --------------------------------------------------
FROM prebuilder AS build_alembic
ARG ALEMBIC_VERSION=1.8.10
RUN git clone -b ${ALEMBIC_VERSION} --single-branch --depth=1 \
    https://github.com/alembic/alembic alembic && \
    cmake -S alembic -B alembic/build -GNinja \
      -DCMAKE_BUILD_TYPE=Release \
      -DCMAKE_INSTALL_PREFIX=/usr/local \
      -DUSE_TESTS=OFF \
      -DALEMBIC_DEBUG_WARNINGS_AS_ERRORS=OFF \
      -DCMAKE_CXX_FLAGS="-O2 -fno-lto" && \
    cmake --build alembic/build && \
    cmake --install alembic/build 


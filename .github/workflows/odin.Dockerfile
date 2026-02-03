FROM newton2022/blender-builder:24-prebuilder AS odin-builder

RUN apt-get update && apt-get install -y \
    build-essential \
    cmake \
    ninja-build \
    git \
    wget \
    libtbb-dev \
    && rm -rf /var/lib/apt/lists/*

# ISPC
RUN echo "Add ISPC" && mkdir -p /opt/ispc && \
    wget -q https://github.com/ispc/ispc/releases/download/v1.29.1/ispc-v1.29.1-linux.aarch64.tar.gz \
        -O ispc.tar.gz && \
    tar -xzf ispc.tar.gz -C /opt/ispc --strip-components=1 && \
    rm ispc.tar.gz

ARG ODIN_VERSION=2.4.1
# Build OIDN
RUN wget -q https://github.com/RenderKit/oidn/releases/download/v${ODIN_VERSION}/oidn-${ODIN_VERSION}.src.tar.gz \
    -O oidn.tar.gz && \
    mkdir oidn && \
    tar -xzf oidn.tar.gz -C oidn --strip-components=1 && \
    rm oidn.tar.gz && \
    cd oidn && mkdir build && cd build && \
    cmake .. -GNinja \
      -DCMAKE_BUILD_TYPE=Release \
      -DOIDN_APPS=OFF \
      -DOIDN_DEVICE_HIP=OFF \
      -DOIDN_DEVICE_CUDA=OFF \
      -DOIDN_DEVICE_SYCL=OFF \
      -DOIDN_DEVICE_METAL=OFF \
      -DOIDN_INSTALL_DEPENDENCIES=ON \
      -DCMAKE_INSTALL_PREFIX=/usr/local \
      -DISPC_EXECUTABLE=/opt/ispc/bin/ispc && \
    cmake --build . && cmake --install . 

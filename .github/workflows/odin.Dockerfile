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

ARG OIDN_VERSION=2.4.1
# Build OIDN
RUN wget -q https://github.com/RenderKit/oidn/releases/download/v${OIDN_VERSION}/oidn-${OIDN_VERSION}.src.tar.gz \
    -O oidn.tar.gz && \
    mkdir oidn && \
    tar -xzf oidn.tar.gz -C oidn --strip-components=1 && \
    rm oidn.tar.gz && \
    cd oidn && \
    /opt/venv/bin/python scripts/build.py install \
    --config Release \
    --install_dir /usr/local \
    -D OIDN_APPS=OFF \
    -D OIDN_DEVICE_CPU=ON \
    -D OIDN_DEVICE_HIP=OFF \
    -D OIDN_DEVICE_CUDA=OFF \
    -D OIDN_DEVICE_SYCL=OFF \
    -D OIDN_DEVICE_METAL=OFF



# syntax=docker/dockerfile:1

# Blender Builder - ARM64 Optimized with Cache Mounts
# Use an official Fedora image as the base.
# The --platform flag ensures the correct architecture is pulled.
# MaterialX with cache mount

FROM newton2022/blender-builder:fedora AS builder

RUN dnf -y install python3.11 python3.11-devel binutils-gold  python3.11-libs python3.11-pip \
    openvdb-devel opensubdiv-devel openvdb-devel \
    --skip-broken --skip-unavailable 

# Configure Python 3.11 as the default 'python3'
RUN update-alternatives --install /usr/bin/python3 python3 /usr/bin/python3.11 100

# Select Python 3.11 for the 'python3' alternative (no priority here)
RUN update-alternatives --set python3 /usr/bin/python3.11

RUN python3.11 -m ensurepip --upgrade  && \
    python3.11 -m pip install --no-cache-dir numpy charset-normalizer urllib3 zstandard requests \
        idna certifi alembic cython mako jinja2 nanobind fastjsonschema  cattrs

WORKDIR /tmp

# 5. TBB
RUN echo "Building TBB" && git clone --branch v2022.2.0 https://github.com/uxlfoundation/oneTBB tbb && \
    cd tbb && mkdir build && cd build && \
    cmake -DCMAKE_BUILD_TYPE=Release -DCMAKE_INSTALL_PREFIX=/usr/local -GNinja \
          -DCMAKE_INTERPROCEDURAL_OPTIMIZATION=OFF  -DTBB_TEST=OFF -DTBB_FUZZ_TESTING=OFF \
          -DCMAKE_CXX_FLAGS="-Wno-error=stringop-overflow" .. && \
    cmake --build . && cmake --install . && rm -rf tbb

RUN echo "Add ISPC" && mkdir -p /opt/ispc && \
    wget -q https://github.com/ispc/ispc/releases/download/v1.28.2/ispc-v1.28.2-linux.aarch64.tar.gz \
        -O ispc.tar.gz && \
    tar -xzf ispc.tar.gz -C /opt/ispc --strip-components=1 && \
    rm ispc.tar.gz
# --- Python Ecosystem ---
# 9. Intel OIDN v2.3.3 (manual CMake build)

RUN echo "Build Image Denoiser Oidn" && \
    wget -q https://github.com/RenderKit/oidn/releases/download/v2.3.3/oidn-2.3.3.src.tar.gz \
        -O oidn.tar.gz && \
    mkdir oidn && tar -xzf oidn.tar.gz -C oidn --strip-components=1 && \
    rm oidn.tar.gz && cd oidn && mkdir build && cd build && \
    cmake .. -GNinja -DCMAKE_BUILD_TYPE=Release \
             -DOIDN_APPS=OFF -DOIDN_DEVICE_HIP=OFF -DOIDN_DEVICE_CUDA=OFF \
             -DOIDN_DEVICE_SYCL=OFF -DOIDN_DEVICE_METAL=OFF \
             -DTBB_DIR=/usr/local \
             -DPython_EXECUTABLE=/usr/sbin/python3.11 \
             -DOIDN_INSTALL_DEPENDENCIES=ON -DCMAKE_INSTALL_PREFIX=/usr/local \
             -DISPC_EXECUTABLE=/opt/ispc/bin/ispc && \
    cmake --build . && cmake --install . && rm -rf oidn

    
RUN echo "Building Manifold v3.2.1" && \
    git clone https://github.com/elalish/manifold -b v3.2.1 --single-branch /tmp/manifold && \
    mkdir -p /tmp/manifold/build && cd /tmp/manifold/build && \
    cmake .. \
      -G Ninja \
      -DCMAKE_BUILD_TYPE=Release \
      -DCMAKE_INSTALL_PREFIX=/usr/local \
      -DMANIFOLD_JSBIND=OFF\
      -DMANIFOLD_CBIND=OFF \
      -DMANIFOLD_PYBIND=OFF \
      -DMANIFOLD_PAR=ON \
      -DMANIFOLD_CROSS_SECTION=OFF \
      -DMANIFOLD_EXPORT=OFF \
      -DMANIFOLD_DEBUG=OFF \
      -DMANIFOLD_TEST=OFF \
      -DMANIFOLD_DOWNLOADS=OFF \
      -DTBB_DIR=/usr/local \ 
      -DTRACY_ENABLE=OFF \
      -DBUILD_SHARED_LIBS=OFF \
      -DBUILD_TESTING=OFF \     
      -DPython_EXECUTABLE=/usr/sbin/python3.11 \
      -DCMAKE_CXX_FLAGS="-Wno-error=stringop-overflow" && \
      cmake --build . && cmake --install . && rm -rf /tmp/manifold

RUN echo "Cloning MaterialX" && \
    git clone https://github.com/AcademySoftwareFoundation/MaterialX.git -b v1.39.4 --depth=1 /tmp/materialx && \
    mkdir -p /tmp/materialx/build && cd /tmp/materialx/build && \
    cmake .. -DCMAKE_BUILD_TYPE=Release \
          -DCMAKE_INSTALL_PREFIX=/usr/local \
          -DMATERIALX_BUILD_GRAPH_EDITOR=OFF \
          -DMATERIALX_BUILD_PYTHON=ON \
          -DMATERIALX_BUILD_TESTS=OFF \
          -DMATERIALX_BUILD_VIEWER=OFF \
          -DMATERIALX_BUILD_RENDER=ON \
          -DMATERIALX_INSTALL_PYTHON=OFF \
          -DMATERIALX_BUILD_SHARED_LIBS=ON \
          -DPython_EXECUTABLE=/usr/sbin/python3.11 \
          -DMATERIALX_INSTALL_PYTHON=/usr/sbin/python3.11 \
          -DCMAKE_CXX_FLAGS="-Wno-error=stringop-overflow" \
    && cmake --build . && \
    cmake --install . && \
    echo "Done Installing MaterialX"

RUN rm -rf /tmp/*


# Fix for SSL certificate issues by pointing standard ENV VARS to certifi's bundle.
# This resolves the CMake warning about not finding "certifi/cacert.pem".
RUN CERTIFI_PATH=$(python3.11 -c "import certifi; print(certifi.where())") && \
    echo "export REQUESTS_CA_BUNDLE=${CERTIFI_PATH}" >> /etc/profile.d/certifi.sh && \
    echo "export SSL_CERT_FILE=${CERTIFI_PATH}" >> /etc/profile.d/certifi.sh

# In case depot_tools expects pip-installed deps, ensure it’s covered:
#RUN pip install --no-cache-dir httplib2 httplib2[socks] PySocks six pyasn1 pyasn1-modules urllib3
# Create a non-root user for the build process for security
# and grant passwordless sudo privileges.
#RUN useradd --create-home --shell /bin/bash builder && \
#    adduser builder sudo && \
#    echo 'builder ALL=(ALL) NOPASSWD:ALL' >> /etc/sudoers


# Switch to the non-root user
#USER builder
WORKDIR /blender-git

# Copy the compile script into the container and make it executable
COPY --chown=builder:builder compile.sh /compile.sh
RUN chmod +x /compile.sh

# Set the entrypoint to our compile script
ENTRYPOINT ["/compile.sh"]

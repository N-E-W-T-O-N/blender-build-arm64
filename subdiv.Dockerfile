FROM newton2022/blender-builder:24-prebuilder

WORKDIR /tmp
# ISPC
RUN echo "Building OpenSubdiv" && \
    git clone --depth=1 https://github.com/PixarAnimationStudios/OpenSubdiv OpenSubdiv && \
    mkdir OpenSubdiv/build && cd OpenSubdiv/build && \
    cmake .. -GNinja -DCMAKE_BUILD_TYPE=Release -DCMAKE_INSTALL_PREFIX=/usr/local \
             -DTBB_ROOT=/usr/local \
             -DNO_TBB=0 -DNO_OPENCL=0 -DNO_OPENGL=0 \
             -DNO_OMP=1 -DNO_CUDA=1 \             
             -DNO_DOC=1 -DNO_EXAMPLES=1 -DNO_REGRESSION=1 -DNO_PTEX=1 \
             -DOSD_PATCH_SHADER_SOURCE_MSL=0 -DOSD_PATCH_SHADER_SOURCE_GLSL=1 -DOSD_PATCH_SHADER_SOURCE_HLSL=1 \
             && \
    cmake --build . && cmake --install . 



IMAGE_NAME := blender-builder

build: build-image
	run

run:
	docker run --rm -it --platform="linux/arm64" \
	-v ${PWD}/blender-git:/blender-git \
	-v ${PWD}/compile.sh:/compile.sh \
	${IMAGE_NAME} /bin/bash

build-compose:
	docker compose build
	docker compose up

build-image:
    docker buildx build --platform linux/arm64 --progress=plain --load -t ${IMAGE_NAME} -t ${IMAGE_NAME}:arm64   .

correct:
	docker run --rm --privileged tonistiigi/binfmt --install all 
	docker run --rm --privileged multiarch/qemu-user-static --reset -p yes -c yes

docker run --rm -it --platform="linux/arm64" -v ${PWD}/blender-git/blender:/blender-git/blender -v ${PWD}/blender-git/build_linux:/blender-git/build_linux docker  -v ${PWD}/compile.sh:/compile.sh blender-builder 

Blender docker run --rm --entrypoint find --platform linux/arm64  blender-builder:latest /blender-git

 docker run --rm -it --platform="linux/arm64" \
   -v ${PWD}/blender-git/blender:/blender-git/blender:rw \
   -v ${PWD}/blender-git/build_linux:/blender-git/build_linux:rw \
   -v ${PWD}/compile.sh:/compile.sh:ro  \
   -v ${PWD}/blender-git/pipewire:/blender-git/pipewire:rw blender-builder

docker buildx build --platform linux/arm64 --progress=plain --load -t blender-builder  -t newton2022/blender-builder -t newton2022/blender-builder:arm64 .

docker buildx create \                           
  --name mybuilder \
  --driver containerd \
  --use

find . -name "platform_unix.cmake"

grep -rnw /home/user/project -e "DatabaseConnection"


 docker run --rm -it --platform="linux/arm64" \
   -v ${PWD}/blender-git/blender:/blender-git/blender:rw \
   -v ${PWD}/blender-git/build_linux:/blender-git/build_linux:rw \
   -v ${PWD}/compile.sh:/compile.sh:ro  \
 newton2022/blender-builder:dev
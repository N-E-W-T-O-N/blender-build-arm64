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


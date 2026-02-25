IMAGE_NAME := newton2022/blender-builder
USER := usr
PASSWORD := pass
build: build-image run

run:
	docker run --rm -it --platform="linux/arm64" --pull always --cpuset-cpus="0-3" \
	-v ${PWD}/blender-git:/blender-git \
	-v ${PWD}/compile.sh:/compile.sh \
	${IMAGE_NAME}:final  

build-compose:
	docker compose build
	docker compose up

build-image:
    docker buildx build --platform linux/arm64 --progress=plain --load -t ${IMAGE_NAME} -t ${IMAGE_NAME}:arm64   .

enter:
	docker run --rm -it --platform="linux/arm64" --pull always --entrypoint bash -w /  ${IMAGE_NAME}:final

display:
	docker run --rm -it \
		--platform linux/arm64 \
		--entrypoint bash \
		-w /blender-git/build_linux/bin \
		-v ${PWD}/blender-git:/blender-git \
		-e DISPLAY=:0 \
		-e WAYLAND_DISPLAY=wayland-0 \
		-e XDG_RUNTIME_DIR=/mnt/wslg/runtime-dir \
		-e PULSE_SERVER=unix:/mnt/wslg/PulseServer \
		-e LD_LIBRARY_PATH=/usr/local/lib \
		-v /mnt/wslg:/mnt/wslg \
		-v /tmp/.X11-unix:/tmp/.X11-unix \
		--device /dev/dxg \
		${IMAGE_NAME}:final
rdp:
	docker run -it --rm --name rdp -p 33890:3389 -e SSHD_ENABLE=true -p 2222:22  --platform="linux/arm64" -v ${PWD}/blender-git/:/blender-git -e USER=${USER} -e PASSWORD=${PASSWORD} heywoodlh/rdp-ubuntu  ; echo " ${USER} ${PASSWORD}  yes "

correct:
	docker run --rm --privileged tonistiigi/binfmt --install all 
	docker run --rm --privileged multiarch/qemu-user-static --reset -p yes -c yes

# docker run --rm -it --platform="linux/arm64" -v ${PWD}/blender-git/blender:/blender-git/blender -v ${PWD}/blender-git/build_linux:/blender-git/build_linux docker  -v ${PWD}/compile.sh:/compile.sh blender-builder 

# Blender docker run --rm --entrypoint find --platform linux/arm64  blender-builder:latest /blender-git

#  docker run --rm -it --platform="linux/arm64" \
#    -v ${PWD}/blender-git/blender:/blender-git/blender:rw \
#    -v ${PWD}/blender-git/build_linux:/blender-git/build_linux:rw \
#    -v ${PWD}/compile.sh:/compile.sh:ro  \
#    -v ${PWD}/blender-git/pipewire:/blender-git/pipewire:rw blender-builder

# docker buildx build --platform linux/arm64 --progress=plain --load -t blender-builder  -t newton2022/blender-builder -t newton2022/blender-builder:arm64 .

# docker buildx create \                           
#   --name mybuilder \
#   --driver containerd \
#   --use

# find . -name "platform_unix.cmake"

# grep -rnw /home/user/project -e "DatabaseConnection"


#  docker run --rm -it --platform="linux/arm64" \
#    -v ${PWD}/blender-git/blender:/blender-git/blender:rw \
#    -v ${PWD}/blender-git/build_linux:/blender-git/build_linux:rw \
#    -v ${PWD}/compile.sh:/compile.sh:ro  \
#  newton2022/blender-builder:dev
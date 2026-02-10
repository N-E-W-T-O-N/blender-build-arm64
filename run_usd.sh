#!/bin/bash
# --entrypoint bash
#--entrypoint /install.sh
docker run -it -v $(pwd)/install_usd.sh:/install.sh:rw -v $(pwd)/OpenUSD:/OpenUSD --workdir / --entrypoint bash --platform linux/arm64  newton2022/blender-builder:merge

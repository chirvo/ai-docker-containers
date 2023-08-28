#!/bin/bash

build_image_pytorch2() {
  docker build --tag pytorch2-rocm5-jammy:latest -f ./dockerfiles/pytorch2-rocm5-jammy.dockerfile .
}

build_image_ai_base() {
  docker build --tag ai-docker-containers-base:latest -f ./dockerfiles/ai-docker-containers-base.dockerfile .
}

_image_rm () {
#$1 IMAGE
  echo -n "Removing images: '$1': "
  docker image rm $1:latest
  [ $? -eq 0 ] && echo "done." || "error." 
}

clean () {
  echo "Pruning containers..."
  docker container prune
  echo -n "Removing images: 'pytorch2-rocm5-jammy': "
  _image_rm pytorch2-rocm5-jammy
  _image_rm ai-docker-containers-base
}

case "$1" in
clean) echo "Removing image"
  clean
  exit 1
  ;;
base) echo "Building ai-docker-containers-base"
  build_image_ai_base
  ;;
pytorch2) echo "Building pytorch2-rocm5-jammy"
  build_image_pytorch2
  ;;
all) echo "Building all"
  build_image_pytorch2
  ;;
*)	echo "Usage: $0 {help|clean|all|pytorch2|base}"
  exit 1
  ;;
esac
exit 0

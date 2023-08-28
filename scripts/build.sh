#!/bin/bash

build_image_pytorch2() {
  docker build --tag pytorch2_rocm5_jammy:latest -f ./dockerfiles/pytorch2_rocm5_jammy.dockerfile .
}

build_image_ai_base() {
  docker build --tag ai_docker_containers_base:latest -f ./dockerfiles/ai_docker_containers_base.dockerfile .
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
  echo -n "Removing images: 'pytorch2_rocm5_jammy': "
  _image_rm pytorch2_rocm5_jammy
  _image_rm ai_docker_containers_base
}

case "$1" in
clean) echo "Removing image"
  clean
  exit 1
  ;;
base) echo "Building ai_docker_containers_base"
  build_image_ai_base
  ;;
pytorch2) echo "Building pytorch2_rocm5_jammy"
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

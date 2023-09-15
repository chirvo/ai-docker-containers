#!/bin/bash

_build () {
  # $1: dockerfile's name
  if [ ! -f ./dockerfiles/$1.dockerfile ]; then
    echo "Error: './dockerfiles/$1.dockerfile' does not exists. Cannot build."
    exit 1
  fi
  docker build --tag chirvo/$1:latest -f ./dockerfiles/$1.dockerfile .
}
_image_rm () {
#$1 IMAGE
  echo -n "Removing image '$1': "
  docker image rm chirvo/$1:latest
  [ $? -eq 0 ] && echo "done." || "error." 
}

_clean () {
  echo "Pruning containers..."
  docker container prune
  _image_rm ai-docker-containers-base
  _image_rm ai-docker-containers-a1111
  _image_rm ai-docker-containers-comfy
}

case "$1" in
clean) 
  _clean
  ;;
base) echo "Building $1"
  _build ai-docker-containers-base
  ;;
a1111) echo "Building $1"
  _build ai-docker-containers-a1111
  ;;
comfy) echo "Building $1"
  _build ai-docker-containers-comfy
  ;;
all) echo "Building $1"
  _build ai-docker-containers-base
  _build ai-docker-containers-a1111
  _build ai-docker-containers-comfy
  ;;
*)	echo "Usage: $0 {help|clean|all|base|a1111|comfy}"
  exit 1
  ;;
esac
exit 0

#!/bin/bash

IMAGES=$(basename -s .dockerfile -a "$(ls ./dockerfiles/*.dockerfile)" | sed -e 's/ai-//')

_build () {
  # $1: dockerfile's name
  if [ ! -f "./dockerfiles/$1.dockerfile" ]; then
    echo "Error: './dockerfiles/$1.dockerfile' does not exists. Cannot build."
    exit 1
  fi
  docker build --tag "chirvo/$1:latest" -f "./dockerfiles/$1.dockerfile" .
}
_image_rm () {
#$1 Image
  echo -n "Removing image '$1': "
  docker image rm "chirvo/$1:latest"
  [ $? -eq 0 ] && echo "done." || echo "error." 
}

case "$1" in
clean) 
  echo "Pruning containers..."
  docker container prune
  for IMAGE in $IMAGES
  do
    _image_rm "ai-$IMAGE"
  done
  ;;
all) echo "Building $1"
  for IMAGE in $IMAGES
  do
    _build "ai-$IMAGE"
  done
  ;;
*)
if [ true ]; then
  echo "It is true"
else
	echo "Usage: $0 {help|clean|all}"
  exit 1
  fi
  ;;
esac
exit 0

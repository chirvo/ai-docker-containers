#!/bin/bash

# Define variables holding names of Dockerfiles for base and service images
BASE_IMAGES=$(echo $(basename -s .dockerfile -a $(ls ./dockerfiles/base/*.dockerfile)))
SERVICE_IMAGES=$(echo $(basename -s .dockerfile -a $(ls ./dockerfiles/services/*.dockerfile)))

# Function to build a specific Docker image based on the provided name (first argument) and additional parameters (second argument)
_build() {
  # Check if the specified Dockerfile exists
  if [ ! -f "./dockerfiles/$1.dockerfile" ]; then
    echo "Error: './dockerfiles/$1.dockerfile' does not exist. Cannot build."
    exit 1
  fi

  # Set tag for the image using provided name and additional parameters
  TAG="chirvo/$(echo "$1" | sed -e 's/[a-zA-Z].*\/[0-9][0-9]-//'):latest"

  # Print building status
  echo -n "Building image for '$1' with tag '$TAG': "

  # Execute docker build command to build the image
  docker build $2 --force-rm --tag "$TAG" -f "./dockerfiles/$1.dockerfile" .

  # Check if docker build was successful
  [ $? -eq 0 ] && echo "done." || echo "error."
}

# Function to remove a specific Docker image based on the provided name (first argument) and additional parameters (second argument)
_image_rm() {
  # Set tag for the image using provided name and additional parameters
  TAG="chirvo/$(echo "$1" | sed -e 's/[a-zA-Z].*\/[0-9][0-9]-//'):latest"

  # Print removal status
  echo -n "Removing image for '$1' with tag '$TAG': "

  # Execute docker rmi command to remove the image
  docker image rm "$TAG"

  # Check if docker rmi was successful
  [ $? -eq 0 ] && echo "done." || echo "error."
}

# Main script execution based on provided input
case "$1" in
clean)
  # Remove all Docker containers and images matching the patterns specified in $BASE_IMAGES and $SERVICE_IMAGES
  docker container prune
  for IMAGE in $BASE_IMAGES; do
    _image_rm "base/$IMAGE"
  done
  for IMAGE in $SERVICE_IMAGES; do
    _image_rm "services/$IMAGE"
  done
  ;;
base)
  # Build all base images listed in $BASE_IMAGES
  for IMAGE in $BASE_IMAGES; do
    _build "base/$IMAGE" $2
  done
  ;;
all)
  # Build both the base and service images listed in $BASE_IMAGES and $SERVICE_IMAGES
  for IMAGE in $BASE_IMAGES; do
    _build "base/$IMAGE" $2
  done
  for IMAGE in $SERVICE_IMAGES; do
    _build "services/$IMAGE" $2
  done
  ;;
*)
  # Build a specific image based on the provided name (either base or service)
  if [ "$1" != "" ]; then
    for IMAGE in $BASE_IMAGES; do
      if [ "$1" == "$IMAGE" ]; then
        echo "Found '$1'."
        _build "base/$1" $2
        exit 0
      fi
    done
    for IMAGE in $SERVICE_IMAGES; do
      if [ "$1" == "$IMAGE" ]; then
        echo "Found 'services/$1'."
        _build "services/$1" $2
        exit 0
      fi
    done
  fi

  # Display usage instructions and list of available images
  echo "Usage: $0 {clean|base|all|<image>}"
  echo ""
  echo "Available Base images: $BASE_IMAGES".
  echo "Available Service images: $SERVICE_IMAGES".
  echo ""
  exit 1
  ;;
esac
exit 0

#!/bin/bash

# Define arrays holding names of Dockerfiles for base and service images
mapfile -t BASE_IMAGES < <(basename -s .dockerfile -a ./dockerfiles/*.dockerfile)
mapfile -t SERVICE_IMAGES < <(basename -s .dockerfile -a ./dockerfiles/*.dockerfile)

# Function to generate Docker image tag
_generate_tag() {
  echo "chirvo/$(echo "$1" | sed -e 's/[a-zA-Z].*\/[0-9][0-9]-//'):$(date -u +%y%m%d_%H%M%S)"
}

# Function to build a specific Docker image based on the provided name (first argument) and additional parameters (second argument)
_build() {
  local image_name="$1"
  local build_args="$2"
  local dockerfile="./dockerfiles/$image_name.dockerfile"
  local tag
  local latest_tag
  # shellcheck disable=SC2016
  tag=$(_generate_tag "$image_name")
  latest_tag=${tag//:*/:latest}

  # Check if the specified Dockerfile exists
  if [ ! -f "$dockerfile" ]; then
    echo "Error: '$dockerfile' does not exist. Cannot build."
    exit 1
  fi

  # Print building status
  echo "Building image for '$image_name' with tag '$tag'..."

  # Execute docker build command to build the image
  # shellcheck disable=SC2086
  if docker build $build_args --force-rm --tag "$latest_tag" --tag "$tag" -f "$dockerfile" .; then
    echo "done."
  else
    echo "error."
  fi
}

# Function to remove a specific Docker image based on the provided name (first argument)
_image_rm() {
  local image_name="$1"
  local tag
  tag=$(_generate_tag "$image_name")

  # Print removal status
  echo -n "Removing image for '$image_name' with tag '$tag': "

  # Execute docker rmi command to remove the image
  if docker image rm "$tag"; then
    echo "done."
  else
    echo "error."
  fi
}

# Function to build all images in a given array
_build_all() {
  local images=("$@")
  for image in "${images[@]}"; do
    _build "$image" "$2"
  done
}

# Function to remove all images in a given array
_remove_all() {
  local images=("$@")
  for image in "${images[@]}"; do
    _image_rm "$image"
  done
}

# Main script execution based on provided input
case "$1" in
clean)
  # Remove all Docker containers and images matching the patterns specified in $BASE_IMAGES and $SERVICE_IMAGES
  docker container prune -f
  _remove_all "${BASE_IMAGES[@]/#/base/}"
  ;;
all)
  # Build all base images listed in $BASE_IMAGES
  _build_all "${BASE_IMAGES[@]/#/base/}" "$2"
  ;;
*)
  # Build a specific image based on the provided name (either base or service)
  if [ -n "$1" ]; then
    # shellcheck disable=SC2199
    # shellcheck disable=SC2076
    echo "Found '$1'."
    _build "$1" "$2"
    exit 0
  fi

  # Display usage instructions and list of available images
  echo "Usage: $0 {clean|all|<image>}"
  echo ""
  echo "Available images: ${BASE_IMAGES[*]}"
  echo ""
  exit 1
  ;;
esac
exit 0

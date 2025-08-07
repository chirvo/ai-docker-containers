#!/usr/bin/env python3
import os
import sys
from datetime import datetime, UTC
from pathlib import Path
import docker  # Import docker-py library
import logging  # Import logging module
import argparse  # Import argparse for CLI argument parsing

# Configure logging
logging.basicConfig(
    level=logging.INFO,
    format="%(asctime)s - %(levelname)s - %(message)s",
    handlers=[logging.StreamHandler(sys.stdout)],
)

# Define the directory for Dockerfiles, assuming a flat structure like in build.sh
DOCKERFILE_DIR = Path("./dockerfiles")

# Define known base images to maintain build order for the 'all' command,
# based on README.md and observed files.
KNOWN_BASE_IMAGES = {"ubuntu_rocm", "uv_pytorch"}

# Discover all images from the flat directory structure and categorize them
ALL_IMAGES = sorted([f.stem for f in DOCKERFILE_DIR.glob("*.dockerfile")])
BASE_IMAGES = [img for img in ALL_IMAGES if img in KNOWN_BASE_IMAGES]
SERVICE_IMAGES = [img for img in ALL_IMAGES if img not in KNOWN_BASE_IMAGES]

# Initialize Docker client
client = docker.from_env()

def generate_tag(image_name, registry_user):
    """Generate Docker image tag."""
    # Create a unique tag using the current UTC timestamp
    timestamp = datetime.now(UTC).strftime("%y%m%d_%H%M%S")
    return f"{registry_user}/{image_name}:{timestamp}"

def build_image(image_name, build_args="", dry_run=False, push=False, registry_user="chirvo"):
    """Build a specific Docker image."""
    # Construct the path to the Dockerfile relative to the project root
    dockerfile_path = f"dockerfiles/{image_name}.dockerfile"
    dockerfile = Path(dockerfile_path)
    if not dockerfile.is_file():
        # Exit if the Dockerfile does not exist
        logging.error(f"Error: '{dockerfile_path}' does not exist. Cannot build.")
        sys.exit(1)

    # Generate tags for the image
    tag = generate_tag(image_name, registry_user)
    latest_tag = f"{tag.split(':')[0]}:latest"  # Create a 'latest' tag

    if dry_run:
        logging.info(
            f"[Dry Run] Would build image '{image_name}' with tags '{latest_tag}' and '{tag}'."
        )
        if push:
            push_image(tag, latest_tag, dry_run=True)
        return

    logging.info(f"Building image for '{image_name}'...")
    try:
        # Use docker-py to build the image with progress feedback.
        # The build context is the current directory ('.').
        build_output = client.api.build(
            path=".",
            dockerfile=dockerfile_path,
            tag=tag,
            buildargs=dict(arg.split("=") for arg in build_args.split() if "=" in arg),
            rm=True,
            forcerm=True,  # Match build.sh's --force-rm
            decode=True,
        )
        last_event = None
        for chunk in build_output:
            last_event = chunk
            if "stream" in chunk:
                # Log the build progress from the 'stream' field
                formatted_output = chunk["stream"].strip()
                if formatted_output:
                    logging.info(formatted_output)
            elif "status" in chunk:
                # Log status updates
                status = chunk["status"]
                progress = chunk.get("progress", "")
                logging.info(f"{status} {progress}")

        if last_event and "error" in last_event:
            logging.error(f"Build failed: {last_event['errorDetail']['message']}")
            sys.exit(1)

        # Apply tags to the built image
        image = client.images.get(tag)
        image.tag(latest_tag)
        logging.info(f"Image built and tagged as '{latest_tag}' and '{tag}'.")

        if push:
            push_image(tag, latest_tag, dry_run)

    except docker.errors.BuildError as e:
        logging.error(f"Build process error: {e}")
    except docker.errors.APIError as e:
        logging.error(f"API error: {e}")

def push_image(tag, latest_tag, dry_run=False):
    """Push a specific Docker image to the registry."""
    if dry_run:
        logging.info(f"[Dry Run] Would push tags '{tag}' and '{latest_tag}'.")
        return

    for t in [tag, latest_tag]:
        logging.info(f"Pushing tag '{t}'...")
        try:
            # Use the low-level API to get detailed stream output
            for line in client.api.push(t, stream=True, decode=True):
                if 'status' in line:
                    status = line['status']
                    # Only log status changes, not every progress update
                    if 'id' not in line and status != "Pushing":
                        logging.info(status)
                if 'error' in line:
                    error_message = line['errorDetail']['message']
                    logging.error(f"Push failed for tag {t}: {error_message}")
                    sys.exit(1)
            logging.info(f"Successfully pushed tag '{t}'.")
        except docker.errors.APIError as e:
            logging.error(f"API error during push for tag {t}: {e}")
            sys.exit(1)


def remove_image(image_name, dry_run=False, confirm=True, registry_user="chirvo"):
    """Remove all tags for a specific Docker image repository."""
    # Use the repository name for removal
    repo_name = f"{registry_user}/{image_name}"
    if confirm:
        user_input = input(f"Are you sure you want to delete all tags for the image '{repo_name}'? (y/N): ").strip().lower()
        if user_input != "y":
            logging.info(f"Aborted removal of image '{repo_name}'.")
            return

    if dry_run:
        logging.info(f"[Dry Run] Would remove all tags for image repository '{repo_name}'.")
        return

    try:
        images = client.images.list(name=repo_name)
        if not images:
            logging.warning(f"Image repository '{repo_name}' not found.")
            return
    except docker.errors.APIError as e:
        logging.error(f"API error while listing images: {e}")
        return

    all_tags = [tag for image in images for tag in image.tags if tag.startswith(repo_name)]

    if not all_tags:
        logging.warning(f"No tags found for image repository '{repo_name}'.")
        return

    logging.info(f"Removing all tags for image repository '{repo_name}'...")
    removed_count = 0
    for tag in all_tags:
        try:
            logging.info(f"Removing tag '{tag}'...")
            client.images.remove(tag)
            removed_count += 1
        except docker.errors.ImageNotFound:
            # This can happen if multiple tags point to the same image ID and one was already removed.
            logging.warning(
                f"Tag '{tag}' not found, it might have been removed already as part of another image ID."
            )
        except docker.errors.APIError as e:
            logging.error(f"API error while removing tag '{tag}': {e}")

    if removed_count > 0:
        logging.info(
            f"{removed_count} tag(s) for repository '{repo_name}' removed successfully."
        )
    else:
        logging.warning(f"No tags were removed for '{repo_name}'.")


def build_all(images, build_args="", dry_run=False, push=False, registry_user="chirvo"):
    """Build all images in the given list."""
    for image in images:
        # Build each image in the list
        build_image(image, build_args, dry_run, push, registry_user)

def remove_all(images, dry_run=False, confirm=True, registry_user="chirvo"):
    """Remove all images in the given list."""
    for image in images:
        # Remove each image in the list
        remove_image(image, dry_run, confirm=confirm, registry_user=registry_user)

def main():
    # Parse CLI arguments
    parser = argparse.ArgumentParser(description="Docker image build and management script.")
    parser.add_argument("command", choices=["clean", "base", "all"] + BASE_IMAGES + SERVICE_IMAGES,
                        help="Command to execute: clean, base, all, or a specific image.")
    parser.add_argument("--registry-user", default="chirvo", help="The Docker registry user/organization.")
    parser.add_argument("--build-args", default="", help="Build arguments to pass to Docker.")
    parser.add_argument("--dry-run", action="store_true", help="Simulate actions without making changes.")
    parser.add_argument("--force", action="store_true", help="Force action without confirmation (skips prompts).")
    parser.add_argument("--remove", action="store_true", help="Remove the specified image instead of building it.")
    parser.add_argument("--push", action="store_true", help="Push the built image(s) to the registry.")
    args = parser.parse_args()

    command = args.command
    registry_user = args.registry_user
    build_args = args.build_args
    dry_run = args.dry_run
    confirm = not args.force
    remove = args.remove
    push = args.push

    if push and remove:
        logging.error("Error: --push and --remove cannot be used together.")
        sys.exit(1)

    if push and command == "clean":
        logging.error("Error: --push cannot be used with the 'clean' command.")
        sys.exit(1)

    if command == "clean":
        # Clean up Docker containers
        logging.info("Pruning unused containers...")
        if dry_run:
            logging.info("[Dry Run] Would prune unused containers.")
        else:
            try:
                client.containers.prune()
                logging.info("Unused containers pruned successfully.")
            except docker.errors.APIError as e:
                logging.error(f"API error: {e}")

        # Remove all images
        remove_all(ALL_IMAGES, dry_run, confirm=confirm, registry_user=registry_user)
    elif command in BASE_IMAGES or command in SERVICE_IMAGES:
        logging.info(f"Processing '{command}'.")
        if remove:
            # Remove the specified image
            remove_image(command, dry_run, confirm, registry_user=registry_user)
        else:
            # Build the specified image
            build_image(command, build_args, dry_run, push, registry_user=registry_user)
    elif command == "base":
        # Build all base images
        build_all(BASE_IMAGES, build_args, dry_run, push, registry_user=registry_user)
    elif command == "all":
        # Build all base and service images
        build_all(BASE_IMAGES, build_args, dry_run, push, registry_user=registry_user)
        build_all(SERVICE_IMAGES, build_args, dry_run, push, registry_user=registry_user)
    else:
        # Handle invalid commands
        logging.error(f"Error: Command '{command}' not recognized.")
        sys.exit(1)

if __name__ == "__main__":
    # Entry point of the script
    main()

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

# Define directories for Dockerfiles
BASE_DIR = Path("./dockerfiles/base")  # Directory containing base Dockerfiles
SERVICE_DIR = Path("./dockerfiles/services")  # Directory containing service Dockerfiles

# Get list of base and service images
BASE_IMAGES = [f.stem for f in BASE_DIR.glob("*.dockerfile")]  # Extract base image names
SERVICE_IMAGES = [f.stem for f in SERVICE_DIR.glob("*.dockerfile")]  # Extract service image names

# Initialize Docker client
client = docker.from_env()

def generate_tag(image_name):
    """Generate Docker image tag."""
    # Create a unique tag using the current UTC timestamp
    timestamp = datetime.now(UTC).strftime("%y%m%d_%H%M%S")
    return f"chirvo/{image_name}:{timestamp}"

def build_image(image_name, build_args="", dry_run=False):
    """Build a specific Docker image."""
    # Construct the path to the Dockerfile
    dockerfile = Path(f"./dockerfiles/{image_name}.dockerfile")
    if not dockerfile.is_file():
        # Exit if the Dockerfile does not exist
        logging.error(f"Error: '{dockerfile}' does not exist. Cannot build.")
        sys.exit(1)

    # Generate tags for the image
    tag = generate_tag(image_name)
    latest_tag = f"{tag.split(':')[0]}:latest"  # Create a 'latest' tag

    if dry_run:
        logging.info(f"[Dry Run] Would build image '{image_name}' with tags '{latest_tag}' and '{tag}'.")
        return

    logging.info(f"Building image for '{image_name}'...")
    try:
        # Use docker-py to build the image with progress feedback
        with open(dockerfile, "rb") as df:
            build_output = client.api.build(
                fileobj=df,
                tag=tag,
                buildargs=dict(arg.split("=") for arg in build_args.split() if "=" in arg),
                rm=True,
                decode=True,
            )
            for chunk in build_output:
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
                elif "errorDetail" in chunk:
                    # Log detailed errors if present
                    logging.error(f"Build Error: {chunk['errorDetail']['message']}")

        # Apply tags to the built image
        image = client.images.get(tag)
        image.tag(latest_tag)
        logging.info(f"Image built and tagged as '{latest_tag}' and '{tag}'.")
    except docker.errors.BuildError as e:
        logging.error(f"Build error: {e}")
    except docker.errors.APIError as e:
        logging.error(f"API error: {e}")

def remove_image(image_name, dry_run=False, confirm=True):
    """Remove a specific Docker image."""
    # Use the repository name for removal
    repo_name = f"chirvo/{image_name}"
    if confirm:
        user_input = input(f"Are you sure you want to delete all tags for the image '{repo_name}'? (y/N): ").strip().lower()
        if user_input != "y":
            logging.info(f"Aborted removal of image '{repo_name}'.")
            return

    if dry_run:
        logging.info(f"[Dry Run] Would remove all tags for image '{repo_name}'.")
        return

    logging.info(f"Removing all tags for image '{repo_name}'...")
    try:
        # Get all tags associated with the image
        image = client.images.get(repo_name)
        for tag in image.tags:
            logging.info(f"Removing tag '{tag}'...")
            client.images.remove(tag)
        logging.info(f"All tags for image '{repo_name}' removed successfully.")
    except docker.errors.ImageNotFound:
        logging.warning(f"Image '{repo_name}' not found.")
    except docker.errors.APIError as e:
        logging.error(f"API error: {e}")

def build_all(images, build_args="", dry_run=False):
    """Build all images in the given list."""
    for image in images:
        # Build each image in the list
        build_image(image, build_args, dry_run)

def remove_all(images, dry_run=False):
    """Remove all images in the given list."""
    for image in images:
        # Remove each image in the list
        remove_image(image, dry_run)

def main():
    # Parse CLI arguments
    parser = argparse.ArgumentParser(description="Docker image build and management script.")
    parser.add_argument("command", choices=["clean", "base", "all"] + BASE_IMAGES + SERVICE_IMAGES,
                        help="Command to execute: clean, base, all, or a specific image.")
    parser.add_argument("--build-args", default="", help="Build arguments to pass to Docker.")
    parser.add_argument("--dry-run", action="store_true", help="Simulate actions without making changes.")
    parser.add_argument("--no-confirm", action="store_true", help="Skip confirmation prompts.")
    parser.add_argument("--remove", action="store_true", help="Remove the specified image instead of building it.")
    args = parser.parse_args()

    command = args.command
    build_args = args.build_args
    dry_run = args.dry_run
    confirm = not args.no_confirm
    remove = args.remove

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
        remove_all([f"base/{img}" for img in BASE_IMAGES], dry_run)
        remove_all([f"services/{img}" for img in SERVICE_IMAGES], dry_run)
    elif command in BASE_IMAGES or command in SERVICE_IMAGES:
        # Handle specific image
        image_type = "base" if command in BASE_IMAGES else "services"
        logging.info(f"Found '{image_type}/{command}'.")

        if remove:
            # Remove the specified image
            remove_image(f"{image_type}/{command}", dry_run, confirm)
        else:
            # Build the specified image
            build_image(f"{image_type}/{command}", build_args, dry_run)
    elif command == "base":
        # Build all base images
        build_all([f"base/{img}" for img in BASE_IMAGES], build_args, dry_run)
    elif command == "all":
        # Build all base and service images
        build_all([f"base/{img}" for img in BASE_IMAGES], build_args, dry_run)
        build_all([f"services/{img}" for img in SERVICE_IMAGES], build_args, dry_run)
    else:
        # Handle invalid commands
        logging.error(f"Error: Command '{command}' not recognized.")
        sys.exit(1)

if __name__ == "__main__":
    # Entry point of the script
    main()

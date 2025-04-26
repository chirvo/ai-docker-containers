# AI Containers Repository

This repository contains Dockerfiles and related configurations for building and managing containerized AI services and tools. The focus is on leveraging AMD ROCm for GPU acceleration and providing a streamlined environment for various AI applications.

## Repository Structure

### Dockerfiles

- **Base Images**: Located in `dockerfiles/base/`, Foundational images, Currently there's one single image, `ubuntu_rocm_pytorch.dockerfile`, which includes AMD ROCm, PyTorch, and other essential tools. Good enough. Check the dockerfile for versions.
- **Service Images**: Found in `dockerfiles/services/`, Dockerfiles for building specific AI services:
  - `ollama.dockerfile`: For Ollama.
  - `comfyui.dockerfile`: For ComfyUI.
  - `kokoro-tts-fastapi.dockerfile`: For Kokoro TTS with FastAPI.
  - `forge.dockerfile`: For WebUI Forge, AUTOMATIC1111's fork. [NOT BEING UPDATED]
  - `a1111.dockerfile`: For AUTOMATIC1111's Stable Diffusion WebUI. [NOT BEING UPDATED]
  - `openedai-speech.dockerfile`: For speech-related tasks. [NOT BEING UPDATED]
  - `zonos.dockerfile`: For Zonos. [NOT BEING UPDATED]

### Compose Files

- Located in `compose/services/`. Docker Compose configurations for deploying services. Examples include:
  - `valkey.yaml`: Configuration for the Valkey service.
  - `tika.yaml`: Configuration for Apache Tika.
  - `open-webui-server.yaml`: Configuration for Open WebUI Server.
  - `ollama.yaml`: Configuration for Ollama.
  - `kokoro-tts.yaml`: Configuration for Kokoro TTS.
  - `forge.yaml`: Configuration for Forge.
  - `comfyui.yaml`: Configuration for ComfyUI.
  - `a1111.yaml`: Configuration for AUTOMATIC1111.

### Scripts

- **`build.sh`**: A shell script for building and managing Docker images.
- **`build.py`**: An attempt to migrate `build.sh` to python. Currently put on hold.

### Volumes

- The `volumes/` directory is used for storing persistent data.

## Usage

### Building Images

Use the `build.sh` or `build.py` scripts to build Docker images. For example:

```bash
./build.sh all
```

### Running Services

Use the Docker Compose files in `compose/` to deploy services. For example:

```bash
docker-compose -f compose/services/ollama.yaml up
```

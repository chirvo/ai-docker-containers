FROM ubuntu:noble

ARG DEBIAN_FRONTEND=noninteractive
ARG UV_PYTHON="3.10"
# Always check for the latest version of AMD drivers: https://repo.radeon.com/amdgpu-install/latest/ubuntu/noble/
ARG AMDGPU_VERSION=6.3.60304-1

ENV LC_ALL=C.UTF-8 LANG=C.UTF-8
ENV UV_LINK_MODE=copy
ENV USE_ROCM=1
ENV USE_CUDA=0
ENV TORCH_ROCM_AOTRITON_ENABLE_EXPERIMENTAL=1
ENV PYTORCH_TUNABLEOP_ENABLED=1
ENV PYTORCH_HIP_ALLOC_CONF=garbage_collection_threshold:0.6,max_split_size_mb:6144

## Optional environment variables for specific GPUs
# For RDNA2 GPUs (e.g., 6700, 6600)
# ENV HSA_OVERRIDE_GFX_VERSION="10.3.0"
# ENV PYTORCH_ROCM_ARCH="gfx1030"

## For RDNA3 GPUs (e.g., 7600)
ENV HSA_OVERRIDE_GFX_VERSION="11.0.0"
ENV PYTORCH_ROCM_ARCH="gfx1100"

## Prepare the system: Install basic dependencies, AMDGPU drivers, ROCm libraries, HIP, LLVM
RUN <<EOF
set -e
apt update && apt -y dist-upgrade
# Install basic dependencies
apt install -y apt-utils curl gnupg software-properties-common wget dumb-init rsync git jq
apt install -y liblcms2-2 libz3-4 libtcmalloc-minimal4 pkg-config
apt install -y rustc cargo build-essential gcc make
apt install -y espeak-ng libsndfile1 ffmpeg
# Install AMDGPU drivers and ROCm libraries
wget --no-cache https://repo.radeon.com/amdgpu-install/latest/ubuntu/noble/amdgpu-install_${AMDGPU_VERSION}_all.deb
apt install -y ./amdgpu-install_${AMDGPU_VERSION}_all.deb
amdgpu-install -y --no-dkms --usecase=rocm,hip,mllib --no-32
rm ./amdgpu-install_${AMDGPU_VERSION}_all.deb
# Install HIP and LLVM
apt update && apt -y dist-upgrade
apt install -y hip-rocclr llvm-amdgpu
apt clean && rm -rf /var/lib/apt/lists/*
EOF

## Prepare virtual environment with python 3.10 using uv
# https://docs.astral.sh/uv/
ENV VIRTUAL_ENV="/.venv"
ENV PATH="/.venv/bin:/root/.local/bin:${PATH}"
WORKDIR /
RUN <<EOF
curl -LsSf https://astral.sh/uv/install.sh | sh
uv python install ${UV_PYTHON}
uv venv --python ${UV_PYTHON}
uv pip install --upgrade pip
EOF


## Install pytorch
# stable for rocm6.2.4
# RUN uv pip install --force-reinstall torch torchvision torchaudio --index-url https://download.pytorch.org/whl/rocm6.2.4
# nightly for rocm6.3
RUN uv pip install --pre --force-reinstall torch torchvision torchaudio triton --index-url https://download.pytorch.org/whl/nightly/rocm6.3

## Optional: Install xFormers (can break stuff!)
# RUN <<EOF
# set -e
# uv pip install ninja packaging wheel psutil
# cd /tmp
# uv pip install -v -U git+https://github.com/facebookresearch/xformers.git@main#egg=xformers --no-build-isolation
# EOF

# Healthcheck to monitor container health
HEALTHCHECK --interval=30s --timeout=10s --start-period=5s --retries=3 \
  CMD rocm-smi || exit 1

# Default command
CMD ["bash"]
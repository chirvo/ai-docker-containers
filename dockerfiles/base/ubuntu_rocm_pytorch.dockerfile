FROM ubuntu:noble AS base

ARG DEBIAN_FRONTEND=noninteractive \
  # Always check for the latest version of AMD drivers: https://repo.radeon.com/amdgpu-install/latest/ubuntu/noble/
  AMDGPU_VERSION=6.4.60400-1

ENV LC_ALL=C.UTF-8 LANG=C.UTF-8 \
  UV_LINK_MODE=copy \
  UV_PYTHON="3.11" \
  USE_ROCM=1 \
  USE_CUDA=0 \
  BUILD_TARGET="rocm" \
  FLASH_ATTENTION_TRITON_AMD_ENABLE="TRUE"  \
  TORCH_ROCM_AOTRITON_ENABLE_EXPERIMENTAL=1 \
  VLLM_USE_TRITON_FLASH_ATTN=0 \
  MIOPEN_FIND_MODE=FAST \
  PYTORCH_TUNABLEOP_ENABLED=1 \
  PYTORCH_HIP_ALLOC_CONF=garbage_collection_threshold:0.2,max_split_size_mb:128,expandable_segments:True \
  ## virtual environment variables
  VIRTUAL_ENV="/.venv" \
  PATH="/.venv/bin:/root/.local/bin:${PATH}" \
  ## Optional environment variables for specific GPUs
  # For RDNA2 GPUs (e.g., 6700, 6600)
  # HSA_OVERRIDE_GFX_VERSION="10.3.0" \
  # PYTORCH_ROCM_ARCH="gfx1030" \
  ## For RDNA3 GPUs (e.g., 7600)
  HSA_OVERRIDE_GFX_VERSION="11.0.0" \
  PYTORCH_ROCM_ARCH="gfx1100"

## Prepare the system: Install basic dependencies
RUN <<EOF
set -e
apt update && apt -y dist-upgrade
# Install basic dependencies
apt install -y dumb-init
#libs
apt install -y liblcms2-2 libsndfile1 libtcmalloc-minimal4 libz3-4
#dev tools and compilers
apt install -y apt-utils build-essential clang-19 gcc rustc cargo cmake git make pkg-config python3-setuptools python3-wheel software-properties-common
#other programs
apt install -y curl espeak-ng ffmpeg gnupg jq neovim rsync wget 
# Hardwire clang-19 to be the default clang
update-alternatives --install /usr/bin/clang clang /usr/bin/clang-19 10
update-alternatives --install /usr/bin/clang++ clang++ /usr/bin/clang++-19 10
EOF

## Prepare the system: Install AMDGPU drivers, ROCm libraries, HIP, LLVM
FROM base AS rocmify
RUN <<EOF
set -e
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

## Prepare the system: Install uv, python, 
FROM rocmify AS pytorchify
RUN <<EOF
set -e
## virtual environment using uv: https://docs.astral.sh/uv/
curl -LsSf https://astral.sh/uv/install.sh | sh
uv python install ${UV_PYTHON}
uv venv --python ${UV_PYTHON}
uv pip install --upgrade pip setuptools wheel ninja packaging psutil
# Install pytorch
uv pip install --force-reinstall --pre torch torchvision torchaudio triton --index-url https://download.pytorch.org/whl/nightly/rocm6.3
# Install SafeTensors
uv pip install --upgrade safetensors
## Install flash-attention
#UPDATE: This fails when building the image. Installing 2.7.4.post1 for now.
#pip install -U git+https://github.com/ROCm/flash-attention@howiejay/navi_support
cd /tmp
git clone https://github.com/Dao-AILab/flash-attention.git
cd flash-attention
git checkout v2.7.4.post1
uv run ./setup.py install
cd /
rm -rf /tmp/flash-attention
EOF


# Healthcheck to monitor container health
HEALTHCHECK --interval=30s --timeout=10s --start-period=5s --retries=3 \
  CMD rocm-smi || exit 1

# Default command
CMD ["bash"]
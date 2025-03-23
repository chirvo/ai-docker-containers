FROM ubuntu:noble

ARG DEBIAN_FRONTEND=noninteractive

ENV LC_ALL=C.UTF-8 LANG=C.UTF-8
ENV UV_LINK_MODE=copy
ENV USE_ROCM=1
ENV USE_CUDA=0
ENV TORCH_ROCM_AOTRITON_ENABLE_EXPERIMENTAL=1
ENV PYTORCH_TUNABLEOP_ENABLED=1
ENV PYTORCH_HIP_ALLOC_CONF=garbage_collection_threshold:0.6,max_split_size_mb:6144

## Try this envvars if you have issues:
# For 6700, 6600 and maybe other RDNA2 or older:
#ENV HSA_OVERRIDE_GFX_VERSION="10.3.0"
#ENV PYTORCH_ROCM_ARCH="gfx1030"

## For AMD 7600 and maybe other RDNA3 cards: 
ENV HSA_OVERRIDE_GFX_VERSION="11.0.0"
ENV PYTORCH_ROCM_ARCH="gfx1100"

RUN <<EOF
set -e
apt update && apt-get -y dist-upgrade
apt install -y apt-utils curl gnupg software-properties-common wget dumb-init rsync git jq
apt install -y liblcms2-2 libz3-4 libtcmalloc-minimal4 pkg-config
apt install -y rustc cargo build-essential gcc make
apt install -y espeak-ng libsndfile1 ffmpeg
apt clean
EOF

## Preparing venv with python 3.10 using uv
# https://docs.astral.sh/uv/
ENV VIRTUAL_ENV="/.venv"
ENV UV_PYTHON="3.10"
ENV PATH="/.venv/bin:/root/.local/bin:${PATH}"
WORKDIR /
RUN curl -LsSf https://astral.sh/uv/install.sh | sh
RUN uv python install 3.10
RUN uv venv --python ${UV_PYTHON}
RUN uv pip install --upgrade pip

## Install ROCm and AMDGPU
# Check always wget https://repo.radeon.com/amdgpu-install/latest/ubuntu/noble/ for the latest version
ARG AMDGPU_VERSION=6.3.60304-1
RUN <<EOF
set -e
wget https://repo.radeon.com/amdgpu-install/latest/ubuntu/noble/amdgpu-install_${AMDGPU_VERSION}_all.deb
apt install -y ./amdgpu-install_${AMDGPU_VERSION}_all.deb
amdgpu-install -y --no-dkms --usecase=rocm,hip,mllib --no-32
rm ./amdgpu-install_${AMDGPU_VERSION}_all.deb
EOF

# Install HIP and LLVM
RUN <<EOF
set -e
apt-get update && apt-get -y dist-upgrade
apt-get install -y hip-rocclr llvm-amdgpu
apt-get clean
EOF

## Install pytorch
# stable for rocm6.2.4
# RUN uv pip install --force-reinstall torch torchvision torchaudio --index-url https://download.pytorch.org/whl/rocm6.2.4
# nightly for rocm6.3
RUN uv pip install --pre --force-reinstall torch torchvision torchaudio triton --index-url https://download.pytorch.org/whl/nightly/rocm6.3

## Install xFormers.
RUN <<EOF
set -e
uv pip install ninja packaging wheel psutil
cd /tmp
uv pip install -v -U git+https://github.com/facebookresearch/xformers.git@main#egg=xformers --no-build-isolation
EOF

FROM ubuntu:noble

ARG DEBIAN_FRONTEND=noninteractive

ENV LC_ALL=C.UTF-8 LANG=C.UTF-8
ENV UV_LINK_MODE=copy
ENV USE_ROCM=1
ENV USE_CUDA=0
ENV TORCH_ROCM_AOTRITON_ENABLE_EXPERIMENTAL=1

# Try this envvars if you have issues:
# For 6700, 6600 and maybe other RDNA2 or older:
#ENV HSA_OVERRIDE_GFX_VERSION="10.3.0"
#ENV PYTORCH_ROCM_ARCH="gfx1030"

# For AMD 7600 and maybe other RDNA3 cards: 
#ENV HSA_OVERRIDE_GFX_VERSION="11.0.0"
#ENV PYTORCH_ROCM_ARCH="gfx1100"

RUN <<EOF
apt update && apt-get -y dist-upgrade
apt install -y apt-utils curl gnupg software-properties-common wget dumb-init rsync git jq
apt install -y liblcms2-2 libz3-4 libtcmalloc-minimal4 pkg-config
apt install -y rustc cargo build-essential gcc make
apt install -y espeak-ng libsndfile1 ffmpeg
apt clean
EOF

# Preparing venv with python 3.10 using uv
# https://docs.astral.sh/uv/
ENV VIRTUAL_ENV="/.venv"
ENV UV_PYTHON="3.10"
ENV PATH="/.venv/bin:/root/.local/bin:${PATH}"
WORKDIR /
RUN curl -LsSf https://astral.sh/uv/install.sh | sh
RUN uv venv
RUN uv python install 3.10


# Install ROCm and AMDGPU
RUN <<EOF
wget https://repo.radeon.com/amdgpu-install/6.3.1/ubuntu/noble/amdgpu-install_6.3.60301-1_all.deb \
apt install -y ./amdgpu-install_6.3.60301-1_all.deb \
amdgpu-install -y --no-dkms --usecase=rocm,hip,mllib --no-32 \
  && rm ./amdgpu-install_6.3.60301-1_all.deb
EOF

# Install HIP and LLVM
RUN <<EOF
apt-get update && apt-get -y dist-upgrade
apt-get install -y hip-rocclr llvm-amdgpu
apt-get clean
EOF

# Install pytorch
RUN <<EOF
pip3 install --pre torch torchvision torchaudio --index-url https://download.pytorch.org/whl/nightly/rocm6.3
EOF
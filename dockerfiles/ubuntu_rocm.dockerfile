FROM ubuntu:noble AS base

# Always check for the latest version of AMD drivers: https://repo.radeon.com/amdgpu-install/latest/ubuntu/noble/
ARG DEBIAN_FRONTEND=noninteractive \
  AMDGPU_DEB_VERSION=6.4.60401-1 \
  AMDGPU_VERSION=6.4.1

ENV LC_ALL=C.UTF-8 LANG=C.UTF-8 \
  USE_ROCM=1 \
  USE_CUDA=0 \
  BUILD_TARGET="rocm" \
  MIOPEN_FIND_MODE=FAST \
  HSA_OVERRIDE_GFX_VERSION="11.0.0"

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
wget --no-cache https://repo.radeon.com/amdgpu-install/${AMDGPU_VERSION}/ubuntu/noble/amdgpu-install_${AMDGPU_DEB_VERSION}_all.deb
apt install -y ./amdgpu-install_${AMDGPU_DEB_VERSION}_all.deb
amdgpu-install -y --no-dkms --usecase=rocm,hip,mllib --no-32
rm ./amdgpu-install_${AMDGPU_DEB_VERSION}_all.deb
# Install HIP and LLVM
apt update && apt -y dist-upgrade
apt install -y hip-rocclr llvm-amdgpu
apt clean && rm -rf /var/lib/apt/lists/*
EOF

# Healthcheck to monitor container health
HEALTHCHECK --interval=30s --timeout=10s --start-period=5s --retries=3 \
  CMD rocm-smi || exit 1

# Default command
CMD ["bash"]

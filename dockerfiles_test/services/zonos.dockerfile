#WIP. Don't use this file yet.
FROM rocm/pytorch:rocm6.2.2_ubuntu22.04_py3.10_pytorch_2.5.1

ENV UV_LINK_MODE=copy
ENV USE_ROCM=1
ENV TORCH_ROCM_AOTRITON_ENABLE_EXPERIMENTAL=1

COPY --from=ghcr.io/astral-sh/uv:latest /uv /uvx /bin/
RUN <<EOF
apt update
apt install -y wget git espeak-ng libsndfile1 ffmpeg
rm -rf /var/lib/apt/lists/*
EOF

RUN <<EOF
git config --global user.email "bigchirv@gmail.com"
git config --global user.name "Irving A. Bermúdez S."
git clone https://github.com/Zyphra/Zonos.git /app
EOF

WORKDIR /app
RUN <<EOF
mv pyproject.toml pyproject.toml.bak
cat pyproject.toml.bak | grep -v torch| sed -e 's/"causal-conv1d.*",//'> pyproject.toml 
EOF

RUN uv pip install --system -e . && uv pip install --system -e .[compile]



RUN <<EOF
ROCM_VERSION=6.3.2 AMDGPU_VERSION=6.3.2 APT_PREF=Package: *\nPin: release o=repo.radeon.com\nPin-Priority: 600 /bin/sh -c apt-get update
DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends ca-certificates curl libnuma-dev gnupg
curl -sL https://repo.radeon.com/rocm/rocm.gpg.key | apt-key add -
printf "deb [arch=amd64] https://repo.radeon.com/rocm/apt/$ROCM_VERSION/ noble main" | tee /etc/apt/sources.list.d/rocm.list
printf "deb [arch=amd64] https://repo.radeon.com/amdgpu/$AMDGPU_VERSION/ubuntu noble main" | tee /etc/apt/sources.list.d/amdgpu.list
apt-get update && DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends sudo libelf1 kmod file python3-dev python3-pip rocm-dev build-essential
apt-get clean
rm -rf /var/lib/apt/lists/*
# buildkit
EOF
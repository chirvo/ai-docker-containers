FROM chirvo/ubuntu_rocm:latest

ARG DEBIAN_FRONTEND=noninteractive
ENV LC_ALL=C.UTF-8 LANG=C.UTF-8 \
  USE_ROCM=1 \
  USE_CUDA=0 \
  HSA_OVERRIDE_GFX_VERSION="11.0.0" \
  PATH="/.venv/bin:/root/.local/bin:${PATH}" \
  BUILD_TARGET="rocm" \
  VIRTUAL_ENV="/.venv" \
  UV_LINK_MODE=copy \
  UV_PYTHON="3.11" \
  PYTORCH_HIP_ALLOC_CONF=garbage_collection_threshold:0.2,max_split_size_mb:128,expandable_segments:True \
  PYTORCH_ROCM_ARCH="gfx1100"

COPY --from=ghcr.io/astral-sh/uv:latest /uv /uvx /bin/
RUN <<EOF
set -e
uv venv --python ${UV_PYTHON}
uv pip install --upgrade pip setuptools wheel ninja packaging psutil
# Install pytorch
uv pip install --force-reinstall --pre torch torchvision torchaudio triton --index-url https://download.pytorch.org/whl/nightly/rocm6.4
# Install SafeTensors
uv pip install --upgrade safetensors
EOF

# Default command
CMD ["bash"]

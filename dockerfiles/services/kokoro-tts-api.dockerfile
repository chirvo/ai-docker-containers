FROM rocm/pytorch:rocm6.3.2_ubuntu22.04_py3.10_pytorch_release_2.4.0

# Set environment variables
ENV DOWNLOAD_MODEL=true
ENV PYTHONUNBUFFERED=1
ENV PYTHONPATH=/app:/app/models
ENV PATH="/app/.venv/bin:$PATH"
ENV UV_LINK_MODE=copy
ENV TORCH_ROCM_AOTRITON_ENABLE_EXPERIMENTAL=1

# Base dependencies
RUN <<EOF
apt-get update
apt-get install --no-install-recommends -y wget git espeak-ng libsndfile1 ffmpeg
apt-get clean
rm -rf /var/lib/apt/lists/*
EOF

# Install uv
COPY --from=ghcr.io/astral-sh/uv:latest /uv /uvx /bin/

# Configure git
RUN git config --global user.email "bigchirv@gmail.com" && \
  git config --global user.name "Irving A. Bermúdez S."

# Clone remsky/Kokoro-FastAPI, merge with bgm4free's fork
RUN git clone https://github.com/remsky/Kokoro-FastAPI.git /app
WORKDIR /app
RUN git remote add upstream https://github.com/bgs4free/Kokoro-FastAPI.git && \
  git fetch upstream && \
  git checkout upstream/add-rocm-support && \
  git merge --strategy ours master && \
  mkdir -p /app/api/src/models/v1_0 /app/api/src/voices/V1_0

# Download and extract models (test)
RUN python docker/scripts/download_model.py --output api/src/models/v1_0

# Download and extract voice models
WORKDIR /app/api/src/voices
RUN <<EOF
for VOICE_URL in $(wget -qO- https://huggingface.co/hexgrad/Kokoro-82M/tree/main/voices | grep -Eo "/hexgrad/[a-zA-Z0-9./?=_-]*.pt" | sort -u | grep resolve)
do
  wget https://huggingface.co$VOICE_URL;
  sleep 1
done
EOF

# Switch back to app directory
WORKDIR /app

# Install dependencies
RUN --mount=type=cache,target=/root/.cache/uv uv venv && uv sync --extra rocm --no-install-project

# Run FastAPI server
CMD ["uv", "run", "python", "-m", "uvicorn", "api.src.main:app", "--host", "0.0.0.0", "--port", "8880", "--log-level", "debug"]

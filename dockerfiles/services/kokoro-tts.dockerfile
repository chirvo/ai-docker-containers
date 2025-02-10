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
apt-get install --no-install-recommends -y curl git espeak-ng libsndfile1 ffmpeg
apt-get clean
rm -rf /var/lib/apt/lists/*
EOF

# Install uv
COPY --from=ghcr.io/astral-sh/uv:latest /uv /uvx /bin/

RUN git config --global user.email "bigchirv@gmail.com"
RUN git config --global user.name "Irving A. Bermúdez S."

# Clone remsky/Kokoro-FastAPI, merge with bgm4free's fork
RUN git clone https://github.com/remsky/Kokoro-FastAPI.git /app
WORKDIR /app
RUN 
RUN git remote add upstream https://github.com/bgs4free/Kokoro-FastAPI.git
RUN git fetch upstream
RUN git checkout upstream/add-rocm-support
# RUN git rm MigrationWorkingNotes.md uv.lock
# RUN git commit -a -m "Removed conflicting files"
RUN git merge --strategy ours master
# RUN git rm MigrationWorkingNotes.md uv.lock
# RUN git commit -m "Merge remote-tracking branch 'upstream/add-rocm-support'"

# Create directories
RUN mkdir -p /app/models mkdir -p /app/api/src/voices

# Download and extract models
WORKDIR /app/models
RUN curl -L -o model.tar.gz https://github.com/remsky/Kokoro-FastAPI/releases/download/v0.0.1/kokoro-82m-pytorch.tar.gz && \
  tar xzf model.tar.gz && \
  rm model.tar.gz

# Download and extract voice models
WORKDIR /app/api/src/voices
RUN curl -L -o voices.tar.gz https://github.com/remsky/Kokoro-FastAPI/releases/download/v0.0.1/voice-models.tar.gz && \
  tar xzf voices.tar.gz && \
  rm voices.tar.gz

# Switch back to app directory
WORKDIR /app

# Install dependencies
RUN --mount=type=cache,target=/root/.cache/uv uv venv && uv sync --extra rocm --no-install-project

# RUN python docker/scripts/download_model.py --output api/src/models/v1_0
# Run FastAPI server
CMD ["uv", "run", "python", "-m", "uvicorn", "api.src.main:app", "--host", "0.0.0.0", "--port", "8880", "--log-level", "debug"]

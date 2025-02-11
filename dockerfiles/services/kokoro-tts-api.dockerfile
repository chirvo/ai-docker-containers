FROM rocm/pytorch:rocm6.2.2_ubuntu22.04_py3.10_pytorch_2.5.1

# Set environment variables
ENV DOWNLOAD_MODEL=true
ENV PYTHONUNBUFFERED=1
ENV PYTHONPATH=/app:/app/models
ENV PATH="/app/.venv/bin:$PATH"
ENV UV_LINK_MODE=copy
ENV USE_ROCM=true
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
  git switch -c add-rocm-support && \
  git rm MigrationWorkingNotes.md uv.lock docker/rocm/uv.lock && \
  git commit -a -m "Remove MigrationWorkingNotes.md and uv.lock" && \
  git checkout master && \
  git merge add-rocm-support

# Install dependencies
RUN --mount=type=cache,target=/root/.cache/uv uv venv && uv sync --extra rocm --no-install-project

# Install project
RUN --mount=type=cache,target=/root/.cache/uv pip install -e ".[rocm]" 

# Download and extract models (test)
RUN python docker/scripts/download_model.py --output api/src/models/v1_0

# Run FastAPI server
CMD ["uv", "run", "--extra", "rocm", "python", "-m", "uvicorn", "api.src.main:app", "--host", "0.0.0.0", "--port", "8880", "--log-level", "debug"]
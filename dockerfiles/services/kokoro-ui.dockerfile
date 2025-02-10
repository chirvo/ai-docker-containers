FROM rocm/pytorch:rocm6.3.2_ubuntu22.04_py3.10_pytorch_release_2.4.0

# Set environment variables
ENV API_HOST=0.0.0.0
ENV API_PORT=8880

# Base dependencies
RUN <<EOF
apt-get update
apt-get install --no-install-recommends -y curl git espeak-ng libsndfile1
apt-get clean
rm -rf /var/lib/apt/lists/*
EOF

# Install uv
COPY --from=ghcr.io/astral-sh/uv:latest /uv /uvx /bin/

RUN git config --global user.email "bigchirv@gmail.com"
RUN git config --global user.name "Irving A. Bermúdez S."

# Clone remsky/Kokoro-FastAPI, merge with bgs4free's fork
RUN git clone https://github.com/remsky/Kokoro-FastAPI.git /app
WORKDIR /app
RUN git remote add upstream https://github.com/bgs4free/Kokoro-FastAPI.git
RUN git fetch upstream
RUN git checkout upstream/add-rocm-support
RUN git merge --strategy ours master

# Install dependencies
RUN --mount=type=cache,target=/root/.cache/uv uv venv && uv sync --extra rocm --no-install-project

WORKDIR /app/ui
# Run the Gradio app
CMD ["python", "app.py"]

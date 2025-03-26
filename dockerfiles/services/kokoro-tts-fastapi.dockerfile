FROM chirvo/base/ubuntu_rocm_pytorch:latest AS base

# Set environment variables
ENV DOWNLOAD_MODEL=true
ENV PYTHONUNBUFFERED=1
ENV PYTHONPATH=/app:/app/models

# Configure git
RUN git config --global user.email "bigchirv@gmail.com" && git config --global user.name "Irving A. Bermúdez S."

# Clone remsky/Kokoro-FastAPI, merge with bgm4free's fork
RUN <<EOF
set -e
git clone https://github.com/remsky/Kokoro-FastAPI.git /app
cd /app
git remote add upstream https://github.com/bgs4free/Kokoro-FastAPI.git
git fetch upstream
git checkout upstream/add-rocm-support
git switch -c add-rocm-support
git rm MigrationWorkingNotes.md uv.lock docker/rocm/uv.lock
git commit -a -m "Remove MigrationWorkingNotes.md and uv.lock"
git checkout master
git merge add-rocm-support
# Install dependencies
uv sync --active --extra rocm --no-install-project && uv pip install -e ".[rocm]" 
# Download and extract models (test)
python docker/scripts/download_model.py --output api/src/models/v1_0
EOF

WORKDIR /app

# Run FastAPI server
CMD ["uv", "run", "--active", "--extra", "rocm", "python", "-m", "uvicorn", "api.src.main:app", "--host", "0.0.0.0", "--port", "8880"]
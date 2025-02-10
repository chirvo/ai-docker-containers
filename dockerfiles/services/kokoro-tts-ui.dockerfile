FROM python:3.10-slim

# Set environment variables
ENV API_HOST=0.0.0.0
ENV API_PORT=8880

RUN <<EOF
apt-get update
apt-get install --no-install-recommends -y curl git
apt-get clean
rm -rf /var/lib/apt/lists/*
EOF

# Install dependencies
RUN pip install gradio==5.9.1 requests==2.32.3

RUN git config --global user.email "bigchirv@gmail.com"
RUN git config --global user.name "Irving A. Bermúdez S."

# Clone remsky/Kokoro-FastAPI, merge with bgs4free's fork
RUN git clone https://github.com/remsky/Kokoro-FastAPI.git /app
WORKDIR /app
RUN git remote add upstream https://github.com/bgs4free/Kokoro-FastAPI.git
RUN git fetch upstream
RUN git checkout upstream/add-rocm-support
RUN git merge --strategy ours master
WORKDIR /app/ui

# Create necessary directories
RUN mkdir -p data/inputs data/outputs

# Run the Gradio app
CMD ["python", "app.py"]


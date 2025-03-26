FROM chirvo/base/ubuntu_rocm_pytorch:latest AS base

WORKDIR /root

## Download and install the base Ollama binaries, and the ROCm-compatible Ollama binaries
RUN <<EOF
set -e
curl -L https://ollama.com/download/ollama-linux-amd64.tgz -o ollama-linux-amd64.tgz
curl -L https://ollama.com/download/ollama-linux-amd64-rocm.tgz -o ollama-linux-amd64-rocm.tgz
tar -C /usr -xzf ollama-linux-amd64.tgz
tar -C /usr -xzf ollama-linux-amd64-rocm.tgz
rm ollama-linux-amd64.tgz ollama-linux-amd64-rocm.tgz
EOF

# Set environment variables for the Ollama service
ENV OLLAMA_HOST=0.0.0.0:11434

# Expose the service port
EXPOSE 11434/tcp

# Add a health check for the Ollama service
HEALTHCHECK --interval=30s --timeout=10s --start-period=5s --retries=3 \
  CMD curl -f http://localhost:11434/ || exit 1

# Run the Ollama service
CMD ["/usr/bin/ollama", "serve"]
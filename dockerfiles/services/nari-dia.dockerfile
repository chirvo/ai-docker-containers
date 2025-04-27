FROM chirvo/base/ubuntu_rocm_pytorch:latest AS base
ENV GRADIO_SERVER_NAME="0.0.0.0" \
  GRADIO_SERVER_PORT="7860"
RUN <<EOF
set -e
git clone --depth 1 https://github.com/nari-labs/dia.git app
cd app
uv pip install gradio soundfile dac safetensors descript-audio-codec
EOF

WORKDIR /app
EXPOSE 7860/tcp
CMD ["uv", "run", "--active", "--no-project", "app.py"]
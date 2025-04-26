FROM chirvo/base/ubuntu_rocm_pytorch:latest AS base
RUN <<EOF
set -e
git clone --depth 1 https://github.com/nari-labs/dia.git app
cd app
uv pip install gradio soundfile dac safetensors descript-audio-codec
EOF

WORKDIR /app
EXPOSE 7860/tcp
CMD ["python", "app.py"]
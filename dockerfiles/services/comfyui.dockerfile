FROM chirvo/base/ubuntu_rocm_pytorch:latest AS builder

ENV GRADIO_ANALYTICS_ENABLED=FALSE

# Install dependencies and clone the repository
WORKDIR /app
RUN  <<EOF
set -e
git clone https://github.com/comfyanonymous/ComfyUI.git /app
uv pip install --upgrade 'optree>=0.13.0'
uv pip install onnx boto3 imageio-ffmpeg insightface
uv pip install -r requirements.txt
# Clone ComfyUI-Manager and install its dependencies
cd /app/custom_nodes
git clone https://github.com/ltdrdata/ComfyUI-Manager.git comfyui-manager
uv pip install -r comfyui-manager/requirements.txt
EOF

EXPOSE 8188/tcp
CMD ["/bin/sh", "-c", "LD_PRELOAD=libtcmalloc_minimal.so.4 python main.py --listen --use-pytorch-cross-attention --reserve-vram 4" ]
FROM chirvo/base/ubuntu_rocm_pytorch:latest AS base

ENV GRADIO_ANALYTICS_ENABLED=FALSE

ARG COMFYUI_PARAMS="--use-pytorch-cross-attention --reserve-vram 4"
WORKDIR /app
RUN  <<EOF
set -e
# Clone the ComfyUI repository and install its dependencies
git clone --depth 1 https://github.com/comfyanonymous/ComfyUI.git /app
uv pip install --upgrade 'optree>=0.13.0'
uv pip install onnx boto3 imageio-ffmpeg insightface setuptools simpleeval
uv pip install -r requirements.txt
# Clone ComfyUI-Manager and install its dependencies
cd /app/custom_nodes
git clone https://github.com/ltdrdata/ComfyUI-Manager.git comfyui-manager
uv pip install -r comfyui-manager/requirements.txt
EOF

FROM base AS final
# Create the entrypoint script and set it as the default command
WORKDIR /
RUN  <<EOF
set -e
# Create the entrypoint script
cat <<EOS > entrypoint.sh 
#!/bin/bash
if  [ ! -e '/.REQUIREMENTS_SATISFIED' ]; then
  find /app/custom_nodes -maxdepth 2 -type f -name 'requirements.txt' -exec pip install -r {} \\;
  touch /.REQUIREMENTS_SATISFIED
fi
cd /app
LD_PRELOAD=libtcmalloc_minimal.so.4 python main.py --listen ${COMFYUI_PARAMS} \$@
EOS
chmod +x entrypoint.sh
EOF

# Expose the ComfyUI port
EXPOSE 8188/tcp

ENTRYPOINT [ "/entrypoint.sh" ]
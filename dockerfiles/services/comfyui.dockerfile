FROM chirvo/base/ubuntu_rocm_pytorch:latest

# For 6700, 6600 and maybe other RDNA2 or older:
#ENV HSA_OVERRIDE_GFX_VERSION=10.3.0
# For AMD 7600 and maybe other RDNA3 cards:
#ENV HSA_OVERRIDE_GFX_VERSION=11.0.0
ENV TORCH_ROCM_AOTRITON_ENABLE_EXPERIMENTAL=1
ENV PYTORCH_TUNABLEOP_ENABLED=1
ENV GRADIO_ANALYTICS_ENABLED=FALSE

# ENV PYTORCH_HIP_ALLOC_CONF=garbage_collection_threshold:0.6,max_split_size_mb:6144

RUN git clone https://github.com/comfyanonymous/ComfyUI.git /app
WORKDIR /app
RUN uv pip install --upgrade 'optree>=0.13.0'
RUN uv pip install onnx boto3 imageio-ffmpeg insightface
RUN uv pip install -r requirements.txt

WORKDIR /app/custom_nodes
RUN git clone https://github.com/ltdrdata/ComfyUI-Manager.git comfyui-manager
WORKDIR /app/custom_nodes/comfyui-manager
RUN uv pip install -r requirements.txt
WORKDIR /app
EXPOSE 8188/tcp
# --cpu-vae instead of --fp32-vae if there's VRAM shortage
# CMD ["python3", "main.py", "--listen", "--use-split-cross-attention", "--reserve-vram", "5", "--normalvram", "--fast", "--force-fp32", "--fp32-vae"]
CMD ["/bin/sh", "-c", "LD_PRELOAD=libtcmalloc_minimal.so.4 python main.py --listen --use-split-cross-attention --lowvram --reserve-vram 4 --force-fp32 --fp32-vae" ]
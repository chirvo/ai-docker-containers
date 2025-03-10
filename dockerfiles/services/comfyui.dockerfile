FROM rocm/pytorch:rocm6.3.4_ubuntu24.04_py3.12_pytorch_release_2.4.0

RUN git clone https://github.com/comfyanonymous/ComfyUI.git /app
WORKDIR /app
RUN pip install --pre --force-reinstall torch torchvision torchaudio --index-url https://download.pytorch.org/whl/nightly/rocm6.3
RUN pip3 install -r requirements.txt
RUN pip install --upgrade 'optree>=0.13.0'

WORKDIR /app/custom_nodes
RUN git clone https://github.com/ltdrdata/ComfyUI-Manager.git comfyui-manager
WORKDIR /app
# For 6700, 6600 and maybe other RDNA2 or older:
#ENV HSA_OVERRIDE_GFX_VERSION=10.3.0
# For AMD 7600 and maybe other RDNA3 cards:
#ENV HSA_OVERRIDE_GFX_VERSION=11.0.0
ENV TORCH_ROCM_AOTRITON_ENABLE_EXPERIMENTAL=1
ENV PYTORCH_TUNABLEOP_ENABLED=1
EXPOSE 8188/tcp

CMD ["python3", "main.py", "--listen", "--use-split-cross-attention", "--reserve-vram", "4", "--fast", "--disable-smart-memory", "--force-fp32"]

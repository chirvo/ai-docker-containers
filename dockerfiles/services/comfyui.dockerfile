FROM rocm/pytorch:rocm6.2.2_ubuntu22.04_py3.10_pytorch_2.5.1

RUN git clone https://github.com/comfyanonymous/ComfyUI.git /app
WORKDIR /app
RUN pip3 install -r requirements.txt

# For 6700, 6600 and maybe other RDNA2 or older:
#ENV HSA_OVERRIDE_GFX_VERSION=10.3.0
# For AMD 7600 and maybe other RDNA3 cards:
#ENV HSA_OVERRIDE_GFX_VERSION=11.0.0
EXPOSE 8188/tcp
CMD ["python3", "main.py", "--listen", "--use-split-cross-attention"]

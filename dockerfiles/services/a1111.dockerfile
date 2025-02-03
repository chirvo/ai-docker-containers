FROM rocm/pytorch:rocm6.3.2_ubuntu22.04_py3.10_pytorch_release_2.4.0

RUN git clone https://github.com/AUTOMATIC1111/stable-diffusion-webui.git /app
WORKDIR /app
RUN git checkout --detach tags/v1.10.1
RUN pip install transformers
RUN cat requirements.txt | grep -v transformers > /tmp/requirements.txt
RUN pip install -r /tmp/requirements.txt

# For 6700, 6600 and maybe other RDNA2 or older:
#ENV HSA_OVERRIDE_GFX_VERSION=10.3.0D
# For AMD 7600 and maybe other RDNA3 cards:
#ENV HSA_OVERRIDE_GFX_VERSION=11.0.0
EXPOSE 7860/tcp
CMD python3 launch.py --listen --precision full --no-half --enable-insecure-extension-access

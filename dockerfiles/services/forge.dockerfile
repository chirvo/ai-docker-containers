FROM rocm/pytorch:rocm6.3.2_ubuntu22.04_py3.10_pytorch_release_2.4.0

RUN curl -L https://github.com/lllyasviel/stable-diffusion-webui-forge/archive/refs/tags/latest.tar.gz > latest.tar.gz
RUN tar zxf latest.tar.gz && mv stable-diffusion-webui-forge-latest /app && rm latest.tar.gz
WORKDIR /app
RUN pip install transformers insightface
RUN cat requirements.txt | grep -v transformers > /tmp/requirements.txt
RUN pip install -r /tmp/requirements.txt

# For 6700, 6600 and maybe other RDNA2 or older:
#ENV HSA_OVERRIDE_GFX_VERSION=10.3.0D
# For AMD 7600 and maybe other RDNA3 cards:
#ENV HSA_OVERRIDE_GFX_VERSION=11.0.0
EXPOSE 7860/tcp
CMD python3 launch.py --listen --precision full --no-half --enable-insecure-extension-access

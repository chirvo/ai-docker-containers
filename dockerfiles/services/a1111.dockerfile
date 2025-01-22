FROM chirvo/pytorch_rocm:latest

RUN apt-get update && apt-get -y dist-upgrade \
  && apt-get install -y \
  rustc cargo build-essential gcc make openssl libssl-dev \
  && apt-get clean
RUN git clone https://github.com/AUTOMATIC1111/stable-diffusion-webui.git /app
WORKDIR /app
RUN uv pip install transformers
RUN cat requirements.txt | grep -v transformers > /tmp/requirements.txt
RUN uv pip install -r /tmp/requirements.txt

# For 6700, 6600 and maybe other RDNA2 or older:
#ENV HSA_OVERRIDE_GFX_VERSION=10.3.0D
# For AMD 7600 and maybe other RDNA3 cards:
#ENV HSA_OVERRIDE_GFX_VERSION=11.0.0
EXPOSE 7860/tcp
CMD python3 launch.py --listen --precision full --no-half --enable-insecure-extension-access

FROM chirvo/base/ubuntu_rocm_pytorch:latest AS base

RUN curl -L https://github.com/lllyasviel/stable-diffusion-webui-forge/archive/refs/tags/latest.tar.gz > latest.tar.gz
RUN tar zxf latest.tar.gz && mv stable-diffusion-webui-forge-latest /app && rm latest.tar.gz
WORKDIR /app
EXPOSE 7860/tcp
CMD ["python3", "launch.py", "--listen", "--precision", "full", "--no-half", "--enable-insecure-extension-access"]

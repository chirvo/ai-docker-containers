FROM chirvo/base/ubuntu_rocm_pytorch:latest AS base

RUN git clone https://github.com/AUTOMATIC1111/stable-diffusion-webui.git /app
WORKDIR /app
RUN git checkout --detach tags/v1.10.1
RUN pip install transformers
RUN cat requirements.txt | grep -v transformers > /tmp/requirements.txt
RUN pip install -r /tmp/requirements.txt

EXPOSE 7860/tcp
CMD ["python3", "launch.py", "--listen", "--precision", "full", "--no-half", "--enable-insecure-extension-access"]

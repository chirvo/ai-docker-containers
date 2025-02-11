FROM rocm/pytorch:rocm6.3.2_ubuntu22.04_py3.10_pytorch_release_2.4.0

ARG TARGETPLATFORM
RUN <<EOF
apt-get update
apt-get install --no-install-recommends -y curl ffmpeg git
apt-get clean
rm -rf /var/lib/apt/lists/*
EOF
ENV PATH="/root/.cargo/bin:${PATH}"

RUN git clone https://github.com/matatonic/openedai-speech.git /app
WORKDIR /app
RUN pip install piper-tts --no-deps piper-phonemize-cross onnxruntime numpy
RUN cat requirements-rocm.txt | grep -v piper-tts | grep -v torch > /tmp/requirements.txt
RUN pip install -r /tmp/requirements.txt
RUN pip install --upgrade 'optree>=0.13.0'
RUN pip install --upgrade torch torchvision torchaudio --index-url https://download.pytorch.org/whl/rocm6.2.4

ENV USE_ROCM=1
ENV PRELOAD_MODEL=xtts_v2.0.2
ENV TTS_HOME=voices
ENV HF_HOME=voices
ENV COQUI_TOS_AGREED=1

CMD ["bash", "startup.sh"]
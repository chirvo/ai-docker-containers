FROM chirvo/base/ubuntu_rocm_pytorch:latest AS base

ENV PRELOAD_MODEL=xtts_v2.0.2
ENV TTS_HOME=voices
ENV HF_HOME=voices
ENV COQUI_TOS_AGREED=1

RUN <<EOF
set -e
git clone https://github.com/matatonic/openedai-speech.git /app
cd /app
uv pip install piper-tts --no-deps piper-phonemize-cross onnxruntime numpy
cat requirements-rocm.txt | grep -v piper-tts | grep -v torch > /tmp/requirements.txt
uv pip install -r /tmp/requirements.txt
EOF

CMD ["bash", "startup.sh"]
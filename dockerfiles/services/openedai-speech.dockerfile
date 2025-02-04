FROM rocm/pytorch:rocm6.3.2_ubuntu22.04_py3.10_pytorch_release_2.4.0
# FROM python:3.11-slim

RUN --mount=type=cache,target=/root/.cache/pip pip install -U pip

ARG TARGETPLATFORM
RUN <<EOF
apt-get update
apt-get install --no-install-recommends -y curl ffmpeg git
if [ "$TARGETPLATFORM" != "linux/amd64" ]; then
	apt-get install --no-install-recommends -y build-essential
	curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y
fi

apt-get clean
rm -rf /var/lib/apt/lists/*
EOF
ENV PATH="/root/.cargo/bin:${PATH}"

RUN git clone https://github.com/matatonic/openedai-speech.git /app
WORKDIR /app
RUN pip install transformers
RUN cat requirements-rocm.txt | grep -v transformers > /tmp/requirements.txt
RUN pip install -r /tmp/requirements.txt

ENV PRELOAD_MODEL=xtts_v2.0.2
ENV TTS_HOME=voices
ENV HF_HOME=voices
ENV COQUI_TOS_AGREED=1

CMD bash startup.sh
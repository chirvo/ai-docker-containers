FROM chirvo/pytorch_rocm:latest

# Install Pre-reqs
RUN apt-get update && apt-get install --no-install-recommends -y \
  git vim nano build-essential python3-dev python3-venv python3-pip gcc g++ ffmpeg

# Set working directory
WORKDIR /app

# Clone the repo
RUN git clone https://github.com/rsxdalv/tts-generation-webui.git /tmp/tts-generation-webui
RUN cp -a /tmp/tts-generation-webui /app
RUN rm -r /tmp/tts-generation-webui

# Install all requirements
RUN pip3 install -r requirements.txt
RUN pip3 install -r requirements_audiocraft_only.txt --no-deps
RUN pip3 install -r requirements_audiocraft_deps.txt
RUN pip3 install -r requirements_bark_hubert_quantizer.txt
RUN pip3 install -r requirements_rvc.txt

# Add React webui (testing)
# RUN cd react-ui && npm install && npm run build

# Run the server
CMD python server.py
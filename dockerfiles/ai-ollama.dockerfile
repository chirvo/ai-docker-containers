FROM chirvo/base-rocm:latest

ARG URI=https://ollama.ai/download/ollama-linux-amd64
WORKDIR /app
RUN wget ${URI} \
  && mv ollama-linux-amd64 ollama \
  && chmod 755 ollama

EXPOSE 11434/tcp
CMD "/app/ollama serve"


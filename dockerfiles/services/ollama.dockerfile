FROM chirvo/pytorch_rocm:latest

WORKDIR /root
# Base ollama installation
RUN curl -L https://ollama.com/download/ollama-linux-amd64.tgz -o ollama-linux-amd64.tgz
RUN tar -C /usr -xzf ollama-linux-amd64.tgz
RUN rm ollama-linux-amd64.tgz
# ollama ROCm support
RUN curl -L https://ollama.com/download/ollama-linux-amd64-rocm.tgz -o ollama-linux-amd64-rocm.tgz
RUN tar -C /usr -xzf ollama-linux-amd64-rocm.tgz
RUN rm ollama-linux-amd64-rocm.tgz

ENV OLLAMA_HOST=0.0.0.0:11434
EXPOSE 11434/tcp
CMD ["/usr/bin/ollama", "serve"]

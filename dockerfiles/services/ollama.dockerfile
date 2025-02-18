FROM rocm/pytorch:rocm6.2.2_ubuntu22.04_py3.10_pytorch_2.5.1

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

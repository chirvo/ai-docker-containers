FROM chirvo/rocm:latest

WORKDIR /root
RUN wget https://github.com/jmorganca/ollama/releases/download/v0.1.22/ollama-linux-amd64
RUN mv ollama-linux-amd64 ollama
RUN chmod 755 ollama

ENV OLLAMA_HOST 0.0.0.0:11434
EXPOSE 11434/tcp
CMD /root/ollama serve

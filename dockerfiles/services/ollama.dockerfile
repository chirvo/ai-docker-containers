FROM chirvo/rocm:latest

ARG URI=https://ollama.ai/download/ollama-linux-amd64

WORKDIR /opt/rocm-6.0.0/lib
RUN ln -sf libhipblas.so.2.0.60000 libhipblas.so.1
RUN ln -sf librocblas.so.4.0.60000 librocblas.so.3
RUN ln -sf librocsparse.so.1.0.0.60000 librocsparse.so.0

WORKDIR /app
RUN wget ${URI}
RUN mv ollama-linux-amd64 ollama
RUN chmod 755 ollama

EXPOSE 11434/tcp
CMD /app/ollama serve


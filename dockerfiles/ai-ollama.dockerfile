FROM chirvo/ai-base:latest

RUN wget https://go.dev/dl/go1.21.5.linux-amd64.tar.gz \
  && tar -xvf go1.21.5.linux-amd64.tar.gz -C /usr/local

ENV GOROOT="/usr/local/go"
ENV GOPATH="/go"
ENV PATH="${GOPATH}}/bin:${GOROOT}/bin:${PATH}"

EXPOSE 11434/tcp
CMD ["ollama"]


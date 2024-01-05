FROM chirvo/base-rocm:latest AS rocm
FROM chirvo/base-golang:latest AS golang

ARG GIT_URI="https://github.com/jmorganca/ollama.git"
ARG DEST_DIR="ollama"
WORKDIR /app

#Git clone
RUN git clone ${GIT_URI}

# Build ollama
RUN cd ${DEST_DIR} \
  && go generate ./... \
  && go build .

EXPOSE 11434/tcp
CMD "/bin/bash"
# CMD "./ollama serve"


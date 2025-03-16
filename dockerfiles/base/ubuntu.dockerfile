FROM ubuntu:noble

ENV LC_ALL=C.UTF-8 LANG=C.UTF-8

ARG DEBIAN_FRONTEND=noninteractive

RUN apt-get update && apt-get -y dist-upgrade \
  && apt-get install -y \
  apt-utils curl gnupg software-properties-common wget dumb-init ffmpeg rsync git jq liblcms2-2 libz3-4 \
  libtcmalloc-minimal4 pkg-config rustc cargo build-essential gcc make \
  && apt-get clean

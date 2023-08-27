FROM ubuntu:jammy

ENV LC_ALL=C.UTF-8 LANG=C.UTF-8

ARG DEBIAN_FRONTEND=noninteractive
RUN apt-get update && apt-get -y dist-upgrade \
    && apt-get install -y apt-utils gnupg software-properties-common wget
RUN wget https://repo.radeon.com/amdgpu-install/5.6/ubuntu/jammy/amdgpu-install_5.6.50600-1_all.deb \
    && apt-get install -y ./amdgpu-install_5.6.50600-1_all.deb \
    && amdgpu-install -y --no-dkms --usecase=rocm,hip,mllib --no-32 \
    && rm ./amdgpu-install_5.6.50600-1_all.deb
RUN apt-get update && apt-get -y dist-upgrade && apt-get install -y \
    dumb-init ffmpeg git hip-rocclr jq liblcms2-2 libz3-4 \
    libtcmalloc-minimal4 llvm-amdgpu pkg-config python3-pip python3-venv \
    && apt-get clean

# If you wanna use the stable version of PyTorch, comment the last line, then uncomment the line below
#RUN pip3 install torch torchvision torchaudio --index-url https://download.pytorch.org/whl/rocm5.4.2
###
RUN pip3 install --pre torch torchvision torchaudio --index-url https://download.pytorch.org/whl/nightly/rocm5.6

CMD /bin/bash
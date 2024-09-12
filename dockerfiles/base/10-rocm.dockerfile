FROM chirvo/ubuntu:latest

ENV USE_CUDA=0
#################
# Common envvars
# Try running it with this command if you have issues:
# For 6700, 6600 and maybe other RDNA2 or older:
#ENV HSA_OVERRIDE_GFX_VERSION="10.3.0"
#ENV PYTORCH_ROCM_ARCH="gfx1030"

# For AMD 7600 and maybe other RDNA3 cards: 
#ENV HSA_OVERRIDE_GFX_VERSION="11.0.0"
#ENV PYTORCH_ROCM_ARCH="gfx1100"

RUN wget https://repo.radeon.com/amdgpu-install/6.2/ubuntu/jammy/amdgpu-install_6.2.60200-1_all.deb \
  && apt install -y ./amdgpu-install_6.2.60200-1_all.deb \
  && amdgpu-install -y --no-dkms --usecase=rocm,hip,mllib --no-32 \
  && rm ./amdgpu-install_6.2.60200-1_all.deb
RUN apt-get update && apt-get -y dist-upgrade \
  && apt-get install -y hip-rocclr llvm-amdgpu \
  && apt-get clean

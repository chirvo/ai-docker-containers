FROM pytorch2-rocm5-jammy:latest

# Try running it with this command if you have issues:
# For 6700, 6600 and maybe other RDNA2 or older:
ENV HSA_OVERRIDE_GFX_VERSION=10.3.0
#ENV PYTORCH_ROCM_ARCH=gfx1030

# For AMD 7600 and maybe other RDNA3 cards: 
#ENV HSA_OVERRIDE_GFX_VERSION=11.0.0
#ENV PYTORCH_ROCM_ARCH=gfx1100

WORKDIR /
COPY scripts/entrypoint.sh .
RUN chmod +x /entrypoint.sh
WORKDIR /app
ENTRYPOINT ["/entrypoint.sh"]
FROM chirvo/pytorch-rocm-jammy:latest

WORKDIR /
COPY scripts/entrypoint.sh .
RUN chmod +x /entrypoint.sh
WORKDIR /app
ENTRYPOINT ["/entrypoint.sh"]
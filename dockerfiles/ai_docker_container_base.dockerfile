FROM pytorch2_rocm5_jammy:latest

WORKDIR /opt
COPY scripts/entrypoint.sh .
RUN chmod +x entrypoint.sh
ENTRYPOINT ["entrypoint.sh"]
FROM pytorch2_rocm5_jammy:latest

COPY bin/entrypoint.sh /opt
RUN chmod +x /opt/entrypoint.sh
ENTRYPOINT ["/opt/entrypoint.sh"]
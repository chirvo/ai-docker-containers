FROM pytorch2_rocm5_jammy:latest

EXPOSE $PORT/tcp
WORKDIR /
COPY ./bin/entrypoint.sh /
RUN chmod +x /entrypoint.sh
ENTRYPOINT [ "/entrypoint.sh", "a1111" ]

RUN git clone $REPO
WORKDIR /$WORKDIR
RUN sh -c "cat requirements.txt | grep -vw torch > /tmp/requirements.txt && mv /tmp/requirements.txt ./requirements.txt"
RUN git config --global --add safe.directory '*'
RUN pip3 install -r requirements.txt
CMD python3 launch.py --listen --enable-insecure-extension-access $PARAMS

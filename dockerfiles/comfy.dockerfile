FROM pytorch2_rocm5_jammy:latest

EXPOSE 8188/tcp
WORKDIR /opt
RUN git clone ${REPO}
WORKDIR /opt/${WORKDIR}
RUN git config --global --add safe.directory '*'
RUN sh -c "cat requirements.txt | grep -vw torch > /tmp/requirements.txt && mv /tmp/requirements.txt ./requirements.txt"
RUN pip3 install -r requirements.txt
CMD python3 main.py --listen ${PARAMS}
RUN 

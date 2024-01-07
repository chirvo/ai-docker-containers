FROM chirvo/pytorch:latest

ARG GIT_URI=https://github.com/AUTOMATIC1111/stable-diffusion-webui
ARG DEST_DIR=stable-diffusion-webui

WORKDIR /app

#Get the sources and copy them over the premounted volume
RUN git clone ${GIT_URI} ${DEST_DIR}.tmp
RUN cp -fnrv  ${DEST_DIR}.tmp ${DEST_DIR}
# RUN rsync -avP ${DEST_DIR}.tmp/ ${DEST_DIR}
# RUN rm -rf ${DEST_DIR}.tmp

#venv
RUN python3 -m venv venv --system-site-packages
ENV PATH=/app/venv:${PATH}
#reqs
WORKDIR /app/${DEST_DIR}
RUN pip3 install -r requirements.txt

EXPOSE 7860/tcp
CMD python3 launch.py --listen --enable-insecure-extension-access
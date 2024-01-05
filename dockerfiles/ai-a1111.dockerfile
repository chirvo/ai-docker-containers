FROM chirvo/base-pytorch:latest

ARG GIT_URI="https://github.com/AUTOMATIC1111/stable-diffusion-webui"
ARG DEST_DIR="stable-diffusion-webui"
WORKDIR /app

#Git clone
RUN git clone ${GIT_URI} ${DEST_DIR}.tmp \
  && cp -fnr ${DEST_DIR}.tmp ${DEST_DIR} \
  && rm -rf ${DEST_DIR}.tmp

#venv
RUN python3 -m venv venv --system-site-packages
ENV PATH="/app/venv:${PATH}"
#reqs
WORKDIR /app/${DEST_DIR}
RUN pip3 install -r requirements.txt

EXPOSE 7860/tcp
CMD python3 launch.py --listen --enable-insecure-extension-access
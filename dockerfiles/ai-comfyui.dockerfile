FROM chirvo/base-pytorch:latest

ARG GIT_URI="https://github.com/comfyanonymous/ComfyUI.git"
ARG DEST_DIR="ComfyUI"
WORKDIR /app

#Git clone
RUN git clone ${GIT_URI} ${DEST_DIR}.tmp \
  && cp -fnr ${DEST_DIR}.tmp ${DEST_DIR} \
  && rm -rf ${DEST_DIR}.tmp

#venv and reqs
RUN python3 -m venv venv --system-site-packages \
  && source ./venv/bin/activate \
  && cd ${DEST_DIR} \
  && pip3 install -r requirements.txt

EXPOSE 8188/tcp
CMD "python3 launch.py --listen"

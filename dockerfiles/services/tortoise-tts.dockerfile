FROM chirvo/pytorch:latest

ENV TORTOISE_MODELS_DIR="/models"

WORKDIR /app
RUN apt install -y rocm-hip-sdk
RUN git clone https://github.com/neonbjb/tortoise-tts.git /tmp/tortoise-tts
RUN cp -a /tmp/tortoise-tts /app
RUN rm -r /tmp/tortoise-tts
RUN pip3 install -r requirements.txt
RUN python3 -m pip install -r ./requirements.txt
RUN python3 setup.py install

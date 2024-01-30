FROM chirvo/pytorch:latest

RUN git clone https://github.com/AUTOMATIC1111/stable-diffusion-webui.git /app
WORKDIR /app
RUN pip3 install -r requirements.txt

EXPOSE 7860/tcp
CMD python3 launch.py --listen --precision full --no-half --enable-insecure-extension-access
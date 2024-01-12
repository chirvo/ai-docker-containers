FROM chirvo/pytorch:latest

WORKDIR /app

#Get the sources and copy them over the premounted volume
RUN git clone https://github.com/AUTOMATIC1111/stable-diffusion-webui.git /tmp/a1111
RUN cp -a /tmp/a1111 /app/a1111

WORKDIR /app/a1111
RUN pip3 install -r requirements.txt

EXPOSE 7860/tcp
CMD python3 launch.py --listen --precision full --no-half --enable-insecure-extension-access
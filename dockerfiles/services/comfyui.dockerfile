FROM chirvo/pytorch:latest


RUN git clone https://github.com/comfyanonymous/ComfyUI.git /app
WORKDIR /app
RUN pip3 install -r requirements.txt

EXPOSE 8188/tcp
CMD python3 launch.py --listen

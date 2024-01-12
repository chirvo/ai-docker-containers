FROM chirvo/pytorch:latest

WORKDIR /app

RUN git clone https://github.com/comfyanonymous/ComfyUI.git comfyui
WORKDIR /app/comfyui
RUN pip3 install -r requirements.txt

EXPOSE 8188/tcp
CMD python3 launch.py --listen

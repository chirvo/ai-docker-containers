FROM chirvo/pytorch_rocm:latest

RUN mkdir -p ~/.config/pip
RUN echo "[global]" >> ~/.config/pip/pip.conf
RUN echo "break-system-packages = true" >> ~/.config/pip/pip.conf
RUN git clone https://github.com/lllyasviel/stable-diffusion-webui-forge.git /app
WORKDIR /app
# RUN pip3 install --break-system-packages -r requirements.txt

# For 6700, 6600 and maybe other RDNA2 or older:
#ENV HSA_OVERRIDE_GFX_VERSION=10.3.0D
# For AMD 7600 and maybe other RDNA3 cards:
#ENV HSA_OVERRIDE_GFX_VERSION=11.0.0
EXPOSE 7860/tcp
CMD python3 launch.py --listen --precision full --no-half --enable-insecure-extension-access --skip-python-version-check
# CMD /app/webui.sh -f

FROM chirvo/rocm:latest

RUN pip3 install --pre torch torchvision torchaudio --index-url https://download.pytorch.org/whl/rocm5.6
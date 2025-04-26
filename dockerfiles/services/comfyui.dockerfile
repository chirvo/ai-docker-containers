FROM chirvo/base/ubuntu_rocm_pytorch:latest AS base

ARG COMFYUI_RELEASE="v0.3.27" \
    COMFYUI_PARAMS="--use-pytorch-cross-attention --reserve-vram 4"

ENV GRADIO_ANALYTICS_ENABLED=FALSE

RUN <<EOF
set -e
# Install required packages not listed in requirements.txt
uv pip install --upgrade 'optree>=0.13.0'
uv pip install onnx boto3 imageio-ffmpeg setuptools simpleeval
uv pip install insightface
EOF
# Clone ComfyUI-Manager and install its dependencies
RUN <<EOF
set -e
git clone --depth 1 https://github.com/comfyanonymous/ComfyUI.git /app
cd /app
# git checkout --detach tags/${COMFYUI_RELEASE}
uv pip install -r requirements.txt
cd /app/custom_nodes
git clone https://github.com/ltdrdata/ComfyUI-Manager.git comfyui-manager
uv pip install -r comfyui-manager/requirements.txt
EOF

FROM base AS final
# Create the entrypoint script and set it as the default command
WORKDIR /
RUN <<EOF
set -e
# Create the entrypoint script
cat <<EOS > entrypoint.sh 
#!/bin/bash
if  [ ! -e '/.REQUIREMENTS_SATISFIED' ]; then
    find /app/custom_nodes -maxdepth 2 -type f -name 'requirements.txt' -exec pip install -r {} \\;
    touch /.REQUIREMENTS_SATISFIED
fi

cd /app
LD_PRELOAD=libtcmalloc_minimal.so.4 python main.py --listen ${COMFYUI_PARAMS} \$@
EOS
chmod +x entrypoint.sh
cat <<EOS > /app/custom_nodes/amd_go_fast.py
import torch
# Taken from https://github.com/Beinsezii/comfyui-amd-go-fast
if "AMD" in torch.cuda.get_device_name() or "Radeon" in torch.cuda.get_device_name():
    try:
        from flash_attn import flash_attn_func

        sdpa = torch.nn.functional.scaled_dot_product_attention

        def sdpa_hijack(query, key, value, attn_mask=None, dropout_p=0.0, is_causal=False, scale=None):
            if query.shape[3] <= 128 and attn_mask is None and query.dtype != torch.float32:
                hidden_states = flash_attn_func(
                    q=query.transpose(1, 2),
                    k=key.transpose(1, 2),
                    v=value.transpose(1, 2),
                    dropout_p=dropout_p,
                    causal=is_causal,
                    softmax_scale=scale,
                ).transpose(1, 2)
            else:
                hidden_states = sdpa(
                    query=query,
                    key=key,
                    value=value,
                    attn_mask=attn_mask,
                    dropout_p=dropout_p,
                    is_causal=is_causal,
                    scale=scale,
                )
            return hidden_states

        torch.nn.functional.scaled_dot_product_attention = sdpa_hijack
        print("###\nSuccess: Flash attention for AMD enabled\n###")
    except ImportError as e:
        print(f"###\nError: Flash attention for AMD NOT enabled\n{e}\n###")
else:
    print(f"###\nFlash attention for AMD NOT enabled\nCould not detect AMD GPU from:\n{torch.cuda.get_device_name()}\n###")

NODE_CLASS_MAPPINGS = {}
NODE_DISPLAY_NAME_MAPPINGS = {}
EOS
EOF

# Expose the ComfyUI port
EXPOSE 8188/tcp

ENTRYPOINT [ "/entrypoint.sh" ]
#WIP. Don't use this file yet.
FROM chirvo/base/ubuntu_rocm_pytorch:latest AS base

# Clone the Zonos repository
RUN git clone https://github.com/Zyphra/Zonos.git /app

# Set the working directory
WORKDIR /app

# Modify pyptroject.toml to remove unsupported dependencies
RUN <<EOF
mv pyproject.toml pyproject.toml.bak
cat pyproject.toml.bak | grep -v torch| sed -e 's/"causal-conv1d.*",//'> pyproject.toml 
EOF

# Install project dependencies
RUN uv pip install --system -e . && uv pip install --system -e .[compile]

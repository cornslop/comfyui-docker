# Use a stable CUDA base image
FROM nvidia/cuda:11.8-runtime-ubuntu22.04 AS base

LABEL description="ComfyUI Docker container with comprehensive node support"

ENV DEBIAN_FRONTEND=noninteractive
ENV TZ=UTC
ENV PYTHONUNBUFFERED=1

RUN ln -fs /usr/share/zoneinfo/Etc/UTC /etc/localtime && \
    apt-get update && apt-get install -y tzdata && \
    dpkg-reconfigure --frontend noninteractive tzdata

# Install system dependencies including Python
RUN apt-get update && apt-get install -y \
    python3 python3-dev python3-pip \
    git wget curl unzip ffmpeg libgl1 libglib2.0-0 \
    build-essential pkg-config cmake \
    && apt-get clean && rm -rf /var/lib/apt/lists/*

# Create python symlink
RUN ln -s /usr/bin/python3 /usr/bin/python

# Install PyTorch FIRST with exact versions (CUDA 11.8 compatible)
RUN pip install --no-cache-dir torch==2.1.0 torchvision==0.16.0 torchaudio==2.1.0 \
    --index-url https://download.pytorch.org/whl/cu118

RUN pip install --no-cache-dir \
    pyyaml \
    opencv-python-headless opencv-contrib-python \
    xformers insightface

RUN pip install --no-cache-dir \
    ultralytics trimesh

RUN pip install --no-cache-dir \
    einops \
    safetensors \
    kornia \
    spandrel \
    onnxruntime \
    timm

# Add these for better node compatibility
RUN pip install --no-cache-dir \
    accelerate \
    diffusers \
    transformers \
    controlnet-aux \
    scipy \
    scikit-image

RUN pip install --no-cache-dir \
    numba \
    blend-modes \
    librosa \
    soundfile

# ComfyUI stage
FROM base AS comfyui

WORKDIR /comfyui

# Clone and setup ComfyUI
RUN git clone https://github.com/comfyanonymous/ComfyUI /comfyui && \
    cd /comfyui && \
    # Remove torch dependencies from requirements to prevent upgrades
    sed -i '/torch/d' requirements.txt && \
    pip install --no-cache-dir -r requirements.txt

# Create workspace structure
RUN mkdir -p /workspace/{input,output,models,custom_nodes}

# Environment variables
ENV COMFYUI_PORT=8188
ENV COMFYUI_HOST=0.0.0.0
ENV AUTO_INSTALL_NODES=true
ENV COMFYUI_MODEL_PATH="/workspace/models"
ENV COMFYUI_PATH="/workspace/comfyui"

VOLUME /workspace

# Copy configuration and scripts
COPY custom-nodes.yml /custom-nodes.yml
COPY scripts/ /scripts/
RUN chmod +x /scripts/*.sh

EXPOSE 8188/tcp

HEALTHCHECK --interval=30s --timeout=10s CMD curl -f http://localhost:${COMFYUI_PORT}/

ENTRYPOINT ["/scripts/docker-entrypoint.sh"]
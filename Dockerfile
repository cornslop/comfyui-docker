# Use NVIDIA's pre-built PyTorch image with compatible CUDA versions
FROM pytorch/pytorch:2.0.1-cuda11.7-cudnn8-runtime AS base

LABEL description="ComfyUI Docker container with comprehensive node support"

ENV DEBIAN_FRONTEND=noninteractive
ENV TZ=UTC
ENV PYTHONUNBUFFERED=1

RUN ln -fs /usr/share/zoneinfo/Etc/UTC /etc/localtime && \
    apt-get update && apt-get install -y tzdata && \
    dpkg-reconfigure --frontend noninteractive tzdata

# Install system dependencies 
RUN apt-get update && apt-get install -y \
    git wget curl unzip ffmpeg libgl1 libglib2.0-0 \
    build-essential pkg-config cmake \
    && apt-get clean && rm -rf /var/lib/apt/lists/*

# Install core dependencies
RUN pip install --no-cache-dir \
    pyyaml \
    opencv-python-headless opencv-contrib-python \
    xformers insightface

RUN pip install --no-cache-dir \
    ultralytics trimesh

# ComfyUI stage
FROM base AS comfyui

WORKDIR /comfyui

# Clone and setup ComfyUI
RUN git clone https://github.com/comfyanonymous/ComfyUI /comfyui && \
    cd /comfyui && \
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
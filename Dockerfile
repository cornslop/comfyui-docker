FROM nvidia/cuda:12.1.1-runtime-ubuntu22.04

ENV DEBIAN_FRONTEND=noninteractive
ENV PYTHONUNBUFFERED=1

# Install system dependencies
RUN apt-get update && apt-get install -y \
    python3.10 python3.10-venv python3.10-dev python3-pip \
    git wget curl unzip ffmpeg libgl1 libglib2.0-0 \
    build-essential pkg-config \
    && apt-get clean && rm -rf /var/lib/apt/lists/*

RUN update-alternatives --install /usr/bin/python python /usr/bin/python3.10 1

WORKDIR /comfyui

# Clone ComfyUI
ARG COMFYUI_COMMIT=HEAD
RUN git clone https://github.com/comfyanonymous/ComfyUI /comfyui && \
    cd /comfyui && \
    git checkout ${COMFYUI_COMMIT} && \
    pip install --no-cache-dir -r requirements.txt

# Install PyTorch with pinned versions
RUN pip install --no-cache-dir torch==2.1.0 torchvision==0.16.0 torchaudio==2.1.0 --index-url https://download.pytorch.org/whl/cu121

# Fix huggingface_hub version AFTER ComfyUI installation
RUN pip install --no-cache-dir --upgrade "huggingface_hub>=0.24.6"

# Comprehensive custom node dependencies for production use
RUN pip install --no-cache-dir \
    opencv-python opencv-contrib-python \
    scipy scikit-image matplotlib pillow numba \
    segment-anything ultralytics transformers diffusers \
    insightface onnxruntime controlnet-aux \
    blend-modes dill omegaconf piexif lark \
    watchdog pyOpenSSL requests gitpython \
    ffmpeg-python librosa soundfile \
    face-recognition mediapipe albumentations \
    timm accelerate xformers \
    fastapi uvicorn websockets \
    clip-interrogator rembg[gpu]

# Create workspace structure
RUN mkdir -p /workspace/{input,output,models,custom_nodes}

# Environment variables
ENV COMFYUI_PORT=8188
ENV COMFYUI_HOST=0.0.0.0

VOLUME /workspace

# Copy configuration and scripts
COPY custom-nodes.yml /custom-nodes.yml
COPY scripts/ /scripts/
RUN chmod +x /scripts/*.sh

EXPOSE 8188/tcp

HEALTHCHECK --interval=30s --timeout=10s --retries=3 \
    CMD curl -f http://localhost:8188/ || exit 1

ENTRYPOINT ["/scripts/docker-entrypoint.sh"]
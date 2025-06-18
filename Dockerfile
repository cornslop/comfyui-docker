# Base stage with system dependencies
FROM nvidia/cuda:12.1.1-runtime-ubuntu22.04 AS base

LABEL description="ComfyUI Docker container with comprehensive node support"

ENV DEBIAN_FRONTEND=noninteractive
ENV PYTHONUNBUFFERED=1
ENV PIP_NO_CACHE_DIR=1
ENV PIP_DISABLE_PIP_VERSION_CHECK=1

# Install system dependencies
RUN apt-get update && apt-get install -y \
    python3.10 \
    python3.10-venv \
    python3.10-dev \
    python3-pip \
    git \
    wget \
    curl \
    unzip \
    ffmpeg \
    libgl1 \
    libglib2.0-0 \
    build-essential \
    pkg-config \
    ca-certificates \
    cmake \
    libopenblas-dev \
    liblapack-dev \
    && apt-get clean && rm -rf /var/lib/apt/lists/*

RUN update-alternatives --install /usr/bin/python python /usr/bin/python3.10 1

# Dependencies stage
FROM base AS dependencies

# Install PyTorch
RUN pip install --no-cache-dir --force-reinstall \
    torch==2.1.0+cu121 \
    torchvision==0.16.0+cu121 \
    torchaudio==2.1.0+cu121 \
    --index-url https://download.pytorch.org/whl/cu121

# Core dependencies
RUN pip install --no-cache-dir \
    pyyaml \
    huggingface_hub \
    opencv-python \
    opencv-contrib-python \
    scipy \
    scikit-image \
    matplotlib \
    pillow \
    numba

# Utility dependencies
RUN pip install --no-cache-dir \
    blend-modes \
    dill \
    omegaconf \
    piexif \
    lark \
    watchdog \
    pyOpenSSL \
    requests \
    gitpython \
    ffmpeg-python \
    librosa \
    soundfile \
    wget \
    openai

# AI/ML dependencies
RUN pip install --no-cache-dir \
    transformers \
    diffusers \
    onnxruntime-gpu \
    segment-anything \
    controlnet-aux \
    insightface \
    dlib==19.24.2 \
    face-recognition

# ComfyUI stage
FROM dependencies AS comfyui

WORKDIR /comfyui

# Clone and setup ComfyUI
ARG COMFYUI_COMMIT=HEAD
RUN git clone https://github.com/comfyanonymous/ComfyUI /comfyui && \
    cd /comfyui && \
    if [ "${COMFYUI_COMMIT}" != "HEAD" ]; then git checkout ${COMFYUI_COMMIT}; fi && \
    pip install --no-cache-dir -r requirements.txt

# Production stage
FROM comfyui AS production

# Optional advanced packages (ONLY HERE, NOT IN DEPENDENCIES STAGE)
RUN pip install --no-cache-dir \
    timm \
    accelerate \
    xformers \
    || echo "⚠️  Some optional packages failed to install"

RUN pip install --no-cache-dir clip-interrogator || echo "⚠️  clip-interrogator failed to install"

# Create workspace structure
RUN mkdir -p /workspace/{input,output,models,custom_nodes}

# Environment variables
ENV COMFYUI_PORT=8188
ENV COMFYUI_HOST=0.0.0.0
ENV AUTO_INSTALL_NODES=true

VOLUME /workspace

# Copy configuration and scripts
COPY custom-nodes.yml /custom-nodes.yml
COPY scripts/ /scripts/
RUN chmod +x /scripts/*.sh

EXPOSE 8188/tcp

# Enhanced health check
HEALTHCHECK --interval=30s --timeout=10s --start-period=60s --retries=3 \
    CMD curl -f http://localhost:${COMFYUI_PORT}/ || exit 1

ENTRYPOINT ["/scripts/docker-entrypoint.sh"]
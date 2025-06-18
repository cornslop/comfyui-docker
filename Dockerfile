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
    && apt-get clean && rm -rf /var/lib/apt/lists/*

RUN update-alternatives --install /usr/bin/python python /usr/bin/python3.10 1

# Dependencies stage
FROM base AS dependencies

# Install PyTorch with exact versions for reproducibility
RUN pip install --no-cache-dir \
    torch==2.1.0 \
    torchvision==0.16.0 \
    torchaudio==2.1.0 \
    --index-url https://download.pytorch.org/whl/cu121

# Core dependencies
RUN pip install --no-cache-dir \
    pyyaml==6.0.1 \
    huggingface_hub==0.24.6 \
    opencv-python==4.8.1.78 \
    opencv-contrib-python==4.8.1.78 \
    scipy==1.11.4 \
    scikit-image==0.22.0 \
    matplotlib==3.8.2 \
    pillow==10.1.0 \
    numba==0.58.1

# Utility dependencies
RUN pip install --no-cache-dir \
    blend-modes==2.1.0 \
    dill==0.3.7 \
    omegaconf==2.3.0 \
    piexif==1.1.3 \
    lark==1.1.8 \
    watchdog==3.0.0 \
    pyOpenSSL==23.3.0 \
    requests==2.31.0 \
    gitpython==3.1.40 \
    ffmpeg-python==0.2.0 \
    librosa==0.10.1 \
    soundfile==0.12.1 \
    wget==3.2 \
    openai==1.88.0

# AI/ML dependencies
RUN pip install --no-cache-dir \
    transformers==4.36.0 \
    diffusers==0.25.0 \
    onnxruntime-gpu==1.16.3 \
    segment-anything==1.0 \
    controlnet-aux==0.0.7 \
    insightface==0.7.3 \
    face-recognition==1.3.0

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

# Optional advanced packages
RUN pip install --no-cache-dir \
    timm==0.9.12 \
    accelerate==0.25.0 \
    xformers==0.0.23 \
    || echo "⚠️  Some optional packages failed to install"

RUN pip install --no-cache-dir clip-interrogator==0.6.0 || echo "⚠️  clip-interrogator failed to install"

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
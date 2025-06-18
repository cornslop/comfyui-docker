# Base stage with system dependencies
FROM nvidia/cuda:12.1.1-runtime-ubuntu22.04 AS base

# Build metadata for reproducibility
LABEL maintainer="condawgng@gmail.com"
LABEL version="1.0.0"
LABEL description="ComfyUI Docker container with comprehensive node support"

ENV DEBIAN_FRONTEND=noninteractive
ENV PYTHONUNBUFFERED=1
ENV PIP_NO_CACHE_DIR=1
ENV PIP_DISABLE_PIP_VERSION_CHECK=1

RUN apt-get update && apt-get install -y \
    python3.10=3.10.12-1~22.04.3 \
    python3.10-venv=3.10.12-1~22.04.3 \
    python3.10-dev=3.10.12-1~22.04.3 \
    python3-pip=22.0.2+dfsg-1ubuntu0.4 \
    git=1:2.34.1-1ubuntu1.10 \
    wget=1.21.2-2ubuntu1 \
    curl=7.81.0-1ubuntu1.15 \
    unzip=6.0-26ubuntu3.1 \
    ffmpeg=7:4.4.2-0ubuntu0.22.04.1 \
    libgl1=1.4.0-1 \
    libglib2.0-0=2.72.4-0ubuntu2.2 \
    build-essential=12.9ubuntu3 \
    pkg-config=0.29.2-1ubuntu3 \
    ca-certificates=20230311ubuntu0.22.04.1 \
    && apt-get clean && rm -rf /var/lib/apt/lists/*

RUN update-alternatives --install /usr/bin/python python /usr/bin/python3.10 1

# Dependencies stage
FROM base AS dependencies

# Install PyTorch with exact versions for reproducibility
RUN pip install --no-cache-dir \
    torch==2.1.0+cu121 \
    torchvision==0.16.0+cu121 \
    torchaudio==2.1.0+cu121 \
    --index-url https://download.pytorch.org/whl/cu121

# Core dependencies with pinned versions
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

# AI/ML dependencies with pinned versions
RUN pip install --no-cache-dir \
    transformers==4.36.0 \
    diffusers==0.25.0 \
    onnxruntime-gpu==1.16.3 \
    segment-anything==1.0 \
    ultralytics==8.0.206 \
    controlnet-aux==0.0.7

# Utility dependencies with pinned versions
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
    soundfile==0.12.1

# ComfyUI stage
FROM dependencies AS comfyui

WORKDIR /comfyui

# Clone and setup ComfyUI with specific commit for reproducibility
ARG COMFYUI_COMMIT=HEAD
RUN git clone https://github.com/comfyanonymous/ComfyUI /comfyui && \
    cd /comfyui && \
    if [ "${COMFYUI_COMMIT}" != "HEAD" ]; then git checkout ${COMFYUI_COMMIT}; fi && \
    pip install --no-cache-dir -r requirements.txt

# Production stage
FROM comfyui AS production

# Optional advanced packages (install with error tolerance)
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
ENV PYTHONPATH=/workspace/comfyui:$PYTHONPATH

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
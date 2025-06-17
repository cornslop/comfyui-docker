FROM nvidia/cuda:12.1.1-runtime-ubuntu22.04

ENV DEBIAN_FRONTEND=noninteractive
ENV PYTHONUNBUFFERED=1

# Install system dependencies with specific versions where possible
RUN apt-get update && apt-get install -y \
    python3.10 python3.10-venv python3.10-dev python3-pip \
    git wget curl unzip ffmpeg libgl1 libglib2.0-0 \
    build-essential pkg-config \
    && apt-get clean && rm -rf /var/lib/apt/lists/*

RUN update-alternatives --install /usr/bin/python python /usr/bin/python3.10 1

WORKDIR /comfyui

# Clone ComfyUI during build and install requirements
RUN git clone https://github.com/comfyanonymous/ComfyUI /comfyui && \
    cd /comfyui && \
    pip install --no-cache-dir -r requirements.txt

# Install PyTorch and other dependencies
RUN pip install --no-cache-dir torch==2.1.0 torchvision==0.16.0 torchaudio==2.1.0 --index-url https://download.pytorch.org/whl/cu121

# Create workspace dir for input/output and custom models
RUN mkdir -p /workspace/input /workspace/output /workspace/models

# Define volumes for persistent data
VOLUME /workspace

COPY docker-entrypoint.sh /docker-entrypoint.sh
RUN chmod +x /docker-entrypoint.sh

EXPOSE 8188/tcp

# Add healthcheck
HEALTHCHECK --interval=30s --timeout=10s --retries=3 \
    CMD curl -f http://localhost:8188/ || exit 1

ENTRYPOINT ["/docker-entrypoint.sh"]
CMD ["python", "-u", "main.py", "--listen", "0.0.0.0", "--port", "8188"]

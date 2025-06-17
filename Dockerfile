FROM nvidia/cuda:12.1.1-runtime-ubuntu22.04

# Set noninteractive mode for apt
ENV DEBIAN_FRONTEND=noninteractive

# Install system dependencies
RUN apt-get update && apt-get install -y \
    python3.10 python3.10-venv python3-pip \
    git wget curl unzip ffmpeg libgl1 libglib2.0-0 \
    && apt-get clean && rm -rf /var/lib/apt/lists/*

# Set python3.10 as default
RUN update-alternatives --install /usr/bin/python python /usr/bin/python3.10 1

# Install PyTorch with CUDA 12.1
RUN pip install --no-cache-dir \
    torch torchvision torchaudio --index-url https://download.pytorch.org/whl/cu121

# Create workspace dir
RUN mkdir -p /workspace

# Install ComfyUI dependencies
WORKDIR /workspace/ComfyUI
RUN pip install --no-cache-dir -r requirements.txt

# Copy entrypoint
COPY docker-entrypoint.sh /docker-entrypoint.sh
RUN chmod +x /docker-entrypoint.sh

# Expose port
EXPOSE 8188/tcp

# Entrypoint
CMD ["/docker-entrypoint.sh"]

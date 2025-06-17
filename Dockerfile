FROM nvidia/cuda:12.1.1-runtime-ubuntu22.04

# 1. Set noninteractive mode for apt
ENV DEBIAN_FRONTEND=noninteractive

# 2. Install system dependencies
RUN apt-get update && apt-get install -y \
    python3.10 python3.10-venv python3-pip \
    git wget curl unzip ffmpeg libgl1 libglib2.0-0 \
    && apt-get clean && rm -rf /var/lib/apt/lists/*

# 3. Set python3.10 as default
RUN update-alternatives --install /usr/bin/python python /usr/bin/python3.10 1

# 4. Install PyTorch with CUDA 12.1
RUN pip install --no-cache-dir \
    torch torchvision torchaudio --index-url https://download.pytorch.org/whl/cu121

# 5. Clone ComfyUI and validate
WORKDIR /workspace
RUN git clone https://github.com/comfyanonymous/ComfyUI.git && \
    test -f /workspace/ComfyUI/main.py || (echo "❌ ComfyUI clone failed." && exit 1)

# 6. Install ComfyUI dependencies
WORKDIR /workspace/ComfyUI
RUN pip install --no-cache-dir -r requirements.txt

# 7. Copy entrypoint
COPY docker-entrypoint.sh /docker-entrypoint.sh
RUN chmod +x /docker-entrypoint.sh

# 8. Expose port
EXPOSE 8188/tcp

# 9. Entrypoint
CMD ["/docker-entrypoint.sh"]

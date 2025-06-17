#!/bin/bash
set -e

# Clone ComfyUI into persistent /workspace ONLY if it doesn't already exist
if [ ! -f /workspace/ComfyUI/main.py ]; then
    echo "📦 Cloning ComfyUI into persistent volume..."
    git clone https://github.com/comfyanonymous/ComfyUI /workspace/ComfyUI
    cd /workspace/ComfyUI
    pip install -r requirements.txt
else
    echo "✅ ComfyUI already exists, skipping clone."
    cd /workspace/ComfyUI
fi

echo "🚀 Launching ComfyUI..."
exec python3 main.py
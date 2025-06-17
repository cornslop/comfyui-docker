#!/bin/bash
set -e

echo "🚀 Starting ComfyUI..."

# Custom node setup (add more below as needed)
NODES_DIR="/workspace/ComfyUI/custom_nodes"
mkdir -p "$NODES_DIR"

if [ ! -d "$NODES_DIR/ComfyUI-Manager" ]; then
  echo "📦 Installing ComfyUI-Manager..."
  git clone https://github.com/ltdrdata/ComfyUI-Manager "$NODES_DIR/ComfyUI-Manager"
fi

# Create log directory
mkdir -p /workspace/logs

# Start ComfyUI and stream logs
cd /workspace/ComfyUI
exec python3 main.py --listen 0.0.0.0 --port 8188 2>&1 | tee /workspace/logs/comfyui.log

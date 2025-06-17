#!/bin/bash

echo "🚀 Starting ComfyUI..."

# Optional: clone custom nodes
NODES_DIR="/workspace/ComfyUI/custom_nodes"
mkdir -p "$NODES_DIR"

# Example node setup (you can add more here)
if [ ! -d "$NODES_DIR/ComfyUI-Manager" ]; then
  git clone https://github.com/ltdrdata/ComfyUI-Manager "$NODES_DIR/ComfyUI-Manager"
fi

# Launch ComfyUI
cd /workspace/ComfyUI
python main.py --listen 0.0.0.0 --port 8188

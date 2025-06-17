#!/bin/bash
set -e

# Create required directories if they don't exist
mkdir -p /workspace/input
mkdir -p /workspace/output
mkdir -p /workspace/models

# Link directories if they don't exist in ComfyUI
if [ ! -L "/comfyui/input" ]; then
  ln -sf /workspace/input /comfyui/input
fi

if [ ! -L "/comfyui/output" ]; then
  ln -sf /workspace/output /comfyui/output
fi

# Link custom models directory if needed
if [ ! -L "/comfyui/models" ]; then
  # Create backup of original models if this is first run
  if [ ! -d "/workspace/models_backup" ] && [ -d "/comfyui/models" ]; then
    cp -r /comfyui/models /workspace/models_backup
  fi
  
  # If workspace models exists, use it, otherwise initialize from original
  if [ ! -d "/workspace/models" ] && [ -d "/comfyui/models" ]; then
    cp -r /comfyui/models /workspace/models
  fi
  
  # Replace models dir with symbolic link
  if [ -d "/comfyui/models" ]; then
    rm -rf /comfyui/models
  fi
  ln -sf /workspace/models /comfyui/models
fi

# Copy ComfyUI to workspace if it doesn't exist
if [ ! -d /workspace/ComfyUI ]; then
    echo "📦 Copying ComfyUI to workspace..."
    cp -r /comfyui /workspace/ComfyUI
else
    echo "✅ ComfyUI already exists in workspace."
fi

cd /workspace/ComfyUI
echo "🚀 Launching ComfyUI..."
exec python3 main.py
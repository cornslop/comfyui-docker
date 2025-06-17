#!/bin/bash
set -e

echo "🔧 Setting up ComfyUI workspace..."

# Create required directories if they don't exist
mkdir -p /workspace/input
mkdir -p /workspace/output
mkdir -p /workspace/models
mkdir -p /workspace/custom_nodes

# Copy ComfyUI to workspace if it doesn't exist (for persistence)
if [ ! -d "/workspace/comfyui" ]; then
  echo "📦 First run: Copying ComfyUI to persistent storage..."
  cp -r /comfyui /workspace/comfyui
  
  # Move original directories to workspace and create symlinks
  if [ -d "/workspace/comfyui/models" ]; then
    cp -r /workspace/comfyui/models/* /workspace/models/ 2>/dev/null || true
    rm -rf /workspace/comfyui/models
  fi
  
  if [ -d "/workspace/comfyui/custom_nodes" ]; then
    cp -r /workspace/comfyui/custom_nodes/* /workspace/custom_nodes/ 2>/dev/null || true
    rm -rf /workspace/comfyui/custom_nodes
  fi
else
  echo "✅ Using existing ComfyUI from persistent storage"
fi

# Create symlinks from ComfyUI directories to workspace
cd /workspace/comfyui

# Remove existing directories/symlinks and create fresh symlinks
for dir in input output models custom_nodes; do
  if [ -L "$dir" ] || [ -d "$dir" ]; then
    rm -rf "$dir"
  fi
  ln -sf "/workspace/$dir" "$dir"
  echo "🔗 Linked $dir to /workspace/$dir"
done

# Install custom nodes
if [ "${AUTO_INSTALL_NODES:-true}" = "true" ]; then
    /scripts/install-nodes.sh
fi

echo "🚀 Launching ComfyUI from persistent storage..."
exec python -u main.py --listen ${COMFYUI_HOST:-0.0.0.0} --port ${COMFYUI_PORT:-8188}
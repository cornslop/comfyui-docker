#!/bin/bash
set -euo pipefail

echo "🔧 Setting up ComfyUI workspace..."

# Validate environment
if [ ! -d "/comfyui" ]; then
    echo "❌ ComfyUI base installation not found!"
    exit 1
fi

# Set environment variables for ComfyUI Manager
export COMFYUI_MODEL_PATH="/workspace/models"
export COMFYUI_PATH="/workspace/comfyui"

# Create required directories if they don't exist
mkdir -p /workspace/{input,output,models,custom_nodes}

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

# Configure WAS Node Suite ffmpeg path
find /workspace/comfyui/custom_nodes -name "was_suite_config.json" -exec \
  sed -i 's|"ffmpeg_bin_path": ""|"ffmpeg_bin_path": "/usr/bin/ffmpeg"|g' {} \;
echo "🎬 Configured ffmpeg path in WAS Node Suite config"

# Install custom nodes
if [ "${AUTO_INSTALL_NODES:-true}" = "true" ]; then
    echo "🔌 Installing custom nodes..."
    /scripts/install-nodes.sh || {
        echo "⚠️ Custom node installation failed, continuing anyway..."
    }
fi

echo "🚀 Launching ComfyUI from persistent storage..."
cd /workspace/comfyui
exec python -u main.py --listen "${COMFYUI_HOST:-0.0.0.0}" --port "${COMFYUI_PORT:-8188}"
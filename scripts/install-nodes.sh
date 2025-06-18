#!/bin/bash
set -euo pipefail

CONFIG_FILE="/custom-nodes.yml"
CUSTOM_NODES_DIR="/workspace/custom_nodes"

# Validate prerequisites
if [ ! -f "$CONFIG_FILE" ]; then
    echo "❌ Configuration file $CONFIG_FILE not found!"
    exit 1
fi

if ! command -v python3 &> /dev/null; then
    echo "❌ Python3 not found!"
    exit 1
fi

# Function to parse YAML and install nodes
install_node_group() {
    local group="$1"
    echo "📦 Installing node group: $group"
    
    python3 << EOF
import yaml
import subprocess
import os
import sys

try:
    with open('$CONFIG_FILE', 'r') as f:
        config = yaml.safe_load(f)
except Exception as e:
    print(f"❌ Failed to parse YAML config: {e}")
    sys.exit(1)

if '$group' in config and config['$group']:
    for node in config['$group']:
        try:
            node_name = node['name']
            node_url = node['url']
            commit = node.get('commit', 'HEAD')
            node_path = os.path.join('$CUSTOM_NODES_DIR', node_name)
            
            if not os.path.exists(node_path):
                print(f"Installing {node_name}...")
                os.makedirs('$CUSTOM_NODES_DIR', exist_ok=True)
                
                # Clone with error handling
                result = subprocess.run(['git', 'clone', node_url, node_path], 
                                      capture_output=True, text=True)
                if result.returncode != 0:
                    print(f"❌ Failed to clone {node_name}: {result.stderr}")
                    continue
                
                # Checkout specific commit
                if commit != 'HEAD':
                    result = subprocess.run(['git', 'checkout', commit], 
                                          cwd=node_path, capture_output=True, text=True)
                    if result.returncode != 0:
                        print(f"⚠️  Failed to checkout {commit} for {node_name}")
                
                # Install requirements if present
                req_file = os.path.join(node_path, 'requirements.txt')
                if os.path.exists(req_file):
                    print(f"📋 Installing requirements for {node_name}")
                    result = subprocess.run(['pip', 'install', '--no-cache-dir', '-r', req_file],
                                          capture_output=True, text=True)
                    if result.returncode != 0:
                        print(f"⚠️  Failed to install requirements for {node_name}: {result.stderr}")
                
                print(f"✅ {node_name} installed successfully")
            else:
                print(f"⏭️  {node_name} already exists")
        except Exception as e:
            print(f"❌ Error processing node {node.get('name', 'unknown')}: {e}")
            continue
EOF
}

# Install auto-install groups with error handling
echo "🔍 Reading configuration..."
auto_groups=$(python3 -c "
import yaml
import sys
try:
    with open('$CONFIG_FILE', 'r') as f:
        config = yaml.safe_load(f)
    groups = config.get('config', {}).get('auto_install_groups', [])
    print(' '.join(groups))
except Exception as e:
    print(f'Error reading config: {e}', file=sys.stderr)
    sys.exit(1)
" 2>/dev/null) || {
    echo "❌ Failed to read auto-install groups from config"
    exit 1
}

if [ -z "$auto_groups" ]; then
    echo "ℹ️  No auto-install groups configured"
    exit 0
fi

# Parse and install each auto-install group
for group in $auto_groups; do
    echo "🎯 Processing group: $group"
    install_node_group "$group" || {
        echo "⚠️  Failed to install group $group, continuing..."
    }
done

echo "✅ Custom node installation completed!"
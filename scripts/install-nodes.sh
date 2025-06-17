#!/bin/bash
set -e

CONFIG_FILE="/custom-nodes.yml"
CUSTOM_NODES_DIR="/workspace/custom_nodes"

# Function to parse YAML and install nodes
install_node_group() {
    local group="$1"
    echo "📦 Installing node group: $group"
    
    # Use yq or simple parsing for YAML (install yq in Dockerfile if needed)
    # For now, using a simple approach
    python3 << EOF
import yaml
import subprocess
import os

with open('$CONFIG_FILE', 'r') as f:
    config = yaml.safe_load(f)

if '$group' in config and config['$group']:
    for node in config['$group']:
        node_name = node['name']
        node_url = node['url']
        commit = node.get('commit', 'HEAD')
        node_path = os.path.join('$CUSTOM_NODES_DIR', node_name)
        
        if not os.path.exists(node_path):
            print(f"Installing {node_name}...")
            os.makedirs('$CUSTOM_NODES_DIR', exist_ok=True)  # Add this line
            subprocess.run(['git', 'clone', node_url, node_path])  # Remove cwd parameter
            subprocess.run(['git', 'checkout', commit], cwd=node_path)
            
            # Install requirements if present
            req_file = os.path.join(node_path, 'requirements.txt')
            if os.path.exists(req_file):
                subprocess.run(['pip', 'install', '--no-cache-dir', '-r', req_file])
            
            print(f"✅ {node_name} installed")
        else:
            print(f"⏭️  {node_name} already exists")
EOF
}

# Install auto-install groups
python3 << EOF
import yaml
with open('$CONFIG_FILE', 'r') as f:
    config = yaml.safe_load(f)
    
auto_groups = config.get('config', {}).get('auto_install_groups', [])
for group in auto_groups:
    print(f"Auto-installing group: {group}")
EOF

# Parse and install each auto-install group
for group in $(python3 -c "
import yaml
with open('$CONFIG_FILE', 'r') as f:
    config = yaml.safe_load(f)
print(' '.join(config.get('config', {}).get('auto_install_groups', [])))
"); do
    install_node_group "$group"
done
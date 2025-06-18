# ComfyUI Docker

Production-ready ComfyUI Docker container optimized for RunPod deployment with comprehensive custom node support.

## Features

- 🐳 Multi-stage Docker build for optimal layer caching
- 🔌 Automatic custom node installation via YAML configuration
- 💾 Persistent storage support for RunPod
- 🎯 90%+ custom node compatibility out of the box
- 🚀 Fast startup times with pre-installed dependencies
- 🔄 CI/CD ready with GitHub Actions

## Quick Start

### RunPod Deployment
```bash
docker run -p 8188:8188 -v /workspace:/workspace ghcr.io/cornslop/comfyui-docker:latest
```

### Local Development
```bash
docker-compose up
```

## Configuration

Edit `custom-nodes.yml` to customize which nodes are automatically installed:

```yaml
essential:
  - name: "ComfyUI-Manager"
    url: "https://github.com/ltdrdata/ComfyUI-Manager.git"
    commit: "main"

config:
  auto_install_groups: ["essential"]
```

## Environment Variables

- `COMFYUI_PORT` - Port to run ComfyUI on (default: 8188)
- `COMFYUI_HOST` - Host to bind to (default: 0.0.0.0)
- `AUTO_INSTALL_NODES` - Whether to auto-install custom nodes (default: true)

## Building

```bash
docker build -t comfyui-docker .
```

## License

MIT License
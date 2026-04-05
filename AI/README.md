# Local AI Stack

This folder contains the local AI runtime for Ollama on Ubuntu with NVIDIA GPU support.

## Table of Contents

- [Folder Contents](#folder-contents)
- [Quick Start](#quick-start)
- [Commands](#commands)
- [Current Configuration](#current-configuration)
- [Model Strategy](#model-strategy)
- [Performance Tips](#performance-tips)
- [Troubleshooting](#troubleshooting)

## Folder Contents

- `ai_manager.sh`: helper script for start, stop, status, and model setup
- `docker-compose.yml`: Ollama container definition
- `config.yml`: current local configuration snapshot

## Quick Start

Run from the project root:

```bash
chmod +x AI/ai_manager.sh
./AI/ai_manager.sh up
./AI/ai_manager.sh setup-models
./AI/ai_manager.sh status
```

Stop the stack:

```bash
./AI/ai_manager.sh down
```

## Commands

- `up`: starts the Ollama container
- `setup-models`: downloads selected model set
- `status`: shows container status and loaded models
- `down`: stops the container

## Current Configuration

The active snapshot is stored in `config.yml`:

```yaml
profile: current
runtime:
  composeFile: ./docker-compose.yml
  dataDir: ../ollama_data
  endpoint: http://localhost:11434
  containerName: ollama
host:
  os: ubuntu-24.x
  gpu: nvidia
  vram: 8GB
models:
  chat:
    - mistral-nemo
    - codestral:22b-v0.1-q4_K_M
  autocomplete:
    - starcoder2:3b
    - qwen2.5-coder:1.5b
  embedding:
    - nomic-embed-text
```

## Model Strategy

- Chat/Reasoning: `mistral-nemo`, `codestral:22b-v0.1-q4_K_M`
- Fast autocomplete: `starcoder2:3b`, `qwen2.5-coder:1.5b`
- Embeddings for codebase search: `nomic-embed-text`

## Performance Tips

- Keep inline suggestion delays at 0 in VS Code for faster feedback.
- Use smaller models for autocomplete and apply operations.
- Monitor VRAM with `watch -n 1 nvidia-smi`.

## Troubleshooting

- If `docker exec` fails, run `./AI/ai_manager.sh up` first.
- If the container is up but the model list is empty, rerun `./AI/ai_manager.sh setup-models`.
- If you run out of space, check and clean old data from `ollama_data` only after backing up needed models.

# Local AI Stack

This folder contains the local AI runtime for Ollama on Ubuntu with NVIDIA GPU support.

## Table of Contents

- [Folder Contents](#folder-contents)
- [Quick Start](#quick-start)
- [Commands](#commands)
- [Current Configuration](#current-configuration)
- [Model Strategy](#model-strategy)
- [Removing Models](#removing-models)
- [Prune Safety](#prune-safety)
- [Performance Tips](#performance-tips)
- [Troubleshooting](#troubleshooting)

## Folder Contents

- `ai_manager.sh`: helper script for start, stop, status, and model setup
- `docker-compose.yml`: Ollama container definition
- `config.yml`: Continue configuration for VS Code

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

Continue in VS Code uses `config.yml` in this folder. The current configuration is:

```yaml
name: Local Config
version: 1.0.0
schema: v1
models:
  - name: Mistral Nemo
    provider: ollama
    model: mistral-nemo:latest
    roles:
      - chat
  - name: Codestral
    provider: ollama
    model: codestral:22b-v0.1-q4_K_M
    roles:
      - chat
  - name: Mistral Small
    provider: ollama
    model: mistral-small:24b
    roles:
      - chat
  - name: Qwen Autocomplete
    provider: ollama
    model: qwen2.5-coder:1.5b
    roles:
      - autocomplete
      - chat
      - apply
```

## Model Strategy

- Chat/Reasoning: `mistral-nemo:latest`, `codestral:22b-v0.1-q4_K_M`, `mistral-small:24b`
- Fast autocomplete and apply: `qwen2.5-coder:1.5b`
- Embeddings for codebase search: `nomic-embed-text`

## Continue Setup

This folder is meant to be used with the Continue extension in VS Code.

Point Continue at this `AI/config.yml` file, then reload VS Code so the model list is picked up.

The important model roles are:

- `chat`: general conversation and reasoning
- `autocomplete`: inline code completion
- `apply`: file-editing and patch application

If Continue asks for the config file location, use `AI/config.yml` from this folder.

## Removing Models

`starcoder2` is a model, not a container. To remove it from Ollama, run:

```bash
docker exec ollama ollama rm starcoder2:3b
```

If you want to remove any other model later, use the same pattern with the model name you pulled.

If you meant the Ollama container itself, remove it with:

```bash
docker compose -f AI/docker-compose.yml down
```

Or, if it is already stopped and you want to delete it directly:

```bash
docker rm -f ollama
```

## Prune Safety

There is no native Docker "lock" button for a container or image. The practical protections are:

- Keep `ollama` running while you do not want it removed.
- Keep model data in the bind mount `../ollama_data`, not in a disposable Docker volume.
- Do not run `docker system prune --all --volumes` unless you understand exactly what will be removed.

What is safe:

- Running containers are not removed by normal prune operations.
- The bind-mounted `ollama_data` folder is not deleted by Docker prune.

What still needs care:

- If you stop and remove the container, it can be pruned like any other unused container.
- If you delete `ollama_data`, you delete the models themselves.

Best practice:

1. Keep the AI stack in the `AI/` folder.
2. Keep model data in `ollama_data/`.
3. Back up `ollama_data/` before cleanup or migration.
4. Avoid prune commands unless you are cleaning intentionally.

## Performance Tips

- Keep inline suggestion delays at 0 in VS Code for faster feedback.
- Use smaller models for autocomplete and apply operations.
- Monitor VRAM with `watch -n 1 nvidia-smi`.

## Troubleshooting

- If `docker exec` fails, run `./AI/ai_manager.sh up` first.
- If the container is up but the model list is empty, rerun `./AI/ai_manager.sh setup-models`.
- If you run out of space, check and clean old data from `ollama_data` only after backing up needed models.

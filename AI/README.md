# Local AI Stack

This folder runs Ollama in Docker with model data persisted on disk.

It supports:

- normal online setup
- repeated offline usage after assets are prepared
- transferring runtime + model data through external storage

## Table of Contents

- [Local AI Stack](#local-ai-stack)
  - [Table of Contents](#table-of-contents)
  - [What This Is For](#what-this-is-for)
  - [Folder Contents](#folder-contents)
  - [Requirements](#requirements)
    - [Online preparation machine (one-time)](#online-preparation-machine-one-time)
    - [Offline target machine (disk-only runtime)](#offline-target-machine-disk-only-runtime)
  - [Quick Start (Online)](#quick-start-online)
  - [Pure Disk Workflow (Online Machine -\> Offline Machine)](#pure-disk-workflow-online-machine---offline-machine)
    - [1) Prepare assets on a machine with internet](#1-prepare-assets-on-a-machine-with-internet)
    - [2) Copy to external disk](#2-copy-to-external-disk)
    - [3) Bring up on offline machine](#3-bring-up-on-offline-machine)
  - [Restore After Deletion](#restore-after-deletion)
  - [What Must Exist For Pure Disk-Only Use](#what-must-exist-for-pure-disk-only-use)
  - [Command Reference](#command-reference)
  - [Current Continue Configuration](#current-continue-configuration)
  - [Model Strategy](#model-strategy)
  - [Prune Safety](#prune-safety)
  - [Troubleshooting](#troubleshooting)

## What This Is For

Use this stack when you want local AI coding models without depending on cloud inference.

Important limitation:

- A fully blank machine with no internet cannot bootstrap everything automatically.
- You must prepare runtime/model assets in advance or import them from disk.
- The host needs enough free space on Docker's data-root to export the runtime image; an external archive path alone is not enough.

## Folder Contents

- `ai_manager.sh`: helper script for setup, startup, shutdown, and offline checks
- `docker-compose.yml`: Ollama container definition
- `config.yml`: Continue configuration for VS Code

## Requirements

### Online preparation machine (one-time)

- Linux host (tested with Ubuntu-like workflow)
- Docker Engine installed and running
- Docker Compose plugin (`docker compose`)
- Internet access (to pull runtime image and models)
- NVIDIA GPU drivers + NVIDIA Container Toolkit (for GPU mode)

### Offline target machine (disk-only runtime)

- Working Ubuntu installation already booted and usable
- Docker Engine installed and running, or installable from the offline bundle
- Docker Compose plugin installed, or installable from the offline bundle
- NVIDIA GPU drivers + NVIDIA Container Toolkit installed (for GPU mode)
- This project folder copied with `AI/` and `ollama_data/` kept as siblings
- Ollama runtime image already loaded locally OR a runtime image tar to import
- Model files already present in `ollama_data/`
- Enough free space on the host disk that Docker uses for image export and temporary files

## Quick Start (Online)

Run from the repository root:

```bash
chmod +x AI/ai_manager.sh
./AI/ai_manager.sh download-all
./AI/ai_manager.sh offline-check
./AI/ai_manager.sh up
./AI/ai_manager.sh status
```

Use `download-all` when you want to prepare the current PC.
Use `bundle-all` or `archive-only` when you want a portable archive for later no-internet use.

If you want one command that both downloads and archives the full offline AI stack, use:

```bash
./AI/ai_manager.sh bundle-all /path/to/external-disk/localai-ai-offline.tar.zst
```

You can also point `bundle-all`, `archive-only`, or `archive-runtime-only` at a directory; the script will place the default archive filename inside that directory.

Vault-style interactive mode (asks for archive path, temp directory, and cleanup choice):

```bash
./AI/ai_manager.sh bundle-all
```

If the target archive already exists, the script asks whether to skip or overwrite.
If you choose skip, `bundle-all` exits before download work starts.

If the host disk is too small, `bundle-all` stops before downloading and tells you to free space or move Docker's data-root to a larger disk.

That command does three things:

1. Downloads the Ollama runtime image and the selected models into `ollama_data/`.
2. Exports the runtime image into the bundle as `ollama-runtime-image.tar`.
3. Creates one offline archive containing `AI/`, `ollama_data/`, and restore instructions.

Use `archive-runtime-only` if you only want a runtime image tar without the full offline bundle.

Stop the stack:

```bash
./AI/ai_manager.sh down
```

## Pure Disk Workflow (Online Machine -> Offline Machine)

For a later no-internet scenario, the important command is `bundle-all`.
It downloads everything needed and packages the offline AI stack into one archive.

Use `archive-only` only when the runtime image and model data already exist and you just want to repackage them.

### 1) Prepare assets on a machine with internet

```bash
chmod +x AI/ai_manager.sh
./AI/ai_manager.sh download-all
./AI/ai_manager.sh export-runtime /path/to/external-disk/ollama-runtime-image.tar
./AI/ai_manager.sh offline-check /path/to/external-disk/ollama-runtime-image.tar
```

If you prefer to download and archive in one step, replace the first two commands with:

```bash
./AI/ai_manager.sh bundle-all /path/to/external-disk/localai-ai-offline.tar.zst
```

Or run the interactive vault-style version (no arguments):

```bash
./AI/ai_manager.sh bundle-all
```

This gives you:

- a single full offline archive (`localai-ai-offline.tar.zst`) containing:
  - `AI/`
  - `ollama_data/`
  - `ollama-runtime-image.tar`
  - `RESTORE.txt`

That archive is the one you move to the target machine for later offline restoration.

Important:

- `bundle-all` needs enough free space on the host's Docker storage area to complete the runtime image export.
- If the host only has about 80 GB free, the full bundle may fail during `docker image save`.
- In that case, free space first or relocate Docker's data-root to a larger disk before trying again.

### 2) Copy to external disk

Copy the full offline archive file to external disk (for example `localai-ai-offline.tar.zst`).

### 3) Bring up on offline machine

On the offline machine (after Docker and GPU stack are installed):

```bash
mkdir -p /path/to/restore/LocalAI
tar --zstd -xf /path/to/external-disk/localai-ai-offline.tar.zst -C /path/to/restore/LocalAI
cd /path/to/restore/LocalAI/localai-ai-offline-*/
chmod +x AI/ai_manager.sh
./AI/ai_manager.sh import-runtime ./ollama-runtime-image.tar
./AI/ai_manager.sh offline-check ./ollama-runtime-image.tar
./AI/ai_manager.sh up
./AI/ai_manager.sh status
```

If `offline-check` reports READY, you can run fully from disk without internet.

## Restore After Deletion

If you delete Ollama and the model/runtime data from the PC itself, you can still restore the stack locally later as long as you kept the external archive and the machine still has a working Ubuntu installation.

If `bundle-all` failed due to low space, the archive was not created. You need to rerun it after freeing host space or moving Docker's storage to a larger disk.

Keep the full archive produced by `bundle-all` or `archive-only` on the external disk.

Restore steps on the same or another machine:

```bash
tar --zstd -xf /path/to/external-disk/localai-ai-offline.tar.zst -C /path/to/restore/LocalAI
cd /path/to/restore/LocalAI/localai-ai-offline-*/
chmod +x AI/ai_manager.sh
./AI/ai_manager.sh import-runtime ./ollama-runtime-image.tar
./AI/ai_manager.sh up
```

Because the archive already contains `ollama_data/`, models are restored from disk after extraction.

If you only need to create/update the full offline archive without downloading models again, use:

```bash
./AI/ai_manager.sh archive-only
```

If you need runtime tar only and do not want the full offline archive, use:

```bash
./AI/ai_manager.sh archive-runtime-only
```

These commands ask for:

1. Target archive path.
2. Temporary working directory on the PC.
3. Whether to delete the temporary working directory at the end.

Then, if needed:

```bash
./AI/ai_manager.sh status
./AI/ai_manager.sh offline-check ./ollama-runtime-image.tar
```

## What Must Exist For Pure Disk-Only Use

If any item below is missing, disk-only operation is not complete:

1. Docker Engine is installed and daemon is running.
2. Docker Compose plugin is installed.
3. NVIDIA drivers and NVIDIA Container Toolkit are installed (GPU mode).
4. `ollama/ollama:latest` is locally loaded in Docker, or importable from tar.
5. `ollama_data/models/blobs` contains model blobs.
6. Required model manifests exist:
   - `mistral-nemo:latest`
   - `codestral:22b-v0.1-q4_K_M`
   - `qwen2.5-coder:1.5b`
   - `nomic-embed-text:latest`

You can verify all of this with:

```bash
./AI/ai_manager.sh offline-check
```

## Command Reference

- `up`: start Ollama container
- `setup-models`: pull selected model set into `ollama_data/`
- `download-all`: pull runtime image plus selected model set
- `bundle-all [archive] [temp] [cleanup]`: download everything and create the portable offline archive for later no-internet use
- `archive-only [archive] [temp] [cleanup]`: create the portable offline archive only when the data already exists
- `archive-runtime-only [archive] [temp] [cleanup]`: archive runtime image only
- `export-runtime [archive-path]`: export `ollama/ollama:latest` to tar
- `import-runtime [archive-path]`: import runtime image tar
- `offline-check [archive-path]`: report missing requirements for disk-only use
- `status`: show container status and loaded models (if running)
- `down`: stop stack

Default runtime tar path if not specified:

- `ollama_data/ollama-runtime-image.tar`

Recommended one-command prep for a portable disk copy:

```bash
./AI/ai_manager.sh bundle-all /path/to/external-disk/localai-ai-offline.tar.zst
```

If you omit arguments for `bundle-all` or `archive-only`, the script will prompt you for target path, temp dir, and cleanup behavior.
That is the preferred path for the later no-internet scenario.

When the target archive path already exists, the script prompts for `skip` or `overwrite` (vault-style behavior).

## Current Continue Configuration

Continue in VS Code uses `config.yml` in this folder.

Point Continue to `AI/config.yml`, then reload VS Code.

The important roles are:

- `chat`: general conversation and reasoning
- `autocomplete`: inline code completion
- `apply`: file-editing and patch application

## Model Strategy

Pulled by `setup-models` / `download-all`:

- Chat/Reasoning: `mistral-nemo:latest`, `codestral:22b-v0.1-q4_K_M`
- Fast autocomplete and apply: `qwen2.5-coder:1.5b`
- Embeddings for codebase search: `nomic-embed-text:latest`

Optional larger model in `config.yml`:

- `mistral-small:24b` is listed in config but is not pulled by default script commands.
- Pull manually if needed:

```bash
docker exec ollama ollama pull mistral-small:24b
```

## Prune Safety

There is no native Docker lock flag for images/containers. Practical safety rules:

- Keep model data in bind mount `../ollama_data`.
- Avoid `docker system prune --all --volumes` unless intentional.
- Back up `ollama_data/` before cleanup or migration.

What prune can still remove:

- stopped containers
- unused images

What prune does not remove:

- bind-mounted host data inside `ollama_data/`

## Troubleshooting

- `offline-check` says runtime image missing:
  - import the tar: `./AI/ai_manager.sh import-runtime /path/to/ollama-runtime-image.tar`
- `offline-check` says model manifests missing:
  - run online once: `./AI/ai_manager.sh setup-models`
- `status` shows container not running:
  - start: `./AI/ai_manager.sh up`
- GPU not available in container:
  - verify host GPU stack: `nvidia-smi`
  - verify Docker GPU integration: install/configure NVIDIA Container Toolkit

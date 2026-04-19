# NoInternet Workspace

NoInternet is a two-part workspace:

- local AI runtime for coding and model experiments (Ollama on Docker)
- offline vault builder for preparing portable engineering resources

This repository is designed to support both online setup and offline operation.

## Table of Contents

- [NoInternet Workspace](#nointernet-workspace)
  - [Table of Contents](#table-of-contents)
  - [Project Goals](#project-goals)
  - [Repository Layout](#repository-layout)
  - [Quick Start](#quick-start)
    - [1) Local AI stack](#1-local-ai-stack)
    - [1b) Pre-download framework + models to disk](#1b-pre-download-framework--models-to-disk)
    - [2) Offline vault builder](#2-offline-vault-builder)
  - [Download Local AI Stack To Disk](#download-local-ai-stack-to-disk)
  - [Offline From Disk Requirements](#offline-from-disk-requirements)
  - [Component Guides](#component-guides)
  - [Storage and Data](#storage-and-data)
  - [Public Repository Notes](#public-repository-notes)
  - [Prune Safety](#prune-safety)
  - [Release Checklist](#release-checklist)

## Project Goals

- Run local LLM tooling on Ubuntu with NVIDIA GPU.
- Prepare an offline engineering vault for development without internet.
- Keep downloaded assets portable on USB or mounted storage.

## Repository Layout

```text
LocalAI/
  README.md
  AI/
    README.md
    ai_manager.sh
    docker-compose.yml
    config.yml
  Vault/
    README_vault.md
    vault_builder.sh
  ollama_data/
  tmp/
```

## Quick Start

### 1) Local AI stack

```bash
chmod +x AI/ai_manager.sh
./AI/ai_manager.sh up
./AI/ai_manager.sh setup-models
./AI/ai_manager.sh status
```

### 1b) Pre-download framework + models to disk

```bash
chmod +x AI/ai_manager.sh
./AI/ai_manager.sh download-all
./AI/ai_manager.sh export-runtime
./AI/ai_manager.sh bundle-all /path/to/external-disk/localai-ai-offline.tar.zst
./AI/ai_manager.sh offline-check
```

If you want the shortest path, use `bundle-all` by itself. It downloads the runtime image and models, then creates one full offline archive.

Vault-style interactive usage (prompts for target archive path, temp dir, and cleanup):

```bash
./AI/ai_manager.sh bundle-all
```

If the target archive already exists, the script asks whether to skip or overwrite.
Choosing skip prevents `bundle-all` from running downloads.

### 2) Offline vault builder

```bash
chmod +x Vault/vault_builder.sh
./Vault/vault_builder.sh
```

## Download Local AI Stack To Disk

You can pre-download the full Local AI software stack to disk, including both runtime framework and models:

```bash
./AI/ai_manager.sh download-all
./AI/ai_manager.sh export-runtime /path/to/external-disk/ollama-runtime-image.tar
./AI/ai_manager.sh bundle-all /path/to/external-disk/localai-ai-offline.tar.zst
./AI/ai_manager.sh offline-check
```

If you want a single command that both downloads and archives the full offline AI stack, use:

```bash
./AI/ai_manager.sh bundle-all /path/to/external-disk/localai-ai-offline.tar.zst
```

If you only want to archive the full stack without new downloads, use:

```bash
./AI/ai_manager.sh archive-only
```

If you only want runtime image tar (no full stack archive), use:

```bash
./AI/ai_manager.sh archive-runtime-only
```

`bundle-all` and `archive-only` produce a full offline archive containing `AI/`, `ollama_data/`, and `ollama-runtime-image.tar`.

Use `download-all` when you only want to populate the current PC.
Use `bundle-all` when you want a portable archive for a later no-internet restore.

What this downloads:

- Ollama runtime image (Docker local image cache)
- Local model set (stored in `ollama_data/`)
- Optional portable runtime tar via `export-runtime`
- Single-step full offline archive via `bundle-all`

This makes it possible to prepare the machine for offline use after the initial online download.

Important:

- The host needs enough free space on Docker's data-root to complete the full offline archive; an external archive destination does not remove that requirement.

## Offline From Disk Requirements

For pure disk-only operation, all of the following must already exist:

1. A working Ubuntu installation that already boots and runs normally.
2. Docker Engine installed and running.
3. Docker Compose plugin available.
4. NVIDIA driver + NVIDIA Container Toolkit installed (for GPU mode).
5. Ollama runtime image loaded locally (or importable from `ollama-runtime-image.tar`).
6. Model data in `ollama_data/`.
7. Required project layout kept intact (`AI/` and `ollama_data/` as sibling folders).

Use this command to verify readiness:

```bash
./AI/ai_manager.sh offline-check
```

If you delete Ollama or the models from the PC later, you can restore them locally again by keeping the external archive, keeping Ubuntu installed, extracting the full archive, and running `import-runtime` plus `up`.

In other words: `bundle-all` prepares the full offline archive, and `import-runtime` restores the runtime image after extraction.

## Component Guides

- AI runtime guide: [AI/README.md](AI/README.md)
- Offline vault guide: [Vault/README_vault.md](Vault/README_vault.md)

## Storage and Data

- `ollama_data/` stores local Ollama models and metadata.
- `tmp/` is used for staging temporary vault build artifacts.
- Vault outputs are written to your chosen target path, commonly a USB mount.
- Docker stores pulled runtime images in its local image cache on disk.

Example target/staging paths:

- target path: `/media/<user>/<usb-label>/Vault`
- staging path: `/home/<user>/Projects/LocalAI/tmp`

## Public Repository Notes

This project is intended to be public, but generated data and local runtime artifacts should not be committed.

Typical non-source artifacts to keep out of git:

- model data (`ollama_data/`)
- temporary staging output (`tmp/`)
- built archives and large caches under external target paths

## Prune Safety

The Ollama models are stored in `ollama_data/` as a bind mount, so Docker prune commands do not remove the model files themselves.

Rules of thumb:

- Running containers are not removed by normal prune operations.
- Docker prune can remove stopped containers and unused images, so keep `ollama` running if you want it protected.
- There is no permanent Docker lock flag for a container; the real protection is where the data lives.
- Back up `ollama_data/` before cleanup, migration, or major model changes.

## Release Checklist

Before publishing:

1. Verify no private keys, tokens, or machine-specific secrets are tracked.
2. Verify large generated assets are ignored by git.
3. Verify scripts and docs use current filenames and paths.
4. Verify README links are valid and up to date.
5. Add or confirm a project license file if you plan public distribution.

# LocalAI Workspace

LocalAI is a two-part workspace:

- local AI runtime for coding and model experiments (Ollama on Docker)
- offline vault builder for preparing portable engineering resources

This repository is designed to support both online setup and offline operation.

## Table of Contents

- [Project Goals](#project-goals)
- [Repository Layout](#repository-layout)
- [Quick Start](#quick-start)
- [Component Guides](#component-guides)
- [Storage and Data](#storage-and-data)
- [Public Repository Notes](#public-repository-notes)
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
    GHcopilot/
      README_vault_GHcopilot.md
      vault_builder_GHcopilot.sh
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

### 2) Offline vault builder

```bash
chmod +x Vault/GHcopilot/vault_builder_GHcopilot.sh
./Vault/GHcopilot/vault_builder_GHcopilot.sh
```

## Component Guides

- AI runtime guide: [AI/README.md](AI/README.md)
- Offline vault guide: [Vault/GHcopilot/README_vault_GHcopilot.md](Vault/GHcopilot/README_vault_GHcopilot.md)

## Storage and Data

- `ollama_data/` stores local Ollama models and metadata.
- `tmp/` is used for staging temporary vault build artifacts.
- Vault outputs are written to your chosen target path, commonly a USB mount.

Example target/staging paths:

- target path: `/media/<user>/<usb-label>/Vault`
- staging path: `/home/<user>/Projects/LocalAI/tmp`

## Public Repository Notes

This project is intended to be public, but generated data and local runtime artifacts should not be committed.

Typical non-source artifacts to keep out of git:

- model data (`ollama_data/`)
- temporary staging output (`tmp/`)
- built archives and large caches under external target paths

## Release Checklist

Before publishing:

1. Verify no private keys, tokens, or machine-specific secrets are tracked.
2. Verify large generated assets are ignored by git.
3. Verify scripts and docs use current filenames and paths.
4. Verify README links are valid and up to date.
5. Add or confirm a project license file if you plan public distribution.

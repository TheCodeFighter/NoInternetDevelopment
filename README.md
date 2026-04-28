<a id="nointernet-workspace"></a>
# 🌐 NoInternet Workspace

> **NoInternet** is a two-part workspace designed to support both online setup and offline operation.

- **local AI runtime** for coding and model experiments (Ollama on Docker)
- **offline vault builder** for preparing portable engineering resources

It is also oriented toward embedded and PC apps with offline libraries and documentation.

<a id="table-of-contents"></a>
## 📖 Table of Contents

- [🌐 NoInternet Workspace](#-nointernet-workspace)
  - [📖 Table of Contents](#-table-of-contents)
  - [🎯 Project Goals](#-project-goals)
  - [📂 Repository Layout](#-repository-layout)
  - [📚 Component Guides](#-component-guides)
  - [💽 Storage and Data](#-storage-and-data)

---

<a id="project-goals"></a>
## 🎯 Project Goals

- **Run local LLM tooling** on Ubuntu with NVIDIA GPU.
- **Tested on PC with NVIDIA GeForce RTX 4060**.
- **Support embedded and PC apps with offline libraries and docs.**
- **Prepare an offline engineering vault** for development without internet.
- **Keep downloaded assets portable** on USB or mounted storage.

---

<a id="repository-layout"></a>
## 📂 Repository Layout

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

---

<a id="component-guides"></a>
## 📚 Component Guides

- AI runtime guide: [AI/README.md](AI/README.md)
- Offline vault guide: [Vault/README_vault.md](Vault/README_vault.md)

---

<a id="storage-and-data"></a>
## 💽 Storage and Data

- `ollama_data/` stores local Ollama models and metadata.
- `tmp/` is used for staging temporary vault build artifacts.
- Vault outputs are written to your chosen target path, commonly a USB mount.
- Docker stores pulled runtime images in its local image cache on disk.

Example target/staging paths:

- target path: `/media/<user>/<usb-label>/Vault`
- staging path: `/home/<user>/Projects/LocalAI/tmp`

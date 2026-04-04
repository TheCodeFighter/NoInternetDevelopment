# Offline Development Vault Builder

This folder contains an Ubuntu 24.x bash script that prepares a large offline engineering vault for embedded, backend, and localhost frontend development.

Script: vault_builder.sh

The script is interactive and does this for each bundle in order:
1. Download resources.
2. Compress the bundle into an archive.
3. Place the archive into your selected target path (USB or mounted disk).

AI model downloads are intentionally excluded.

## What gets downloaded

### Bundle 1: Docker + Debs + Toolchains (~20 GB)

- APT package cache (.deb) for compilers and tools:
  - gcc, g++, clang, llvm, lldb, gdb, cmake, ninja, make, pkg-config, ccache
  - docker.io, docker-compose-plugin
  - python3, python3-dev, python3-venv, python3-pip
  - nodejs, npm
  - sqlite3, postgresql client/dev, ssl/curl dev libs
  - boost dev package set, xml libs, mqtt/zmq libs
  - embedded tools (avrdude, avr gcc/gdb/libc, openocd)
  - docs helpers (doxygen, graphviz, zeal)
- Docker images saved as tar files:
  - ubuntu:24.04, debian:12-slim
  - python:3.12-slim, node:20-bookworm-slim
  - gcc:14, postgres:16, redis:7, nginx:1.27-alpine

### Bundle 2: Python + Node + Frontend caches (~10 GB)

- Python source tarball (CPython 3.12.9).
- Python wheel/source cache for backend/network/data packages:
  - numpy, pandas, scipy, matplotlib
  - requests, httpx, aiohttp, urllib3
  - fastapi, uvicorn, flask, django
  - sqlalchemy, psycopg2-binary, mysqlclient, pymongo, redis
  - grpcio, protobuf, pyserial, pyzmq, paho-mqtt
  - lxml, beautifulsoup4, jinja2, websockets
- Node frontend resources:
  - Latest Node v20 Linux x64 tarball
  - npm packs for react/react-dom/vite/typescript/tailwind/vue/svelte/lit/preact/etc
  - Warmed npm cache via a frontend seed project for localhost UI work

### Bundle 3: C/C++ Libraries (network/server/radio/parser/math)

Source archives for popular libs, including:
- Boost, nlohmann/json, fmt, spdlog
- cpp-httplib, Crow, Asio, libuv, websocketpp
- pugixml, tinyxml2, rapidjson, yaml-cpp
- Eigen
- RadioLib, rtl-sdr

### Bundle 4: OS Images + Embedded + VS Code plugins (~5 GB)

- Raspberry Pi OS Lite ARM64 latest image (suitable for Pi Zero 2W workflows).
- Arduino IDE latest Linux AppImage.
- Arduino CLI latest Linux tarball.
- Arduino core download cache (includes Nano-relevant core arduino:avr).
- VS Code extension packages (.vsix):
  - C/C++ Tools
  - CMake Tools
  - PlatformIO IDE
  - Arduino community extension
  - Cortex-Debug

### Bundle 5: Documentation (~5 GB target)

- cppreference offline HTML book archive.
- Python HTML documentation archive.
- GCC manual PDF.
- Hardware PDFs (Raspberry Pi Zero 2W, ATmega328P).
- Zeal feed index and selected docset archives (C/C++/Python/CMake/Bash/Docker/PostgreSQL).

### Bundle 6: Knowledge (Kiwix, ~40-60 GB)

- Latest StackOverflow full English ZIM from Kiwix index.
- Latest Kiwix desktop client (AppImage or tarball fallback).

## Output layout on target device

After a run, these folders are created under your chosen target path:

- archives/
- manifests/
- logs/

You will get one compressed archive per bundle, plus sha256 checksums.

## Requirements

- Ubuntu 24.x host
- Internet connection for the initial vault build
- sudo privileges (needed for apt download steps)
- Recommended tools present: curl, wget, tar, zstd (optional), docker (optional but recommended), python3/pip, npm
- Space planning:
  - Target storage: typically 85-110 GB depending on selected/latest file sizes
  - Staging storage: additional temporary space is needed while each bundle is being built

## How to use

1. Make script executable:

    ```bash
    chmod +x Vault/GHcopilot/vault_builder.sh
    ```

2. Run script:

    ```bash
    ./Vault/GHcopilot/vault_builder.sh
    ```

3. In prompts:

   - Enter target path (for example /media/david/MY_USB).
   - Enter staging path or accept default under /tmp.
   - Confirm full run.

5. Wait for completion.

   This can take many hours.

6. Check results:

   - archives in target_path/archives
   - checksums (*.sha256)
   - full run log in target_path/logs
   - run manifest in target_path/manifests

## Offline usage examples

### Docker images offline

```bash
for f in /path/to/archives_extracted/docker/*.tar; do
  docker load -i "$f"
done
```

### Install cached .deb packages offline

```bash
cd /path/to/archives_extracted/debs
sudo dpkg -i ./*.deb || sudo apt-get -f install
```

### Install Python packages offline

```bash
pip install --no-index --find-links=/path/to/archives_extracted/python_wheels \
  numpy pandas fastapi sqlalchemy psycopg2-binary
```

### Use npm packs offline

```bash
npm install --offline /path/to/archives_extracted/node/npm_packs/react-*.tgz
```

### Install VS Code extensions offline

```bash
code --install-extension /path/to/archives_extracted/vscode/cpptools.vsix
```

### Open StackOverflow offline with Kiwix

```bash
chmod +x /path/to/archives_extracted/kiwix/kiwix-desktop_latest_x86_64.AppImage
/path/to/archives_extracted/kiwix/kiwix-desktop_latest_x86_64.AppImage
```

Then open stackoverflow_latest.zim from the Kiwix UI.

## Notes

- URLs and versions on external servers can change over time. The script continues when a single item fails and reports all failed items at the end.
- If docker/python/npm are missing on the online machine, related bundle parts are skipped and logged.
- For deterministic environments, pin package versions by editing arrays in vault_builder.sh.

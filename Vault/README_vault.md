# Offline Development Vault Builder

This folder contains an Ubuntu 24.x bash script that prepares a large offline engineering vault for embedded, backend, and localhost frontend development.

Script: vault_builder.sh

## Table of Contents

- [What gets downloaded](#what-gets-downloaded)
- [Output layout on target device](#output-layout-on-target-device)
- [Requirements](#requirements)
- [Path examples: USB target and tmp staging](#path-examples-usb-target-and-tmp-staging)
- [Rerun behavior](#rerun-behavior)
- [Manifest behavior](#manifest-behavior)
- [download_cache: why it exists and when to delete](#download_cache-why-it-exists-and-when-to-delete)
- [How to use](#how-to-use)
- [Offline first-use guide](#offline-first-use-guide)
- [Offline bundle guide](#offline-bundle-guide)
- [Offline usage examples](#offline-usage-examples)
- [License and reuse notes](#license-and-reuse-notes)
- [Notes](#notes)

The script is interactive and lets you choose how the run behaves at startup.

Run modes:

- existing items: auto-skip them all, or ask for each one
- package mode: press Enter before each item.
- bundle mode: press Enter once before each bundle.
- start bundle: choose the first bundle to process, default 1.

Bundles before the selected start bundle are skipped.

The script then does this for the selected bundles:

1. Download resources.
2. Compress the bundle into an archive.
3. Place the archive into your selected target path (USB or mounted disk).
4. If the item already exists on target storage, prompt for skip or overwrite.

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

### Database-related downloads

This script does not download a full application database dump or your own project data.

What it does download for database work:

- sqlite3 and libsqlite3-dev for local SQLite usage
- libpq-dev and postgresql-client for PostgreSQL development and access
- the postgres:16 Docker image so you can run a local PostgreSQL server offline
- Python database packages such as sqlalchemy, psycopg2-binary, mysqlclient, pymongo, and redis

If you need to work fully offline with an actual database, use the downloaded postgres:16 image to start a local server, then restore your own SQL dump or data export into that server.

### Offline database workflow

If you need a database that you can fill with your own data, the simplest path is PostgreSQL from the downloaded Docker image.

Start a local database container:

```bash
docker run -d \
  --name local-postgres \
  -e POSTGRES_USER=dev \
  -e POSTGRES_PASSWORD=devpass \
  -e POSTGRES_DB=myapp \
  -p 5432:5432 \
  postgres:16
```

Connect with psql from the downloaded client tools or from the container itself:

```bash
psql -h localhost -U dev -d myapp
```

Create a table and insert sample data:

```sql
CREATE TABLE customers (
  id SERIAL PRIMARY KEY,
  name TEXT NOT NULL,
  email TEXT UNIQUE NOT NULL,
  created_at TIMESTAMP DEFAULT NOW()
);

INSERT INTO customers (name, email)
VALUES
  ('Alice', 'alice@example.com'),
  ('Bob', 'bob@example.com');

SELECT * FROM customers;
```

If you already have data in a .sql file, restore it like this:

```bash
psql -h localhost -U dev -d myapp -f /path/to/your_dump.sql
```

If you prefer SQLite for a small local project, the script also downloads sqlite3 and libsqlite3-dev. SQLite uses a single file database, so your application usually creates the database file itself and then writes data into it directly.

### Database documentation included

Yes, the vault does download database documentation.

- Bundle 5 includes the PostgreSQL Zeal docset, so you can browse PostgreSQL docs offline in Zeal.
- Bundle 5 also includes the general Docker, Bash, C, C++, Python, and PostgreSQL docsets listed in the docs bundle.
- The README examples above show how to use the downloaded database tools and image to build and populate your own local database offline.

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

### Bundle 7: Communication (Briar, offline and nearby messaging)

- Briar Android APK for direct install on phones.
- Briar Mailbox APK to improve message delivery when contacts are hard to reach.
- Briar Desktop for Ubuntu 24.04 as a .deb package.
- Briar Desktop for Linux x64 as an AppImage fallback.
- Offline Briar documentation pages for install, desktop download, contribution, and copyright.

Briar is the bundle for off-grid messaging, not a general internet chat app.
Use Android for Bluetooth and nearby contact setup.
Use Ubuntu/Linux Desktop for a companion client over LAN/Wi-Fi or Tor.

## Output layout on target device

After a run, these folders are created under your chosen target path:

- archives/
- manifests/
- logs/
- download_cache/

You will get one compressed archive per bundle, plus sha256 checksums.
Inside logs/ you get two logs:

- full run log (all activity)
- issues log (warnings and errors only) for quick troubleshooting

## Requirements

- Ubuntu 24.x host
- Internet connection for the initial vault build
- sudo privileges (needed for apt download steps)
- Recommended tools present: curl, wget, tar, zstd (optional), docker (optional but recommended), python3/pip, npm
- Space planning:
  - Target storage: typically 85-110 GB depending on selected/latest file sizes
  - Staging storage: additional temporary space is needed while each bundle is being built

If python3/pip/node/npm are missing on the online host, the script will try to install them automatically using sudo apt-get before bundle 2.
If Docker is missing or unusable, the script will try to install docker.io and docker-compose-plugin and start the daemon before bundle 1.

## Path examples: USB target and tmp staging

Example values when prompted by the script:

- Target path (USB/mounted disk): `/media/<user>/<usb-label>/Vault`
- Staging path (project tmp folder): `/home/<user>/Projects/LocalAI/tmp`
- Default staging path if you press Enter: `/tmp/offline_vault_stage_<RUN_ID>`

## Rerun behavior

- The script reuses the same target path and download cache when you run it again.
- Finished items are reused from target_path/download_cache when possible.
- Existing archives in target_path/archives are replaced when the same bundle is archived again.
- If you start from a later bundle number, earlier bundles are skipped entirely.

## Manifest behavior

- target_path/manifests/run_manifest_<RUN_ID>.txt is written at the end of each run.
- It records which bundles completed and which items failed.
- It is a build record, not an input file that the script needs to continue.

## download_cache: why it exists and when to delete

Why it exists:

- It stores completed downloads item-by-item under `target_path/download_cache`.
- On reruns, the script can reuse these files instead of downloading again.
- It helps recover from interrupted runs without restarting every bundle.

When to delete it:

- Keep it if you plan to rerun, rebuild, or update bundles later.
- Delete it only when you are sure all final archives and `.sha256` files are complete and you no longer need fast reruns.
- Deleting cache saves space but future runs may need to re-download many items.

## How to use

1. Make script executable:

    ```bash
    chmod +x Vault/vault_builder.sh
    ```

2. Run script:

    ```bash
    ./Vault/vault_builder.sh
    ```

3. Follow the prompts.

  The script asks for the target path first, then how to handle already-downloaded items, then the confirmation mode, then the starting bundle number. If you choose auto-skip, any item that already exists in target_path/download_cache is reused without asking. If you choose ask, you decide skip or overwrite for each existing item. Package mode means one Enter per item. Bundle mode means one Enter per bundle.

Wait for completion.

  This can take many hours.

Check results.

  Archives live in target_path/archives, checksums are written next to them, logs live in target_path/logs, run manifests live in target_path/manifests, and the persistent download cache lives in target_path/download_cache.

Use the issues log in target_path/logs/offline_vault_issues_<RUN_ID>.log to quickly find warnings/errors/failures without scanning the full log.

View logs live.

  To watch a .log file continuously without reopening or reloading it, keep it open in a terminal with:

  ```bash
  tail -f /path/to/target_path/logs/offline_vault_full_<RUN_ID>.log
  ```

  If you want a scrollable viewer that follows new lines, use `less +F /path/to/target_path/logs/offline_vault_full_<RUN_ID>.log` and press Ctrl+C to stop following.

## Offline first-use guide

If you only have the downloaded archives and no internet, use this order:

1. Unpack the bundle archives from target_path/archives into a working folder on the offline machine.
2. Read the manifest files in target_path/manifests to see what each archive contains.
3. Use the sections below to load the tools you need from the extracted folders.
4. Keep the logs in target_path/logs if you need to check what completed or failed during the build.

Typical extraction commands:

```bash
mkdir -p /path/to/offline_vault/extracted
cd /path/to/offline_vault/extracted

tar -xf /path/to/archives/01_docker_debs_toolchains.tar.*
tar -xf /path/to/archives/02_python_node_frontend.tar.*
tar -xf /path/to/archives/03_cpp_sources.tar.*
tar -xf /path/to/archives/04_os_embedded_vscode.tar.*
tar -xf /path/to/archives/05_documentation.tar.*
tar -xf /path/to/archives/06_kiwix_knowledge.tar.*
tar -xf /path/to/archives/07_briar_communication.tar.*
```

If the archive ends in .tar.zst, tar can usually extract it directly on modern Ubuntu systems. If not, install zstd on the offline machine ahead of time or use a machine that already has tar with zstd support.

## Offline bundle guide

### Bundle 1: Docker + Debs + Toolchains

Use this bundle when you need local build tools, system libraries, or Docker images.

The .deb files in the extracted debs folder can be installed offline like this:

```bash
cd /path/to/extracted/01_docker_debs_toolchains/debs
sudo dpkg -i ./*.deb || sudo apt-get -f install
```

If dependencies are missing, apt-get -f install tries to fix them from the cached packages you already have. If your machine truly has no package cache, install the missing .deb files manually in the same folder until dpkg succeeds.

The Docker image tars can be loaded without internet:

```bash
cd /path/to/extracted/01_docker_debs_toolchains/docker
for image in ./*.tar; do
  docker load -i "$image"
done
```

Use this when you want the same base images on an offline machine. After loading, check with docker images.

The toolchain packages in this bundle are mainly useful for offline system recovery and local development. Examples include gcc, clang, cmake, ninja, gdb, lldb, make, pkg-config, ccache, python3, node, npm, sqlite3, postgresql client libraries, and embedded tooling like avrdude and openocd.

### Bundle 2: Python + Node + Frontend caches

Use this bundle when you need Python package installs or frontend work without internet.

Python packages are stored as wheels or source archives under python_wheels. You can install them offline with:

```bash
cd /path/to/extracted/02_python_node_frontend/python_wheels
pip install --no-index --find-links=. numpy pandas scipy matplotlib requests httpx aiohttp urllib3
pip install --no-index --find-links=. fastapi uvicorn flask django sqlalchemy psycopg2-binary mysqlclient pymongo redis
pip install --no-index --find-links=. grpcio protobuf pyserial pyzmq paho-mqtt lxml beautifulsoup4 jinja2 websockets
```

If a package has a source distribution only, pip may need build tools already installed from bundle 1. That is why bundle 1 is usually the first one to unpack.

Node packages are stored in node/npm_packs. Install a pack directly from the tarball:

```bash
cd /path/to/extracted/02_python_node_frontend/node/npm_packs
npm install ./react-*.tgz
```

For a fully offline frontend workflow, use the warmed npm cache and the seed project that was stored under node/frontend_seed. You can copy that seed project to a working folder and run npm install using the local cache. If npm needs to rebuild native packages, make sure bundle 1 is already installed.

The Node tarball in this bundle is the offline runtime source tarball used by the builder. It is not required for day-to-day app development unless you want the same Node version that the build machine used.

### Bundle 3: C/C++ source libraries

Use this bundle when you want the source code for libraries rather than prebuilt binaries.

Each archive in sources is the upstream source tree for a library such as Boost, fmt, spdlog, nlohmann/json, cpp-httplib, Crow, Asio, libuv, websocketpp, pugixml, tinyxml2, rapidjson, yaml-cpp, Eigen, RadioLib, and rtl-sdr.

To use them offline:

1. Extract the archive you need.
2. Read its README or docs folder.
3. Build it locally with cmake, make, or the library's own build instructions.

Example pattern:

```bash
cd /path/to/extracted/03_cpp_sources/sources
tar -xf fmt-11.0.2.tar.gz
cd fmt-11.0.2
cmake -S . -B build
cmake --build build
```

Some libraries are header-only and can be included directly in your project. Others need a build step or are used as source dependencies in your own CMake or Makefile project.

RadioLib and rtl-sdr are especially useful for embedded and radio projects. Use the extracted source tree as your local reference and build them with your target toolchain.

### Bundle 4: OS images + Embedded + VS Code plugins

Use this bundle for Raspberry Pi, Arduino, and offline VS Code setup.

The Raspberry Pi OS image is meant to be written to an SD card or USB storage with a flashing tool such as dd, Rufus, balenaEtcher, or the Raspberry Pi Imager on another machine.

Example on Linux:

```bash
sudo dd if=/path/to/extracted/04_os_embedded_vscode/images/raspberry-pi-os-lite.img of=/dev/sdX bs=4M status=progress conv=fsync
```

Be careful to replace /dev/sdX with the correct device. Wrong device selection can erase the wrong disk.

Arduino IDE and Arduino CLI are stored as Linux downloads. If the archive contains an AppImage, make it executable and run it:

```bash
chmod +x /path/to/extracted/04_os_embedded_vscode/arduino/ArduinoIDE.AppImage
/path/to/extracted/04_os_embedded_vscode/arduino/ArduinoIDE.AppImage
```

Arduino CLI can usually be unpacked and used directly from its extracted folder. Use it for offline board installs, sketch builds, and uploads when you already have the required cores and libraries cached.

The VS Code extensions in the vscode folder are .vsix packages. Install them offline with:

```bash
code --install-extension /path/to/extracted/04_os_embedded_vscode/vscode/cpptools.vsix
code --install-extension /path/to/extracted/04_os_embedded_vscode/vscode/cmake-tools.vsix
code --install-extension /path/to/extracted/04_os_embedded_vscode/vscode/platformio-ide.vsix
code --install-extension /path/to/extracted/04_os_embedded_vscode/vscode/vscode-arduino-community.vsix
code --install-extension /path/to/extracted/04_os_embedded_vscode/vscode/cortex-debug.vsix
```

The Arduino core cache is useful if you need arduino:avr or Nano-related boards on an offline machine. Copy the cached core files into the Arduino data directory or point the Arduino CLI at the local cache path used by your setup.

### Bundle 5: Documentation

Use this bundle when you want reference material available offline.

The cppreference HTML book, Python docs, GCC manual, hardware PDFs, and Zeal docsets can be opened directly from the extracted folders.

For example:

```bash
xdg-open /path/to/extracted/05_documentation/docs/gcc-14.1-manual.pdf
xdg-open /path/to/extracted/05_documentation/docs/arduino-nano-datasheet.pdf
```

If you use Zeal, copy the extracted docset archives into Zeal's docsets folder and then open Zeal again. The docsets appear in the sidebar once Zeal indexes them.

This bundle is the one to keep nearby when you have no browser access and need reference material for C, C++, Python, Bash, Docker, PostgreSQL, or embedded hardware.

### Bundle 6: Kiwix knowledge

Use this bundle for completely offline reading and search, especially Stack Overflow.

The Kiwix Desktop AppImage or tar.gz gives you the reader application. The Stack Overflow ZIM is the content database that the reader opens.

How to use it:

1. Make the AppImage executable or unpack the tar.gz if that is what you have.
2. Start Kiwix Desktop.
3. Use Open File or Add Library inside Kiwix.
4. Select the extracted stackoverflow_latest.zim file.
5. Search inside Kiwix exactly like an offline browser.

Example:

```bash
chmod +x /path/to/extracted/06_kiwix_knowledge/kiwix/kiwix-desktop_latest_x86_64.AppImage
/path/to/extracted/06_kiwix_knowledge/kiwix/kiwix-desktop_latest_x86_64.AppImage
```

Once Kiwix is open, load stackoverflow_latest.zim from the kiwix folder.

### Bundle 7: Briar communication

Use this bundle when you want a messenger that can keep working with weak or no internet and nearby-device contact setup.

Important capability split:

- Briar Android is the primary off-grid client and supports Bluetooth and nearby contact setup.
- Briar Desktop on Ubuntu/Linux is a companion client for LAN/Wi-Fi and Tor.
- Briar Desktop does not support Bluetooth nearby contact addition.

If you already have adb installed on the PC, you can install Briar Android from the APK like this:

```bash
adb install /path/to/extracted/07_briar_communication/android/briar.apk
adb install /path/to/extracted/07_briar_communication/android/mailbox.apk
```

If you do not use adb, copy the APK to the phone and open it with a file manager or browser download picker, then allow app installs if Android asks.

For Ubuntu 24.04, install the Briar Desktop .deb:

```bash
sudo apt install /path/to/extracted/07_briar_communication/desktop/briar-desktop-ubuntu-24.04.deb
```

If your Linux setup prefers AppImage, use the fallback instead:

```bash
chmod +x /path/to/extracted/07_briar_communication/desktop/briar-desktop-x64.AppImage
/path/to/extracted/07_briar_communication/desktop/briar-desktop-x64.AppImage
```

Suggested setup order:

1. Install Briar Android first.
2. Install Briar Mailbox if you expect weak connectivity.
3. Install Briar Desktop on Ubuntu if you want a second device.
4. Add contacts from Android when you want the Bluetooth/off-grid workflow.
5. Use Desktop for a companion session, not as the primary Bluetooth link.

Offline Briar docs included in the bundle:

- download-briar.html: main Android download page
- download-briar-desktop.html: desktop package page with Linux, Windows, and macOS choices
- briar-direct-download.html: Android APK direct-install instructions
- briar-get-involved.html: source, build, chat, and contribution info
- briar-copyright.html: Briar license and website copyright notes

If you only want the docs and not the app binaries, open the HTML pages directly from the extracted docs folder in your browser or with xdg-open.

How to use Briar offline:

1. Open Briar.
2. Create or unlock your identity.
3. Add a contact by nearby connection, QR flow, or a shared link/code when the app offers it.
4. Start a private chat or group.
5. Keep the app open when you expect delayed delivery or sync.

If the internet is unavailable, Briar still works best when at least one of these paths is available between devices:

- Bluetooth on Android for nearby pairing.
- Wi-Fi/LAN between devices.
- Tor when you later have routed connectivity.

For true off-grid work, keep Android as the main messaging device and use Linux as the companion device.

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

## License and reuse notes

This vault is meant for offline use on your own machines. In general, the downloads fall into three practical groups:

1. Source code and documentation archives: usually safe to keep and use locally, but follow the upstream license if you redistribute them.
2. Binary tools and installers: usually fine to use for your own offline setup, but redistribution may be limited by the vendor's terms or trademark rules.
3. Stack Overflow and other content collections: the content license matters, especially if you redistribute, mirror publicly, or republish excerpts.

Briar itself is open source, and the downloads in this bundle come from the project's official distribution pages. Keep the upstream notices if you share the files or the bundle.

For Stack Overflow specifically, the content is distributed under a Creative Commons Attribution-ShareAlike-style license, so attribution and share-alike obligations matter if you reuse or republish content outside your own machine.

For personal offline development, the important rule is simple: keep the original notices, do not remove license files, and do not assume that every archive can be re-uploaded or bundled into another public project without checking its license first.

## Notes

- URLs and versions on external servers can change over time. The script continues when a single item fails and reports all failed items at the end.
- If docker/python/npm are missing on the online machine, related bundle parts are skipped and logged.
- If Docker cannot be installed or started, that is recorded in the issues log and bundle 1 will skip Docker image exports.
- The script attempts to auto-install missing python3/pip/node/npm tools with sudo apt-get before running bundle 2.
- Docker apt seed packages are treated as optional, so a docker.io download failure will not stop the rest of bundle 1.
- If you choose auto-skip, already-downloaded items are silently reused from the cache and you will not be prompted for them again.
- For deterministic environments, pin package versions by editing arrays in vault_builder.sh.
- The script keeps a persistent item cache in target_path/download_cache so reruns can skip already-downloaded items item-by-item.

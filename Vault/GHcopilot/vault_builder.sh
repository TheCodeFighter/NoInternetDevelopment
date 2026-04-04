#!/usr/bin/env bash
set -u
set -o pipefail

SCRIPT_VERSION="1.0.0"
RUN_ID="$(date +%Y%m%d_%H%M%S)"

APT_PACKAGES=(
  build-essential gcc g++ clang lldb llvm gdb cmake ninja-build make pkg-config ccache
  autoconf automake libtool gperf
  git curl wget rsync unzip zip xz-utils zstd ca-certificates
  docker.io docker-compose-plugin
  python3 python3-dev python3-venv python3-pip
  nodejs npm
  sqlite3 libsqlite3-dev
  libpq-dev postgresql-client
  libssl-dev libcurl4-openssl-dev
  libboost-all-dev
  libzmq3-dev libmosquitto-dev
  libxml2-dev libtinyxml2-dev
  avrdude gcc-avr gdb-avr avr-libc openocd
  doxygen graphviz zeal
)

DOCKER_IMAGES=(
  ubuntu:24.04
  debian:12-slim
  python:3.12-slim
  node:20-bookworm-slim
  gcc:14
  postgres:16
  redis:7
  nginx:1.27-alpine
)

PYTHON_PACKAGES=(
  numpy pandas scipy matplotlib
  requests httpx aiohttp urllib3
  fastapi uvicorn flask django
  sqlalchemy psycopg2-binary mysqlclient pymongo redis
  pydantic marshmallow python-dotenv
  grpcio protobuf
  pyserial pyzmq paho-mqtt
  lxml beautifulsoup4 jinja2 websockets
)

NPM_PACKAGES=(
  react react-dom vite typescript
  tailwindcss axios socket.io-client
  lit preact svelte vue
  eslint prettier
)

CPP_SOURCE_URLS=(
  "boost_1_85_0.tar.gz|https://archives.boost.io/release/1.85.0/source/boost_1_85_0.tar.gz"
  "nlohmann-json-3.11.3.tar.gz|https://github.com/nlohmann/json/archive/refs/tags/v3.11.3.tar.gz"
  "fmt-11.0.2.tar.gz|https://github.com/fmtlib/fmt/archive/refs/tags/11.0.2.tar.gz"
  "spdlog-1.14.1.tar.gz|https://github.com/gabime/spdlog/archive/refs/tags/v1.14.1.tar.gz"
  "cpp-httplib-0.16.3.tar.gz|https://github.com/yhirose/cpp-httplib/archive/refs/tags/v0.16.3.tar.gz"
  "crow-1.2.0.tar.gz|https://github.com/CrowCpp/Crow/archive/refs/tags/v1.2.0.tar.gz"
  "asio-1.30.2.tar.gz|https://github.com/chriskohlhoff/asio/archive/refs/tags/asio-1-30-2.tar.gz"
  "libuv-1.49.2.tar.gz|https://github.com/libuv/libuv/archive/refs/tags/v1.49.2.tar.gz"
  "websocketpp-0.8.2.tar.gz|https://github.com/zaphoyd/websocketpp/archive/refs/tags/0.8.2.tar.gz"
  "pugixml-1.14.tar.gz|https://github.com/zeux/pugixml/archive/refs/tags/v1.14.tar.gz"
  "tinyxml2-10.0.0.tar.gz|https://github.com/leethomason/tinyxml2/archive/refs/tags/10.0.0.tar.gz"
  "rapidjson-1.1.0.tar.gz|https://github.com/Tencent/rapidjson/archive/refs/tags/v1.1.0.tar.gz"
  "yaml-cpp-0.8.0.tar.gz|https://github.com/jbeder/yaml-cpp/archive/refs/tags/0.8.0.tar.gz"
  "eigen-3.4.0.tar.gz|https://gitlab.com/libeigen/eigen/-/archive/3.4.0/eigen-3.4.0.tar.gz"
  "radiolib-6.5.0.tar.gz|https://github.com/jgromes/RadioLib/archive/refs/tags/v6.5.0.tar.gz"
  "rtl-sdr-2.0.2.tar.gz|https://github.com/osmocom/rtl-sdr/archive/refs/tags/2.0.2.tar.gz"
)

VSCODE_EXTENSION_URLS=(
  "cpptools.vsix|https://ms-vscode.gallery.vsassets.io/_apis/public/gallery/publisher/ms-vscode/extension/cpptools/latest/assetbyname/Microsoft.VisualStudio.Services.VSIXPackage"
  "cmake-tools.vsix|https://ms-vscode.gallery.vsassets.io/_apis/public/gallery/publisher/ms-vscode/extension/cmake-tools/latest/assetbyname/Microsoft.VisualStudio.Services.VSIXPackage"
  "platformio-ide.vsix|https://platformio.gallery.vsassets.io/_apis/public/gallery/publisher/platformio/extension/platformio-ide/latest/assetbyname/Microsoft.VisualStudio.Services.VSIXPackage"
  "vscode-arduino-community.vsix|https://vscode-arduino.gallery.vsassets.io/_apis/public/gallery/publisher/vscode-arduino/extension/vscode-arduino-community/latest/assetbyname/Microsoft.VisualStudio.Services.VSIXPackage"
  "cortex-debug.vsix|https://marus25.gallery.vsassets.io/_apis/public/gallery/publisher/marus25/extension/cortex-debug/latest/assetbyname/Microsoft.VisualStudio.Services.VSIXPackage"
)

DOC_URLS=(
  "cppreference-html-book.zip|https://github.com/PeterFeicht/cppreference-doc/releases/download/v2024.02.17/html-book-2024.02.17.zip"
  "python-3.12.9-docs-html.tar.bz2|https://docs.python.org/3/archives/python-3.12.9-docs-html.tar.bz2"
  "gcc-14.1-manual.pdf|https://gcc.gnu.org/onlinedocs/gcc-14.1.0/gcc.pdf"
  "atmega328p-datasheet.pdf|https://ww1.microchip.com/downloads/en/DeviceDoc/ATmega328P-Data-Sheet-DS-DS40002061B.pdf"
  "rpi-zero2w-product-brief.pdf|https://datasheets.raspberrypi.com/zero2/raspberry-pi-zero-2-w-product-brief.pdf"
  "rpi-zero2w-getting-started.pdf|https://datasheets.raspberrypi.com/zero2/zero2-w-getting-started.pdf"
  "zeal-feed-entries.xml|https://kapeli.com/feeds/zzz/entries.xml"
  "zeal-docset-cpp.tgz|https://kapeli.com/feeds/C++.tgz"
  "zeal-docset-c.tgz|https://kapeli.com/feeds/C.tgz"
  "zeal-docset-python3.tgz|https://kapeli.com/feeds/Python_3.tgz"
  "zeal-docset-cmake.tgz|https://kapeli.com/feeds/CMake.tgz"
  "zeal-docset-bash.tgz|https://kapeli.com/feeds/Bash.tgz"
  "zeal-docset-docker.tgz|https://kapeli.com/feeds/Docker.tgz"
  "zeal-docset-postgresql.tgz|https://kapeli.com/feeds/PostgreSQL.tgz"
)

TARGET_ROOT=""
STAGING_ROOT=""
LOG_FILE=""

FAILED_ITEMS=()
COMPLETED_BUNDLES=()

if [[ "${EUID}" -eq 0 ]]; then
  echo "Do not run as root. Use a normal user with sudo privileges."
  exit 1
fi

timestamp() {
  date "+%Y-%m-%d %H:%M:%S"
}

log() {
  local msg="$1"
  echo "[$(timestamp)] ${msg}" | tee -a "$LOG_FILE"
}

warn() {
  local msg="$1"
  echo "[$(timestamp)] WARNING: ${msg}" | tee -a "$LOG_FILE" >&2
}

record_failure() {
  local item="$1"
  FAILED_ITEMS+=("$item")
  warn "$item"
}

require_commands() {
  local required=(bash curl wget tar sha256sum awk grep sed sort lsblk df)
  local missing=()

  for cmd in "${required[@]}"; do
    if ! command -v "$cmd" >/dev/null 2>&1; then
      missing+=("$cmd")
    fi
  done

  if [[ ${#missing[@]} -gt 0 ]]; then
    echo "Missing required commands: ${missing[*]}"
    echo "Install them first, then rerun."
    exit 1
  fi
}

print_manifest() {
  cat <<'EOF'
==========================================================================
  OFFLINE DEVELOPMENT VAULT BUILDER (Ubuntu 24.x)
==========================================================================
This script downloads and packages resources into compressed archives.
Order is strict and sequential per bundle:
  download -> compress archive -> move archive to selected target path

Bundle plan (approx):
  1) Docker + Debs + Toolchains .................... ~20 GB
  2) Python + Node + Frontend caches ............... ~10 GB
  3) C/C++ source libraries (network/server/radio) . ~5-10 GB
  4) OS images + Embedded tools + VSCode plugins ... ~5 GB
  5) Documentation + Zeal docsets + hardware PDFs .. ~5 GB
  6) Kiwix offline knowledge (StackOverflow) ....... ~40-60 GB

NOT included:
  - AI model files (you already host them locally)
==========================================================================
EOF
}

list_storage_devices() {
  echo
  echo "Detected block devices (choose a mounted target path):"
  lsblk -o NAME,SIZE,TYPE,FSTYPE,MOUNTPOINTS,MODEL
  echo
}

prompt_paths() {
  local answer

  read -r -p "Enter absolute target path (USB or disk mountpoint): " TARGET_ROOT
  if [[ -z "$TARGET_ROOT" ]]; then
    echo "Target path is required."
    exit 1
  fi

  if [[ ! -d "$TARGET_ROOT" ]]; then
    read -r -p "Target path does not exist. Create it? [y/N]: " answer
    if [[ "$answer" =~ ^[Yy]$ ]]; then
      mkdir -p "$TARGET_ROOT"
    else
      echo "Aborted."
      exit 1
    fi
  fi

  if [[ ! -w "$TARGET_ROOT" ]]; then
    echo "Target path is not writable: $TARGET_ROOT"
    exit 1
  fi

  read -r -p "Enter staging path for temporary downloads [/tmp/offline_vault_stage_${RUN_ID}]: " STAGING_ROOT
  STAGING_ROOT="${STAGING_ROOT:-/tmp/offline_vault_stage_${RUN_ID}}"

  mkdir -p "$STAGING_ROOT"
  mkdir -p "$TARGET_ROOT/archives" "$TARGET_ROOT/manifests" "$TARGET_ROOT/logs"

  LOG_FILE="$TARGET_ROOT/logs/offline_vault_${RUN_ID}.log"
  : > "$LOG_FILE"

  echo
  echo "Target : $TARGET_ROOT"
  echo "Staging: $STAGING_ROOT"
  echo
  echo "Free space snapshot:"
  df -h "$TARGET_ROOT" "$STAGING_ROOT" | tee -a "$LOG_FILE"
  echo
}

confirm_start() {
  local confirm
  read -r -p "Proceed with all bundles? This can take many hours. [y/N]: " confirm
  if [[ ! "$confirm" =~ ^[Yy]$ ]]; then
    echo "Aborted by user."
    exit 0
  fi
}

download_url() {
  local label="$1"
  local url="$2"
  local output_path="$3"

  mkdir -p "$(dirname "$output_path")"

  if [[ -f "$output_path" ]]; then
    log "Already present, skipping: $label"
    return 0
  fi

  log "Downloading: $label"
  if wget -c --tries=4 --timeout=45 -O "$output_path" "$url" >>"$LOG_FILE" 2>&1; then
    return 0
  fi

  record_failure "Download failed: $label ($url)"
  rm -f "$output_path"
  return 1
}

download_latest_from_index() {
  local label="$1"
  local index_url="$2"
  local file_regex="$3"
  local output_path="$4"
  local listing
  local latest_name

  log "Resolving latest file for: $label"
  if ! listing="$(curl -fsSL "$index_url" 2>>"$LOG_FILE")"; then
    record_failure "Index fetch failed: $label ($index_url)"
    return 1
  fi

  latest_name="$(printf '%s' "$listing" | grep -oE "$file_regex" | sort -uV | tail -n 1)"
  if [[ -z "$latest_name" ]]; then
    record_failure "Could not resolve latest file for: $label"
    return 1
  fi

  download_url "$label [$latest_name]" "${index_url}${latest_name}" "$output_path"
}

archive_bundle() {
  local bundle_key="$1"
  local bundle_dir="$2"
  local output_archive=""

  if [[ ! -d "$bundle_dir" ]]; then
    record_failure "Bundle folder missing before archive: $bundle_key"
    return 1
  fi

  if [[ -z "$(find "$bundle_dir" -mindepth 1 -print -quit 2>/dev/null)" ]]; then
    warn "Bundle is empty, skipping archive: $bundle_key"
    rm -rf "$bundle_dir"
    return 1
  fi

  if command -v zstd >/dev/null 2>&1 && tar --help 2>&1 | grep -q -- '--zstd'; then
    output_archive="$TARGET_ROOT/archives/${bundle_key}.tar.zst"
    log "Compressing bundle with zstd: $bundle_key"
    if tar --zstd -cf "${output_archive}.part" -C "$(dirname "$bundle_dir")" "$(basename "$bundle_dir")" >>"$LOG_FILE" 2>&1; then
      mv "${output_archive}.part" "$output_archive"
    else
      record_failure "Archive failed (zstd): $bundle_key"
      rm -f "${output_archive}.part"
      return 1
    fi
  else
    output_archive="$TARGET_ROOT/archives/${bundle_key}.tar.gz"
    log "Compressing bundle with gzip: $bundle_key"
    if tar -czf "${output_archive}.part" -C "$(dirname "$bundle_dir")" "$(basename "$bundle_dir")" >>"$LOG_FILE" 2>&1; then
      mv "${output_archive}.part" "$output_archive"
    else
      record_failure "Archive failed (gzip): $bundle_key"
      rm -f "${output_archive}.part"
      return 1
    fi
  fi

  sha256sum "$output_archive" > "${output_archive}.sha256"
  log "Bundle archived: $output_archive"

  rm -rf "$bundle_dir"
  COMPLETED_BUNDLES+=("$bundle_key")
  return 0
}

bundle_01_docker_debs_toolchains() {
  local bundle_key="01_docker_debs_toolchains"
  local bundle_dir="$STAGING_ROOT/$bundle_key"
  local pkg
  local image
  local safe_name
  local docker_ok=0
  local docker_cmd=(docker)

  log "=== Bundle 1/6: Docker + Debs + Toolchains ==="
  rm -rf "$bundle_dir"
  mkdir -p "$bundle_dir/debs" "$bundle_dir/docker" "$bundle_dir/meta"

  printf '%s\n' "${APT_PACKAGES[@]}" > "$bundle_dir/meta/apt_seed_packages.txt"
  printf '%s\n' "${DOCKER_IMAGES[@]}" > "$bundle_dir/meta/docker_images.txt"

  if command -v apt-get >/dev/null 2>&1 && command -v sudo >/dev/null 2>&1; then
    log "Running apt-get update (sudo)..."
    if sudo apt-get update >>"$LOG_FILE" 2>&1; then
      for pkg in "${APT_PACKAGES[@]}"; do
        log "Downloading .deb seed package (with deps): $pkg"
        if ! sudo apt-get -y --download-only -o Dir::Cache::archives="$bundle_dir/debs" install "$pkg" >>"$LOG_FILE" 2>&1; then
          record_failure "apt download failed for package: $pkg"
        fi
      done
      find "$bundle_dir/debs" -type f ! -name '*.deb' -delete 2>/dev/null || true
    else
      record_failure "apt-get update failed"
    fi
  else
    record_failure "Skipping apt bundle: apt-get and/or sudo not available"
  fi

  if command -v docker >/dev/null 2>&1; then
    if docker info >/dev/null 2>&1; then
      docker_cmd=(docker)
      docker_ok=1
    elif command -v sudo >/dev/null 2>&1 && sudo docker info >/dev/null 2>&1; then
      docker_cmd=(sudo docker)
      docker_ok=1
    fi

    if [[ $docker_ok -eq 1 ]]; then
      for image in "${DOCKER_IMAGES[@]}"; do
        safe_name="${image//\//_}"
        safe_name="${safe_name//:/_}"

        log "Pulling Docker image: $image"
        if "${docker_cmd[@]}" pull "$image" >>"$LOG_FILE" 2>&1; then
          log "Saving Docker image: $image"
          if ! "${docker_cmd[@]}" save "$image" -o "$bundle_dir/docker/${safe_name}.tar" >>"$LOG_FILE" 2>&1; then
            record_failure "docker save failed: $image"
          fi
        else
          record_failure "docker pull failed: $image"
        fi
      done
    else
      record_failure "Skipping docker images: Docker daemon not accessible"
    fi
  else
    record_failure "Skipping docker images: docker command not found"
  fi

  archive_bundle "$bundle_key" "$bundle_dir"
}

bundle_02_python_node_frontend() {
  local bundle_key="02_python_node_frontend"
  local bundle_dir="$STAGING_ROOT/$bundle_key"
  local pkg

  log "=== Bundle 2/6: Python + Node + Frontend ==="
  rm -rf "$bundle_dir"
  mkdir -p "$bundle_dir/python_wheels" "$bundle_dir/node/npm_packs" "$bundle_dir/node/npm_cache" "$bundle_dir/meta"

  printf '%s\n' "${PYTHON_PACKAGES[@]}" > "$bundle_dir/meta/python_packages.txt"
  printf '%s\n' "${NPM_PACKAGES[@]}" > "$bundle_dir/meta/npm_packages.txt"

  download_url "CPython 3.12.9 source" "https://www.python.org/ftp/python/3.12.9/Python-3.12.9.tgz" "$bundle_dir/python_wheels/Python-3.12.9.tgz"

  if command -v python3 >/dev/null 2>&1 && python3 -m pip --version >/dev/null 2>&1; then
    for pkg in "${PYTHON_PACKAGES[@]}"; do
      log "Downloading pip package: $pkg"
      if ! python3 -m pip download --prefer-binary --dest "$bundle_dir/python_wheels" "$pkg" >>"$LOG_FILE" 2>&1; then
        record_failure "pip download failed for package: $pkg"
      fi
    done
  else
    record_failure "Skipping Python wheel cache: python3/pip unavailable"
  fi

  download_latest_from_index \
    "Node.js latest v20 Linux x64" \
    "https://nodejs.org/dist/latest-v20.x/" \
    "node-v20\\.[0-9]+\\.[0-9]+-linux-x64\\.tar\\.xz" \
    "$bundle_dir/node/node-v20-linux-x64-latest.tar.xz"

  if command -v npm >/dev/null 2>&1; then
    for pkg in "${NPM_PACKAGES[@]}"; do
      log "Downloading npm pack: $pkg"
      if ! npm pack "$pkg" --pack-destination "$bundle_dir/node/npm_packs" >>"$LOG_FILE" 2>&1; then
        record_failure "npm pack failed for package: $pkg"
      fi
    done

    mkdir -p "$bundle_dir/node/frontend_seed"
    cat > "$bundle_dir/node/frontend_seed/package.json" <<'JSON'
{
  "name": "offline-frontend-seed",
  "version": "1.0.0",
  "private": true,
  "description": "Cache warmer for offline localhost frontend development",
  "dependencies": {
    "axios": "latest",
    "lit": "latest",
    "preact": "latest",
    "react": "latest",
    "react-dom": "latest",
    "socket.io-client": "latest",
    "svelte": "latest",
    "tailwindcss": "latest",
    "typescript": "latest",
    "vite": "latest",
    "vue": "latest"
  },
  "devDependencies": {
    "eslint": "latest",
    "prettier": "latest"
  }
}
JSON

    log "Building npm cache warmup project"
    if ! (
      cd "$bundle_dir/node/frontend_seed" && \
      npm install --ignore-scripts --no-audit --no-fund --cache "$bundle_dir/node/npm_cache"
    ) >>"$LOG_FILE" 2>&1; then
      record_failure "npm cache warmup install failed"
    fi
  else
    record_failure "Skipping npm bundle: npm command not found"
  fi

  archive_bundle "$bundle_key" "$bundle_dir"
}

bundle_03_cpp_sources() {
  local bundle_key="03_cpp_sources"
  local bundle_dir="$STAGING_ROOT/$bundle_key"
  local entry
  local filename
  local url

  log "=== Bundle 3/6: C/C++ source libraries ==="
  rm -rf "$bundle_dir"
  mkdir -p "$bundle_dir/sources" "$bundle_dir/meta"

  for entry in "${CPP_SOURCE_URLS[@]}"; do
    filename="${entry%%|*}"
    url="${entry#*|}"
    download_url "$filename" "$url" "$bundle_dir/sources/$filename"
  done

  printf '%s\n' "${CPP_SOURCE_URLS[@]}" > "$bundle_dir/meta/cpp_sources_manifest.txt"
  archive_bundle "$bundle_key" "$bundle_dir"
}

bundle_04_os_embedded_vscode() {
  local bundle_key="04_os_embedded_vscode"
  local bundle_dir="$STAGING_ROOT/$bundle_key"
  local entry
  local filename
  local url
  local cli_bin
  local cli_cfg
  local cli_data

  log "=== Bundle 4/6: OS images + embedded + VSCode plugins ==="
  rm -rf "$bundle_dir"
  mkdir -p "$bundle_dir/images" "$bundle_dir/arduino" "$bundle_dir/vscode" "$bundle_dir/meta"

  download_url "Raspberry Pi OS Lite ARM64 (latest)" \
    "https://downloads.raspberrypi.com/raspios_lite_arm64_latest" \
    "$bundle_dir/images/raspios_lite_arm64_latest.img.xz"

  download_url "Arduino IDE (latest AppImage)" \
    "https://downloads.arduino.cc/arduino-ide/arduino-ide_latest_Linux_64bit.AppImage" \
    "$bundle_dir/images/arduino-ide_latest_Linux_64bit.AppImage"

  download_url "Arduino CLI (latest Linux x64)" \
    "https://downloads.arduino.cc/arduino-cli/arduino-cli_latest_Linux_64bit.tar.gz" \
    "$bundle_dir/arduino/arduino-cli_latest_Linux_64bit.tar.gz"

  if [[ -f "$bundle_dir/arduino/arduino-cli_latest_Linux_64bit.tar.gz" ]]; then
    mkdir -p "$bundle_dir/arduino/bin"
    if tar -xzf "$bundle_dir/arduino/arduino-cli_latest_Linux_64bit.tar.gz" -C "$bundle_dir/arduino/bin" >>"$LOG_FILE" 2>&1; then
      cli_bin="$bundle_dir/arduino/bin/arduino-cli"
      cli_cfg="$bundle_dir/arduino/arduino-cli.yaml"
      cli_data="$bundle_dir/arduino/data"

      if [[ -x "$cli_bin" ]]; then
        mkdir -p "$cli_data/downloads" "$cli_data/user" "$cli_data/data"
        cat > "$cli_cfg" <<EOF
board_manager:
  additional_urls: []
directories:
  data: ${cli_data}/data
  downloads: ${cli_data}/downloads
  user: ${cli_data}/user
EOF

        log "Updating Arduino core index"
        if ! "$cli_bin" core update-index --config-file "$cli_cfg" >>"$LOG_FILE" 2>&1; then
          record_failure "arduino-cli core update-index failed"
        fi

        log "Downloading Arduino cores (Nano via arduino:avr)"
        if ! "$cli_bin" core download arduino:avr --config-file "$cli_cfg" >>"$LOG_FILE" 2>&1; then
          record_failure "arduino-cli core download failed: arduino:avr"
        fi

        if ! "$cli_bin" core download arduino:megaavr --config-file "$cli_cfg" >>"$LOG_FILE" 2>&1; then
          record_failure "arduino-cli core download failed: arduino:megaavr"
        fi

        if ! "$cli_bin" core download arduino:mbed_nano --config-file "$cli_cfg" >>"$LOG_FILE" 2>&1; then
          record_failure "arduino-cli core download failed: arduino:mbed_nano"
        fi
      else
        record_failure "arduino-cli binary missing after extraction"
      fi
    else
      record_failure "Could not extract arduino-cli archive"
    fi
  fi

  for entry in "${VSCODE_EXTENSION_URLS[@]}"; do
    filename="${entry%%|*}"
    url="${entry#*|}"
    download_url "$filename" "$url" "$bundle_dir/vscode/$filename"
  done

  printf '%s\n' "${VSCODE_EXTENSION_URLS[@]}" > "$bundle_dir/meta/vscode_extensions_manifest.txt"
  archive_bundle "$bundle_key" "$bundle_dir"
}

bundle_05_documentation() {
  local bundle_key="05_documentation"
  local bundle_dir="$STAGING_ROOT/$bundle_key"
  local entry
  local filename
  local url

  log "=== Bundle 5/6: Documentation + Zeal + hardware PDFs ==="
  rm -rf "$bundle_dir"
  mkdir -p "$bundle_dir/docs" "$bundle_dir/meta"

  for entry in "${DOC_URLS[@]}"; do
    filename="${entry%%|*}"
    url="${entry#*|}"
    download_url "$filename" "$url" "$bundle_dir/docs/$filename"
  done

  printf '%s\n' "${DOC_URLS[@]}" > "$bundle_dir/meta/docs_manifest.txt"
  archive_bundle "$bundle_key" "$bundle_dir"
}

bundle_06_kiwix_knowledge() {
  local bundle_key="06_kiwix_knowledge"
  local bundle_dir="$STAGING_ROOT/$bundle_key"

  log "=== Bundle 6/6: Kiwix offline knowledge ==="
  rm -rf "$bundle_dir"
  mkdir -p "$bundle_dir/kiwix" "$bundle_dir/meta"

  download_latest_from_index \
    "Kiwix StackOverflow ZIM" \
    "https://download.kiwix.org/zim/stackoverflow/" \
    "stackoverflow\\.com_en_all_[0-9]{4}-[0-9]{2}\\.zim" \
    "$bundle_dir/kiwix/stackoverflow_latest.zim"

  if ! download_latest_from_index \
    "Kiwix Desktop x86_64 AppImage" \
    "https://download.kiwix.org/release/kiwix-desktop/" \
    "kiwix-desktop[^\"']*x86_64[^\"']*\\.AppImage" \
    "$bundle_dir/kiwix/kiwix-desktop_latest_x86_64.AppImage"; then

    download_latest_from_index \
      "Kiwix Desktop x86_64 tar.gz" \
      "https://download.kiwix.org/release/kiwix-desktop/" \
      "kiwix-desktop[^\"']*x86_64[^\"']*\\.tar\\.gz" \
      "$bundle_dir/kiwix/kiwix-desktop_latest_x86_64.tar.gz"
  fi

  archive_bundle "$bundle_key" "$bundle_dir"
}

write_run_manifest() {
  local manifest_path="$TARGET_ROOT/manifests/run_manifest_${RUN_ID}.txt"

  {
    echo "Offline Vault Builder"
    echo "Version: $SCRIPT_VERSION"
    echo "Run ID : $RUN_ID"
    echo "Date   : $(date -Iseconds)"
    echo ""
    echo "Target root : $TARGET_ROOT"
    echo "Staging root: $STAGING_ROOT"
    echo ""
    echo "Completed bundles:"
    for b in "${COMPLETED_BUNDLES[@]}"; do
      echo "  - $b"
    done
    echo ""
    echo "Failures (${#FAILED_ITEMS[@]}):"
    for f in "${FAILED_ITEMS[@]}"; do
      echo "  - $f"
    done
  } > "$manifest_path"

  log "Run manifest written: $manifest_path"
}

print_summary() {
  echo
  echo "=========================================================================="
  echo "Offline vault build finished"
  echo "=========================================================================="
  echo "Completed bundles: ${#COMPLETED_BUNDLES[@]}"
  for b in "${COMPLETED_BUNDLES[@]}"; do
    echo "  - $b"
  done
  echo
  echo "Failures: ${#FAILED_ITEMS[@]}"
  if [[ ${#FAILED_ITEMS[@]} -gt 0 ]]; then
    for f in "${FAILED_ITEMS[@]}"; do
      echo "  - $f"
    done
  fi
  echo
  echo "Archives location: $TARGET_ROOT/archives"
  echo "Log file         : $LOG_FILE"
  echo "=========================================================================="
}

main() {
  require_commands
  print_manifest
  list_storage_devices
  prompt_paths
  confirm_start

  log "Starting run $RUN_ID"
  log "Attempting sudo credential warm-up"
  if command -v sudo >/dev/null 2>&1; then
    if ! sudo -v >>"$LOG_FILE" 2>&1; then
      warn "sudo credential warm-up failed. apt/docker steps may fail."
    fi
  fi

  bundle_01_docker_debs_toolchains
  bundle_02_python_node_frontend
  bundle_03_cpp_sources
  bundle_04_os_embedded_vscode
  bundle_05_documentation
  bundle_06_kiwix_knowledge

  write_run_manifest
  print_summary
}

main "$@"

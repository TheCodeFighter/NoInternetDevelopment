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

APT_OPTIONAL_PACKAGES=(
  docker.io
  docker-compose-plugin
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

PYTHON_OPTIONAL_PACKAGES=(
  mysqlclient
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
  "radiolib-7.6.0.tar.gz|https://codeload.github.com/jgromes/RadioLib/tar.gz/refs/tags/7.6.0"
  "rtl-sdr-2.0.2.tar.gz|https://codeload.github.com/osmocom/rtl-sdr/tar.gz/refs/tags/v2.0.2"
)

VSCODE_EXTENSION_URLS=(
  "cpptools.vsix|https://ms-vscode.gallery.vsassets.io/_apis/public/gallery/publisher/ms-vscode/extension/cpptools/latest/assetbyname/Microsoft.VisualStudio.Services.VSIXPackage"
  "cmake-tools.vsix|https://ms-vscode.gallery.vsassets.io/_apis/public/gallery/publisher/ms-vscode/extension/cmake-tools/latest/assetbyname/Microsoft.VisualStudio.Services.VSIXPackage"
  "platformio-ide.vsix|https://platformio.gallery.vsassets.io/_apis/public/gallery/publisher/platformio/extension/platformio-ide/latest/assetbyname/Microsoft.VisualStudio.Services.VSIXPackage"
  "vscode-arduino-community.vsix|https://vscode-arduino.gallery.vsassets.io/_apis/public/gallery/publisher/vscode-arduino/extension/vscode-arduino-community/latest/assetbyname/Microsoft.VisualStudio.Services.VSIXPackage"
  "cortex-debug.vsix|https://marus25.gallery.vsassets.io/_apis/public/gallery/publisher/marus25/extension/cortex-debug/latest/assetbyname/Microsoft.VisualStudio.Services.VSIXPackage"
)

DOC_URLS=(
  "cppreference-html-book.zip|https://github.com/PeterFeicht/cppreference-doc/releases/download/v20250209/html-book-20250209.zip"
  "python-3.12.12-docs-html.tar.bz2|https://www.python.org/ftp/python/doc/3.12.12/python-3.12.12-docs-html.tar.bz2"
  "gcc-14.1-manual.pdf|https://gcc.gnu.org/onlinedocs/gcc-14.1.0/gcc.pdf"
  "arduino-nano-datasheet.pdf|https://docs.arduino.cc/resources/datasheets/A000005-datasheet.pdf"
  "rp2040-datasheet.pdf|https://pip.raspberrypi.com/documents/RP-008371-DS-rp2040-datasheet.pdf"
  "pico-getting-started.pdf|https://pip.raspberrypi.com/documents/RP-008276-DS-getting-started-with-pico.pdf"
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
ISSUE_LOG_FILE=""
DOWNLOAD_CACHE_ROOT=""
DOWNLOAD_GRANULARITY="package"
START_BUNDLE_INDEX=1
EXISTING_ITEM_STRATEGY="auto-skip"

FAILED_ITEMS=()
COMPLETED_BUNDLES=()

BUNDLE_LABELS=(
  "Docker + Debs + Toolchains"
  "Python + Node + Frontend caches"
  "C/C++ source libraries"
  "OS images + Embedded + VS Code plugins"
  "Documentation + Zeal docsets + hardware PDFs"
  "Kiwix offline knowledge"
  "Briar communication"
)

BUNDLE_FUNCTIONS=(
  bundle_01_docker_debs_toolchains
  bundle_02_python_node_frontend
  bundle_03_cpp_sources
  bundle_04_os_embedded_vscode
  bundle_05_documentation
  bundle_06_kiwix_knowledge
  bundle_07_briar_communication
)

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

info() {
  local msg="$1"
  echo "[$(timestamp)] INFO: ${msg}" | tee -a "$LOG_FILE"
}

log_issue_line() {
  local line="$1"

  if [[ -n "$ISSUE_LOG_FILE" ]]; then
    echo "$line" >> "$ISSUE_LOG_FILE"
  fi
}

warn() {
  local msg="$1"
  local line="[$(timestamp)] WARNING: ${msg}"
  echo "$line" | tee -a "$LOG_FILE" >&2
  log_issue_line "$line"
}

record_failure() {
  local item="$1"
  local line="[$(timestamp)] ERROR: ${item}"
  FAILED_ITEMS+=("$item")
  echo "$line" | tee -a "$LOG_FILE" >&2
  log_issue_line "$line"
}

is_optional_apt_package() {
  local pkg="$1"

  for optional_pkg in "${APT_OPTIONAL_PACKAGES[@]}"; do
    if [[ "$pkg" == "$optional_pkg" ]]; then
      return 0
    fi
  done

  return 1
}

is_optional_python_package() {
  local pkg="$1"

  for optional_pkg in "${PYTHON_OPTIONAL_PACKAGES[@]}"; do
    if [[ "$pkg" == "$optional_pkg" ]]; then
      return 0
    fi
  done

  return 1
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

ensure_runtime_download_tools() {
  local install_pkgs=()
  local unique_pkgs=()
  local pkg
  local -A seen=()

  if ! command -v python3 >/dev/null 2>&1; then
    install_pkgs+=(python3)
  fi

  if ! python3 -m pip --version >/dev/null 2>&1; then
    install_pkgs+=(python3-pip python3-venv)
  fi

  if ! command -v node >/dev/null 2>&1; then
    install_pkgs+=(nodejs)
  fi

  if ! command -v npm >/dev/null 2>&1; then
    install_pkgs+=(npm)
  fi

  for pkg in "${install_pkgs[@]}"; do
    if [[ -z "${seen[$pkg]+x}" ]]; then
      unique_pkgs+=("$pkg")
      seen[$pkg]=1
    fi
  done

  if [[ ${#unique_pkgs[@]} -eq 0 ]]; then
    log "Host runtime tools already available (python3/pip/node/npm)."
    return 0
  fi

  if ! command -v sudo >/dev/null 2>&1 || ! command -v apt-get >/dev/null 2>&1; then
    warn "Cannot auto-install missing runtime tools (${unique_pkgs[*]}): sudo or apt-get unavailable"
    return 1
  fi

  log "Installing missing host runtime tools: ${unique_pkgs[*]}"
  if ! sudo apt-get update >>"$LOG_FILE" 2>&1; then
    warn "apt-get update failed while installing runtime tools"
    return 1
  fi

  if ! sudo apt-get -y install "${unique_pkgs[@]}" >>"$LOG_FILE" 2>&1; then
    warn "Runtime tool install failed (${unique_pkgs[*]}). Bundle 2 may be partially skipped"
    return 1
  fi

  log "Runtime tools installation complete."
  return 0
}

ensure_docker_runtime() {
  if command -v docker >/dev/null 2>&1 && docker info >/dev/null 2>&1; then
    log "Docker runtime already available."
    return 0
  fi

  if ! command -v sudo >/dev/null 2>&1 || ! command -v apt-get >/dev/null 2>&1; then
    warn "Docker runtime is unavailable and cannot be auto-installed (sudo or apt-get missing)."
    return 1
  fi

  log "Installing Docker runtime packages: docker.io docker-compose-plugin"
  if ! sudo apt-get update >>"$LOG_FILE" 2>&1; then
    warn "apt-get update failed while installing Docker runtime"
    return 1
  fi

  if ! sudo apt-get -y install docker.io docker-compose-plugin >>"$LOG_FILE" 2>&1; then
    warn "Docker runtime package install failed"
    return 1
  fi

  if command -v systemctl >/dev/null 2>&1; then
    sudo systemctl enable --now docker >>"$LOG_FILE" 2>&1 || true
  fi

  if docker info >/dev/null 2>&1; then
    log "Docker runtime is ready."
    return 0
  fi

  warn "Docker runtime install finished but the daemon is still not reachable."
  return 1
}

print_manifest() {
  cat <<'EOF'
==========================================================================
  OFFLINE DEVELOPMENT VAULT BUILDER (Ubuntu 24.x)
==========================================================================
This script downloads and packages resources into compressed archives.
Order is strict and sequential per bundle:
  download -> compress archive -> move archive to selected target path
Interactive safeguards:
  - Choose bundle mode or package mode at startup
  - Press Enter before each item download starts
  - If item exists on target, choose skip or overwrite
  - Start from any bundle number, default is 1
  - Bundles before the selected start bundle are skipped

Bundle plan (approx):
  1) Docker + Debs + Toolchains .................... ~20 GB
  2) Python + Node + Frontend caches ............... ~10 GB
  3) C/C++ source libraries (network/server/radio) . ~5-10 GB
  4) OS images + Embedded tools + VSCode plugins ... ~5 GB
  5) Documentation + Zeal docsets + hardware PDFs .. ~5 GB
  6) Kiwix offline knowledge (StackOverflow) ....... ~40-60 GB
  7) Briar communication (Android + Desktop + docs)  ~small

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
  mkdir -p "$TARGET_ROOT/archives" "$TARGET_ROOT/manifests" "$TARGET_ROOT/logs" "$TARGET_ROOT/download_cache"

  LOG_FILE="$TARGET_ROOT/logs/offline_vault_${RUN_ID}.log"
  ISSUE_LOG_FILE="$TARGET_ROOT/logs/offline_vault_issues_${RUN_ID}.log"
  DOWNLOAD_CACHE_ROOT="$TARGET_ROOT/download_cache"
  : > "$LOG_FILE"
  : > "$ISSUE_LOG_FILE"

  echo
  echo "Target : $TARGET_ROOT"
  echo "Staging: $STAGING_ROOT"
  echo
  echo "Free space snapshot:"
  df -h "$TARGET_ROOT" "$STAGING_ROOT" | tee -a "$LOG_FILE"
  echo
}

prompt_run_preferences() {
  local choice=""

  while true; do
    read -r -p "Already-downloaded items [auto-skip/ask, default auto-skip]: " choice
    choice="${choice:-auto-skip}"

    case "${choice,,}" in
      auto-skip|ask)
        EXISTING_ITEM_STRATEGY="${choice,,}"
        break
        ;;
      *)
        echo "Please enter auto-skip or ask."
        ;;
    esac
  done

  while true; do
    read -r -p "Download confirmation mode [package/bundle, default package]: " choice
    choice="${choice:-package}"

    case "${choice,,}" in
      package|bundle)
        DOWNLOAD_GRANULARITY="${choice,,}"
        break
        ;;
      *)
        echo "Please enter package or bundle."
        ;;
    esac
  done

  while true; do
    read -r -p "Start from bundle number [1-7, default 1]: " choice
    choice="${choice:-1}"

    if [[ "$choice" =~ ^[1-7]$ ]]; then
      START_BUNDLE_INDEX="$choice"
      break
    fi

    echo "Please enter a number from 1 to 7."
  done

  echo
  echo "Existing items    : $EXISTING_ITEM_STRATEGY"
  echo "Selected mode        : $DOWNLOAD_GRANULARITY"
  echo "Selected start bundle: $START_BUNDLE_INDEX"
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

target_cache_path_for_stage_path() {
  local stage_path="$1"
  local rel=""

  if [[ "$stage_path" == "$STAGING_ROOT"/* ]]; then
    rel="${stage_path#"$STAGING_ROOT"/}"
  else
    rel="$(basename "$stage_path")"
  fi

  echo "$DOWNLOAD_CACHE_ROOT/$rel"
}

prompt_enter_for_item() {
  local label="$1"

  if [[ "$DOWNLOAD_GRANULARITY" == "package" ]]; then
    read -r -p "Press Enter to continue item: ${label} " _
  fi
}

prompt_enter_for_bundle() {
  local label="$1"

  read -r -p "Press Enter to start bundle: ${label} " _
}

user_wants_skip_existing_item() {
  local label="$1"
  local target_path="$2"
  local choice=""

  while true; do
    read -r -p "Target already has ${label} at ${target_path}. Choose [s]kip or [o]verwrite: " choice
    case "${choice,,}" in
      s|skip)
        return 0
        ;;
      o|overwrite)
        return 1
        ;;
      *)
        echo "Please type s (skip) or o (overwrite)."
        ;;
    esac
  done
}

prepare_item_for_download() {
  local label="$1"
  local output_path="$2"
  local target_cache_path=""

  prompt_enter_for_item "$label"

  mkdir -p "$(dirname "$output_path")"
  target_cache_path="$(target_cache_path_for_stage_path "$output_path")"
  mkdir -p "$(dirname "$target_cache_path")"

  if [[ -f "$target_cache_path" ]]; then
    if [[ "$EXISTING_ITEM_STRATEGY" == "auto-skip" ]]; then
      cp -f "$target_cache_path" "$output_path"
      log "Auto-skipped existing target item: $label"
      return 1
    fi

    if user_wants_skip_existing_item "$label" "$target_cache_path"; then
      cp -f "$target_cache_path" "$output_path"
      log "Skip selected, reused existing target item: $label"
      return 1
    fi

    rm -f "$target_cache_path" "$output_path"
    log "Overwrite selected for target item: $label"
  fi

  return 0
}

persist_item_to_target_cache() {
  local output_path="$1"
  local target_cache_path=""

  target_cache_path="$(target_cache_path_for_stage_path "$output_path")"
  mkdir -p "$(dirname "$target_cache_path")"
  cp -f "$output_path" "$target_cache_path"
}

persist_item_to_target_cache_and_cleanup() {
  local output_path="$1"

  persist_item_to_target_cache "$output_path"
  rm -f "$output_path"
}

sync_target_cache_to_stage_dir() {
  local stage_dir="$1"
  local target_cache_dir=""

  target_cache_dir="$(target_cache_path_for_stage_path "$stage_dir")"
  if [[ -d "$target_cache_dir" ]]; then
    mkdir -p "$stage_dir"
    cp -af "$target_cache_dir"/. "$stage_dir"/
  fi
}

sync_stage_dir_to_target_cache() {
  local stage_dir="$1"
  local target_cache_dir=""

  if [[ ! -d "$stage_dir" ]]; then
    return 0
  fi

  if [[ -z "$(find "$stage_dir" -mindepth 1 -print -quit 2>/dev/null)" ]]; then
    return 0
  fi

  target_cache_dir="$(target_cache_path_for_stage_path "$stage_dir")"
  mkdir -p "$target_cache_dir"
  if command -v rsync >/dev/null 2>&1; then
    rsync -a --exclude='partial/' "$stage_dir"/ "$target_cache_dir"/ >/dev/null 2>&1 || true
  else
    find "$stage_dir" -mindepth 1 -maxdepth 1 ! -name 'partial' -exec cp -af {} "$target_cache_dir"/ \;
  fi
}

download_url() {
  local label="$1"
  local url="$2"
  local output_path="$3"

  if ! prepare_item_for_download "$label" "$output_path"; then
    return 0
  fi

  if [[ -f "$output_path" ]]; then
    log "Already present, skipping: $label"
    persist_item_to_target_cache_and_cleanup "$output_path"
    return 0
  fi

  log "Downloading: $label"
  if wget -c --tries=4 --timeout=45 -O "$output_path" "$url" >>"$LOG_FILE" 2>&1; then
    persist_item_to_target_cache_and_cleanup "$output_path"
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
  local apt_marker
  local image
  local safe_name
  local output_tar
  local docker_ok=0
  local docker_cmd=(docker)

  log "=== Bundle 1/7: Docker + Debs + Toolchains ==="
  rm -rf "$bundle_dir"
  mkdir -p "$bundle_dir/debs" "$bundle_dir/docker" "$bundle_dir/meta" "$bundle_dir/meta/apt_markers"

  sync_target_cache_to_stage_dir "$bundle_dir/debs"
  sync_target_cache_to_stage_dir "$bundle_dir/docker"
  sync_target_cache_to_stage_dir "$bundle_dir/meta/apt_markers"

  printf '%s\n' "${APT_PACKAGES[@]}" > "$bundle_dir/meta/apt_seed_packages.txt"
  printf '%s\n' "${DOCKER_IMAGES[@]}" > "$bundle_dir/meta/docker_images.txt"

  if command -v apt-get >/dev/null 2>&1 && command -v sudo >/dev/null 2>&1; then
    log "Running apt-get update (sudo)..."
    if sudo apt-get update >>"$LOG_FILE" 2>&1; then
      for pkg in "${APT_PACKAGES[@]}"; do
        apt_marker="$bundle_dir/meta/apt_markers/${pkg}.done"
        if ! prepare_item_for_download "APT package: $pkg" "$apt_marker"; then
          log "Skipping apt package by user choice: $pkg"
          continue
        fi

        log "Downloading .deb seed package (with deps): $pkg"
        if ! sudo apt-get -y --download-only -o Dir::Cache::archives="$bundle_dir/debs" install "$pkg" >>"$LOG_FILE" 2>&1; then
          if is_optional_apt_package "$pkg"; then
            info "apt download failed for optional package: $pkg"
          else
            record_failure "apt download failed for package: $pkg"
          fi
        else
          date -Iseconds > "$apt_marker"
          persist_item_to_target_cache_and_cleanup "$apt_marker"
        fi
        sync_stage_dir_to_target_cache "$bundle_dir/debs"
        find "$bundle_dir/debs" -mindepth 1 -maxdepth 1 ! -name 'partial' -exec rm -rf {} + 2>/dev/null || true
      done
      rm -rf "$bundle_dir/debs/partial"
      sync_stage_dir_to_target_cache "$bundle_dir/debs"
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
        output_tar="$bundle_dir/docker/${safe_name}.tar"

        if ! prepare_item_for_download "Docker image: $image" "$output_tar"; then
          log "Skipping Docker image by user choice: $image"
          continue
        fi

        log "Pulling Docker image: $image"
        if "${docker_cmd[@]}" pull "$image" >>"$LOG_FILE" 2>&1; then
          log "Saving Docker image: $image"
          if ! "${docker_cmd[@]}" save "$image" -o "$output_tar" >>"$LOG_FILE" 2>&1; then
            record_failure "docker save failed: $image"
          else
            persist_item_to_target_cache_and_cleanup "$output_tar"
          fi
        else
          record_failure "docker pull failed: $image"
        fi
      done

      sync_stage_dir_to_target_cache "$bundle_dir/docker"
    else
      record_failure "Skipping docker images: Docker daemon not accessible"
    fi
  else
    record_failure "Skipping docker images: docker command not found"
  fi

  sync_target_cache_to_stage_dir "$bundle_dir/debs"
  sync_target_cache_to_stage_dir "$bundle_dir/docker"
  sync_target_cache_to_stage_dir "$bundle_dir/meta/apt_markers"

  archive_bundle "$bundle_key" "$bundle_dir"
}

bundle_02_python_node_frontend() {
  local bundle_key="02_python_node_frontend"
  local bundle_dir="$STAGING_ROOT/$bundle_key"
  local pkg
  local pip_marker
  local npm_pack_marker
  local npm_cache_marker

  log "=== Bundle 2/7: Python + Node + Frontend ==="
  rm -rf "$bundle_dir"
  mkdir -p "$bundle_dir/python_wheels" "$bundle_dir/node/npm_packs" "$bundle_dir/node/npm_cache" "$bundle_dir/node/frontend_seed" "$bundle_dir/meta" "$bundle_dir/meta/pip_markers" "$bundle_dir/meta/npm_pack_markers"

  sync_target_cache_to_stage_dir "$bundle_dir/python_wheels"
  sync_target_cache_to_stage_dir "$bundle_dir/node/npm_packs"
  sync_target_cache_to_stage_dir "$bundle_dir/node/npm_cache"
  sync_target_cache_to_stage_dir "$bundle_dir/node/frontend_seed"
  sync_target_cache_to_stage_dir "$bundle_dir/meta/pip_markers"
  sync_target_cache_to_stage_dir "$bundle_dir/meta/npm_pack_markers"

  printf '%s\n' "${PYTHON_PACKAGES[@]}" > "$bundle_dir/meta/python_packages.txt"
  printf '%s\n' "${NPM_PACKAGES[@]}" > "$bundle_dir/meta/npm_packages.txt"

  download_url "CPython 3.12.9 source" "https://www.python.org/ftp/python/3.12.9/Python-3.12.9.tgz" "$bundle_dir/python_wheels/Python-3.12.9.tgz"

  if command -v python3 >/dev/null 2>&1 && python3 -m pip --version >/dev/null 2>&1; then
    for pkg in "${PYTHON_PACKAGES[@]}"; do
      pip_marker="$bundle_dir/meta/pip_markers/${pkg}.done"
      if ! prepare_item_for_download "Python package: $pkg" "$pip_marker"; then
        log "Skipping Python package by user choice: $pkg"
        continue
      fi

      log "Downloading pip package: $pkg"
      if ! python3 -m pip download --prefer-binary --dest "$bundle_dir/python_wheels" "$pkg" >>"$LOG_FILE" 2>&1; then
        if is_optional_python_package "$pkg"; then
          info "pip download failed for optional package: $pkg"
        else
          record_failure "pip download failed for package: $pkg"
        fi
      else
        date -Iseconds > "$pip_marker"
        persist_item_to_target_cache_and_cleanup "$pip_marker"
      fi
    done

    sync_stage_dir_to_target_cache "$bundle_dir/python_wheels"
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
      npm_pack_marker="$bundle_dir/meta/npm_pack_markers/${pkg}.done"
      if ! prepare_item_for_download "NPM package: $pkg" "$npm_pack_marker"; then
        log "Skipping NPM package by user choice: $pkg"
        continue
      fi

      log "Downloading npm pack: $pkg"
      if ! npm pack "$pkg" --pack-destination "$bundle_dir/node/npm_packs" >>"$LOG_FILE" 2>&1; then
        record_failure "npm pack failed for package: $pkg"
      else
        date -Iseconds > "$npm_pack_marker"
        persist_item_to_target_cache_and_cleanup "$npm_pack_marker"
      fi
    done

    sync_stage_dir_to_target_cache "$bundle_dir/node/npm_packs"

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

    npm_cache_marker="$bundle_dir/meta/npm_cache_warmup.done"
    if prepare_item_for_download "NPM cache warmup install (frontend seed)" "$npm_cache_marker"; then
      log "Building npm cache warmup project"
      if ! (
        cd "$bundle_dir/node/frontend_seed" && \
        npm install --ignore-scripts --no-audit --no-fund --cache "$bundle_dir/node/npm_cache"
      ) >>"$LOG_FILE" 2>&1; then
        record_failure "npm cache warmup install failed"
      else
        date -Iseconds > "$npm_cache_marker"
        persist_item_to_target_cache_and_cleanup "$npm_cache_marker"
      fi
    else
      log "Skipping npm cache warmup by user choice"
    fi

    sync_stage_dir_to_target_cache "$bundle_dir/node/npm_cache"
    sync_stage_dir_to_target_cache "$bundle_dir/node/frontend_seed"
  else
    record_failure "Skipping npm bundle: npm command not found"
  fi

  sync_target_cache_to_stage_dir "$bundle_dir/python_wheels"
  sync_target_cache_to_stage_dir "$bundle_dir/node/npm_packs"
  sync_target_cache_to_stage_dir "$bundle_dir/node/npm_cache"
  sync_target_cache_to_stage_dir "$bundle_dir/node/frontend_seed"
  sync_target_cache_to_stage_dir "$bundle_dir/meta/pip_markers"
  sync_target_cache_to_stage_dir "$bundle_dir/meta/npm_pack_markers"

  archive_bundle "$bundle_key" "$bundle_dir"
}

bundle_03_cpp_sources() {
  local bundle_key="03_cpp_sources"
  local bundle_dir="$STAGING_ROOT/$bundle_key"
  local entry
  local filename
  local url

  log "=== Bundle 3/7: C/C++ source libraries ==="
  rm -rf "$bundle_dir"
  mkdir -p "$bundle_dir/sources" "$bundle_dir/meta"

  for entry in "${CPP_SOURCE_URLS[@]}"; do
    filename="${entry%%|*}"
    url="${entry#*|}"
    download_url "$filename" "$url" "$bundle_dir/sources/$filename"
  done

  printf '%s\n' "${CPP_SOURCE_URLS[@]}" > "$bundle_dir/meta/cpp_sources_manifest.txt"

  sync_target_cache_to_stage_dir "$bundle_dir/sources"
  sync_target_cache_to_stage_dir "$bundle_dir/meta"

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
  local core
  local core_marker

  log "=== Bundle 4/7: OS images + embedded + VSCode plugins ==="
  rm -rf "$bundle_dir"
  mkdir -p "$bundle_dir/images" "$bundle_dir/arduino" "$bundle_dir/vscode" "$bundle_dir/meta" "$bundle_dir/meta/arduino_core_markers"

  sync_target_cache_to_stage_dir "$bundle_dir/images"
  sync_target_cache_to_stage_dir "$bundle_dir/arduino"
  sync_target_cache_to_stage_dir "$bundle_dir/vscode"
  sync_target_cache_to_stage_dir "$bundle_dir/meta/arduino_core_markers"

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
        for core in arduino:avr arduino:megaavr arduino:mbed_nano; do
          core_marker="$bundle_dir/meta/arduino_core_markers/${core//:/_}.done"
          if ! prepare_item_for_download "Arduino core: $core" "$core_marker"; then
            log "Skipping Arduino core by user choice: $core"
            continue
          fi

          if ! "$cli_bin" core download "$core" --config-file "$cli_cfg" >>"$LOG_FILE" 2>&1; then
            record_failure "arduino-cli core download failed: $core"
          else
            date -Iseconds > "$core_marker"
            persist_item_to_target_cache_and_cleanup "$core_marker"
          fi
        done

        sync_stage_dir_to_target_cache "$bundle_dir/arduino/data"
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

  sync_stage_dir_to_target_cache "$bundle_dir/vscode"
  sync_stage_dir_to_target_cache "$bundle_dir/images"
  sync_stage_dir_to_target_cache "$bundle_dir/arduino"

  sync_target_cache_to_stage_dir "$bundle_dir/images"
  sync_target_cache_to_stage_dir "$bundle_dir/arduino"
  sync_target_cache_to_stage_dir "$bundle_dir/vscode"
  sync_target_cache_to_stage_dir "$bundle_dir/meta/arduino_core_markers"

  printf '%s\n' "${VSCODE_EXTENSION_URLS[@]}" > "$bundle_dir/meta/vscode_extensions_manifest.txt"
  archive_bundle "$bundle_key" "$bundle_dir"
}

bundle_05_documentation() {
  local bundle_key="05_documentation"
  local bundle_dir="$STAGING_ROOT/$bundle_key"
  local entry
  local filename
  local url

  log "=== Bundle 5/7: Documentation + Zeal + hardware PDFs ==="
  rm -rf "$bundle_dir"
  mkdir -p "$bundle_dir/docs" "$bundle_dir/meta"

  for entry in "${DOC_URLS[@]}"; do
    filename="${entry%%|*}"
    url="${entry#*|}"
    download_url "$filename" "$url" "$bundle_dir/docs/$filename"
  done

  printf '%s\n' "${DOC_URLS[@]}" > "$bundle_dir/meta/docs_manifest.txt"

  sync_target_cache_to_stage_dir "$bundle_dir/docs"
  sync_target_cache_to_stage_dir "$bundle_dir/meta"

  archive_bundle "$bundle_key" "$bundle_dir"
}

bundle_06_kiwix_knowledge() {
  local bundle_key="06_kiwix_knowledge"
  local bundle_dir="$STAGING_ROOT/$bundle_key"

  log "=== Bundle 6/7: Kiwix offline knowledge ==="
  rm -rf "$bundle_dir"
  mkdir -p "$bundle_dir/kiwix" "$bundle_dir/meta"

  download_latest_from_index \
    "Kiwix StackOverflow ZIM" \
    "https://download.kiwix.org/zim/stack_exchange/" \
    "stackoverflow\\.com_en_all_[0-9]{4}-[0-9]{2}\\.zim" \
    "$bundle_dir/kiwix/stackoverflow_latest.zim"

  if ! download_latest_from_index \
    "Kiwix Desktop x86_64 AppImage" \
    "https://download.kiwix.org/release/kiwix-desktop/" \
    "kiwix-desktop[^\"']*x86_64[^\"']*\.(AppImage|appimage)" \
    "$bundle_dir/kiwix/kiwix-desktop_latest_x86_64.AppImage"; then

    download_latest_from_index \
      "Kiwix Desktop x86_64 tar.gz" \
      "https://download.kiwix.org/release/kiwix-desktop/" \
      "kiwix-desktop[^\"']*x86_64[^\"']*\\.tar\\.gz" \
      "$bundle_dir/kiwix/kiwix-desktop_latest_x86_64.tar.gz"
  fi

  sync_target_cache_to_stage_dir "$bundle_dir/kiwix"
  sync_target_cache_to_stage_dir "$bundle_dir/meta"

  archive_bundle "$bundle_key" "$bundle_dir"
}

bundle_07_briar_communication() {
  local bundle_key="07_briar_communication"
  local bundle_dir="$STAGING_ROOT/$bundle_key"

  log "=== Bundle 7/7: Briar communication ==="
  rm -rf "$bundle_dir"
  mkdir -p "$bundle_dir/android" "$bundle_dir/desktop" "$bundle_dir/docs" "$bundle_dir/meta"

  download_url \
    "Briar Android APK" \
    "https://briarproject.org/apk/briar.apk" \
    "$bundle_dir/android/briar.apk"

  download_url \
    "Briar Mailbox APK" \
    "https://briarproject.org/apk/mailbox.apk" \
    "$bundle_dir/android/mailbox.apk"

  download_url \
    "Briar Desktop Ubuntu 24.04 DEB" \
    "https://desktop.briarproject.org/debs/noble/briar-desktop-ubuntu-24.04.deb" \
    "$bundle_dir/desktop/briar-desktop-ubuntu-24.04.deb"

  download_url \
    "Briar Desktop Linux x64 AppImage" \
    "https://desktop.briarproject.org/appimage/briar-desktop-x64.AppImage" \
    "$bundle_dir/desktop/briar-desktop-x64.AppImage"

  download_url \
    "Briar Download Page" \
    "https://briarproject.org/download-briar/" \
    "$bundle_dir/docs/briar-download.html"

  download_url \
    "Briar Desktop Download Page" \
    "https://briarproject.org/download-briar-desktop/" \
    "$bundle_dir/docs/briar-desktop-download.html"

  download_url \
    "Briar Direct APK Install Guide" \
    "https://briarproject.org/installing-apps-via-direct-download/" \
    "$bundle_dir/docs/briar-direct-download.html"

  download_url \
    "Briar Get Involved Page" \
    "https://briarproject.org/get-involved/" \
    "$bundle_dir/docs/briar-get-involved.html"

  download_url \
    "Briar Copyright Page" \
    "https://briarproject.org/copyright/" \
    "$bundle_dir/docs/briar-copyright.html"

  cat > "$bundle_dir/meta/README.txt" <<'EOF'
Briar communication bundle

Android is the primary off-grid client.
Use Briar Desktop on Ubuntu/Linux as a companion client.

Offline documentation included in this bundle:
- Briar download pages for Android and desktop
- Briar direct APK install instructions
- Briar get involved page
- Briar copyright page

Desktop capability note:
- Briar Desktop supports private chats, groups, forums, blogs, LAN/Wi-Fi, Tor, and Briar Mailbox.
- Briar Desktop does not support nearby Bluetooth contact addition.
- Briar Android supports Bluetooth and nearby/off-grid contact setup.

Recommended order:
1. Install Briar Android.
2. Install Briar Mailbox if you want better connectivity.
3. Install Briar Desktop on Ubuntu if you want a second device.
4. Pair or add contacts from Android first when Bluetooth/off-grid setup matters.
EOF

  sync_target_cache_to_stage_dir "$bundle_dir/android"
  sync_target_cache_to_stage_dir "$bundle_dir/desktop"
  sync_target_cache_to_stage_dir "$bundle_dir/docs"
  sync_target_cache_to_stage_dir "$bundle_dir/meta"

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
  echo "Confirmation mode: $DOWNLOAD_GRANULARITY"
  echo "Start bundle     : $START_BUNDLE_INDEX"
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
  echo "Download cache    : $DOWNLOAD_CACHE_ROOT"
  echo "Log file          : $LOG_FILE"
  echo "Issues log        : $ISSUE_LOG_FILE"
  echo "=========================================================================="
}

run_selected_bundles() {
  local bundle_index
  local bundle_array_index

  for ((bundle_index = START_BUNDLE_INDEX; bundle_index <= ${#BUNDLE_FUNCTIONS[@]}; bundle_index++)); do
    bundle_array_index=$((bundle_index - 1))

    if [[ "$DOWNLOAD_GRANULARITY" == "bundle" ]]; then
      prompt_enter_for_bundle "Bundle ${bundle_index}/${#BUNDLE_FUNCTIONS[@]}: ${BUNDLE_LABELS[$bundle_array_index]}"
    fi

    log "Starting Bundle ${bundle_index}/${#BUNDLE_FUNCTIONS[@]}: ${BUNDLE_LABELS[$bundle_array_index]}"
    "${BUNDLE_FUNCTIONS[$bundle_array_index]}"
  done
}

main() {
  require_commands
  print_manifest
  list_storage_devices
  prompt_paths
  prompt_run_preferences
  confirm_start

  log "Starting run $RUN_ID"
  log "Attempting sudo credential warm-up"
  if command -v sudo >/dev/null 2>&1; then
    if ! sudo -v >>"$LOG_FILE" 2>&1; then
      warn "sudo credential warm-up failed. apt/docker steps may fail."
    fi
  fi

  ensure_runtime_download_tools
  ensure_docker_runtime

  run_selected_bundles

  write_run_manifest
  print_summary
}

main "$@"

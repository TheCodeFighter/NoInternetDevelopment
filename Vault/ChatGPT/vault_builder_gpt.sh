#!/usr/bin/env bash

set -euo pipefail

TMP_DIR="/tmp/offline-build"
MANIFEST="manifest.txt"

# ---------- UI ----------
echo "=== Offline Dev Bundle Builder ==="
read -rp "Enter target directory (USB mount point): " TARGET

if [ ! -d "$TARGET" ]; then
    echo "Target does not exist!"
    exit 1
fi

mkdir -p "$TMP_DIR"
mkdir -p "$TARGET/manifests"

log() {
    echo "[+] $1"
    echo "$1" >> "$TARGET/manifests/$MANIFEST"
}

compress_and_move() {
    local name=$1
    log "Compressing $name"

    tar --use-compress-program=zstd -cf "${name}.tar.zst" "$name"

    mv "${name}.tar.zst" "$TARGET/"
    rm -rf "$name"
}

# ---------- TOOLCHAINS ----------
download_toolchains() {
    mkdir -p toolchains && cd toolchains

    log "Downloading CMake"
    wget https://github.com/Kitware/CMake/releases/download/v3.29.0/cmake-3.29.0-linux-x86_64.tar.gz
    tar -xf cmake-*.tar.gz

    log "Downloading Ninja"
    wget https://github.com/ninja-build/ninja/releases/download/v1.11.1/ninja-linux.zip
    unzip ninja-linux.zip

    log "Downloading LLVM/Clang"
    wget https://github.com/llvm/llvm-project/releases/download/llvmorg-18.1.2/clang+llvm-18.1.2-x86_64-linux-gnu.tar.xz
    tar -xf clang+llvm-*.tar.xz

    log "Downloading GCC ARM"
    wget https://developer.arm.com/-/media/Files/downloads/gnu/13.2.rel1/binrel/gcc-arm-none-eabi-13.2.rel1-x86_64-linux.tar.xz
    tar -xf gcc-arm-none-eabi-*.tar.xz

    cd ..
    compress_and_move toolchains
}

# ---------- DOCKER ----------
download_docker_images() {
    mkdir -p docker && cd docker

    images=(
        "ubuntu:24.04"
        "debian:bookworm"
        "python:3.12"
        "node:20"
        "postgres:16"
        "redis:7"
        "nginx:alpine"
    )

    for img in "${images[@]}"; do
        log "Pulling $img"
        docker pull "$img"

        fname=$(echo "$img" | tr '/:' '_')
        log "Saving $img"
        docker save "$img" -o "${fname}.tar"
    done

    cd ..
    compress_and_move docker
}

# ---------- PYTHON ----------
download_python() {
    mkdir -p python && cd python

    log "Downloading Python"
    wget https://www.python.org/ftp/python/3.12.2/Python-3.12.2.tgz

    mkdir wheelhouse

    libs=(
        numpy pandas requests httpx flask fastapi sqlalchemy psycopg2 matplotlib
    )

    log "Downloading Python wheels"
    pip download -d wheelhouse "${libs[@]}"

    cd ..
    compress_and_move python
}

# ---------- C/C++ LIBS ----------
download_cpp_libs() {
    mkdir -p libs && cd libs

    log "Downloading nlohmann/json"
    git clone https://github.com/nlohmann/json.git

    log "Downloading spdlog"
    git clone https://github.com/gabime/spdlog.git

    log "Downloading fmt"
    git clone https://github.com/fmtlib/fmt.git

    log "Downloading pugixml"
    git clone https://github.com/zeux/pugixml.git

    log "Downloading cpp-httplib"
    git clone https://github.com/yhirose/cpp-httplib.git

    cd ..
    compress_and_move libs
}

# ---------- OS IMAGES ----------
download_os_images() {
    mkdir -p os-images && cd os-images

    log "Downloading Raspberry Pi OS Lite"
    wget https://downloads.raspberrypi.com/raspios_lite_arm64_latest -O rpi_os.zip

    log "Downloading Arduino CLI"
    wget https://downloads.arduino.cc/arduino-cli/arduino-cli_latest_Linux_64bit.tar.gz

    cd ..
    compress_and_move os-images
}

# ---------- MAIN ----------
cd "$TMP_DIR"

download_toolchains
download_docker_images
download_python
download_cpp_libs
download_os_images

log "DONE"

echo "All files saved to $TARGET"
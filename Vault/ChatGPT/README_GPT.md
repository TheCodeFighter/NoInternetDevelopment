# Offline Development Bundle Builder

## Overview

This project provides a Bash-based automation script for building a self-contained offline development environment.

The script downloads, packages, compresses, and transfers essential development resources onto a removable storage device (e.g., USB drive). The resulting bundle enables software development without internet access, targeting embedded, backend, and systems programming workflows.

### Key Features

Fully offline-ready development environment
Supports C, C++, Python, and Node.js ecosystems
Includes:
Toolchains (GCC, Clang, CMake, Ninja)
Docker images
Python packages (wheelhouse)
C/C++ libraries (source-based)
OS images (Raspberry Pi, Arduino)
Transparent manifest logging
Compression using zstd (fast + efficient)
Modular structure (easy to extend)

### Directory Structure (on USB)

```Shell
offline-dev/
├── docker/
├── toolchains/
├── python/
├── libs/
├── os-images/
├── manifests/
└── *.tar.zst
```

Each component is stored as a compressed archive (.tar.zst) for portability and space efficiency.

## Requirements

### System Requirements

Ubuntu 24.x (recommended)
At least 110 GB available storage
Docker installed and running
Python + pip installed
Basic tools:
wget
git
tar
zstd
unzip

### Install Dependencies

```Shell
sudo apt update
sudo apt install -y
wget git tar zstd unzip
python3 python3-pip
docker.io
```

## Usage

### Step 1: Prepare USB / Target Directory

Mount your USB device and note its path:

```Shell
lsblk
```

Example mount point:

```Shell
/media/user/USB_DRIVE
```

### Step 2: Run Script

```Shell
chmod +x offline_builder.sh
./offline_builder.sh
```

You will be prompted:

```Shell
Enter target directory (USB mount point):
```

### Step 3: Automated Process

The script will:

- Download resources into `/tmp/offline-build`
- Compress each module (`.tar.zst`)
- Move compressed archive to USB
- Clean temporary files
- Log actions to manifest file

## Modules Included

1. Toolchains
    CMake
    Ninja
    LLVM / Clang
    GCC ARM (embedded)

    Purpose:

    Native + cross-compilation support
    Embedded systems development

2. Docker Images

    Images are:

    Pulled via Docker
    Exported using docker save

    Included:

    ubuntu:24.04
    debian:bookworm
    python:3.12
    node:20
    postgres:16
    redis:7
    nginx:alpine

    Usage offline:

    ```Shell
    docker load -i ubuntu_24.04.tar
    ```

3. Python Environment

    Includes:

    Python source tarball
    Pre-downloaded pip packages (wheelhouse)

    Libraries:

    numpy
    pandas
    requests
    httpx
    flask
    fastapi
    sqlalchemy
    psycopg2
    matplotlib

    Offline install:

    ```Shell
    pip install --no-index --find-links=wheelhouse numpy
    ```

4. C/C++ Libraries

    Cloned from source:

    nlohmann/json
    spdlog
    fmt
    pugixml
    cpp-httplib

    Advantages:

    No binary compatibility issues
    Buildable across architectures

5. OS / Embedded

    Includes:

    Raspberry Pi OS Lite (ARM64)
    Arduino CLI

    Use cases:

    Embedded Linux development
    Microcontroller programming

## Compression Strategy

All modules are compressed using:

```Shell
tar --use-compress-program=zstd
```

Advantages:

- Faster than gzip
- Better compression ratio
- Suitable for large datasets

## Manifest Logging

Each operation is logged to:

```Shell
/manifests/manifest.txt
```

This ensures:

- Traceability
- Reproducibility
- Debugging capability
- Important Notes

## Disk Space Constraints

You have ~110 GB, so:

Avoid adding large datasets blindly
Docker images and Python packages can grow quickly
Not Included (by default)
Full Wikipedia (Kiwix) (~50 GB)
Full npm ecosystem
Full Boost build artifacts

These can be added manually if needed.

## Extending the Script

You can easily add new modules:

Example:

```Shell
download_custom() {
mkdir -p custom && cd custom

wget <your_resource>

cd ..
compress_and_move custom

}
```

Then call it in main:

```Shell
download_custom
```

Recommended Improvements
Reliability
Add checksum validation (sha256)
Add retry logic for downloads
Use wget -c for resume support
Performance
Parallel downloads
Prebuilt package mirrors
Usability
Interactive menu (select modules)
Progress bar (pv)
Disk space validation before each step
Offline Usage Workflow
Plug in USB
Extract needed module:

```Shell
tar -xf toolchains.tar.zst
```

Use tools locally

Example:

```Shell
./cmake/bin/cmake
```

Security Considerations
All downloads come from public sources (GitHub, official vendors)
No integrity verification is implemented by default
You should:
Verify checksums manually
Pin versions explicitly
Limitations
No package dependency resolution offline (manual)
No automatic environment setup
Docker images may become outdated
Conclusion

This script provides a practical, modular, and reproducible approach to building a fully offline development environment tailored for:

Embedded systems
Backend services
Systems programming

It is intentionally transparent and extensible, allowing you to evolve it into a production-grade offline infrastructure.

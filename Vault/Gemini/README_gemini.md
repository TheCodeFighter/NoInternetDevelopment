# Sovereign Vault: Offline Development Environment README

## Overview

This archive contains a complete, self-sustained development ecosystem for C/C++, Python, Frontend (Node.js/React), and embedded systems (Raspberry Pi, Arduino). It is designed to operate with zero internet connectivity.

1. System Requirements (Offline Host)
    Ubuntu 24.x or similar Debian-based Linux distribution.

    At least 110GB of free space.

    Docker installed (if not, use the provided .deb packages).

2. Restoring Host Toolchains (Apt Packages)
    We use local .deb files to bypass the apt repository network check. This is why we pre-downloaded all dependencies during the vault creation process to ensure no missing links occur during an offline installation.

    Navigate to the debs folder and install the packages:

    ```Shell
    cd /path/to/usb/debs
    tar -xzvf apt_packages.tar.gz
    sudo dpkg -i ./vault_staging/debs/*.deb
    ```

    (Note: Run the dpkg command twice if you encounter circular dependency errors during the first pass. This is standard behavior for offline Debian package installations.)

3. Loading Docker Images
    Docker usually pulls from external registries like Docker Hub. Since the environment is air-gapped, we load the filesystem directly from our compressed tarballs. This avoids any network DNS resolution timeouts and instantly registers the image locally.

    Navigate to the docker folder:

    ```Shell
    cd /path/to/usb/docker
    docker load < ubuntu_24.04.tar.gz
    docker load < alpine_latest.tar.gz
    docker load < python_3.12-slim.tar.gz
    docker load < postgres_16-alpine.tar.gz
    ```

4. Offline Python Environment
    When installing Python packages offline, pip will by default try to reach PyPI.org. We must use --no-index to explicitly disable this network check and --find-links to point directly to our downloaded wheels. This prevents installation failures and forces pip to resolve dependencies strictly from the local folder.

    Navigate to the python folder, extract the wheels, and install:

    ```Shell
    cd /path/to/usb/python
    tar -xzvf python_wheels.tar.gz
    pip install --no-index --find-links=./vault_staging/python_wheels numpy pandas fastapi uvicorn psycopg2-binary sqlalchemy pydantic
    ```

5. C/C++ Development with Docker
    To compile C/C++ projects using the provided libraries (Boost, Nlohmann, Crow, etc.) without cluttering your host system, use Docker volume mounts. We mount the libraries directly into the container so the compiler can access the source files directly from the USB/disk without needing a package manager.

    First, extract the libraries on your host:

    ```Shell
    cd /path/to/usb/cpp_libs
    tar -xzvf boost.tar.gz
    tar -xzvf crow.tar.gz

    Repeat for other library archives
    ```

    Run your development container, mapping the libraries to /usr/src/libs:

    ```Shell
    docker run -it -v /path/to/usb/cpp_libs:/usr/src/libs ubuntu:24.04 /bin/bash
    ```

    Inside the container, configure your CMakeLists.txt or compiler flags (e.g., -I/usr/src/libs/...) to reference this mounted directory.

6. Frontend Setup (Node.js & React)
    Extract the Node binaries and append them to your system path. This enables JavaScript execution and npm package management locally without needing a network connection.

    ```Shell
    cd /path/to/usb/frontend
    tar -xzvf frontend_tools.tar.gz
    cd vault_staging/frontend
    tar -xJvf node-v20.11.1-linux-x64.tar.xz
    export PATH=$PWD/node-v20.11.1-linux-x64/bin:$PATH
    npm install -g react-.tgz vite-.tgz tailwindcss-*.tgz
    ```

7. VS Code Extensions Setup
    The VS Code marketplace requires an active internet connection. To bypass this, install the extensions manually from the provided VSIX packages.

    Open VS Code.

    Go to the Extensions view (Ctrl+Shift+X).

    Click the ... menu in the top right corner of the Extensions pane.

    Select Install from VSIX...

    Navigate to the /path/to/usb/vscode/ directory and select cpptools.vsix and vscode-arduino.vsix.

8. Hardware & OS Images
    Use a standard tool like dd to flash the .img.xz file to your SD card for the Raspberry Pi Zero 2W. For the Arduino IDE, run the AppImage directly. AppImages are used here because they contain all necessary dependencies bundled inside a single executable file, eliminating the need for system-level shared libraries.

    ```Shell
    cd /path/to/usb/hardware
    chmod +x arduino-ide.AppImage
    ./arduino-ide.AppImage
    ```

9. Accessing the Knowledge Base (Kiwix)
    We use Kiwix to read .zim files because it utilizes a highly compressed, pre-indexed format. This allows you to perform fast, local searches across massive databases like StackOverflow without needing a dedicated SQL/NoSQL database running in the background.

    Navigate to the knowledge folder and run the reader:

    ```Shell
    cd /path/to/usb/docs_knowledge
    ./kiwix-reader.AppImage
    ```

    Once the application launches, select stackoverflow.zim to access the offline database.

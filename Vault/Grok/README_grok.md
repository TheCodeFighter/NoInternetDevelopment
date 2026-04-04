# Offline Resources Downloader

Purpose: Bash script for Ubuntu 24.x to download ~110GB of offline dev resources (Docker, toolchains, Python/Node libs, OS images, docs, Kiwix, C/C++ libs, frontend) into compressed .tar.gz archives. Saves directly to USB/host. All files Docker/host-runnable.
Resources Downloaded

Docker_Debs_Toolchains (20GB) – docker debs, gcc/clang/cmake, ARM toolchain
Python_Node_Libs (10GB) – Python 3.12, Node 22, wheels (numpy/pandas/fastapi/etc.)
OS_Images (5GB) – RPi Zero 2W Lite, Arduino IDE AppImage
Docs_Zeal (5GB) – Zeal docsets + hardware PDFs
Kiwix_Knowledge (50GB) – wikipedia_en_all_nopic
C_CPP_Libs_Frontend – nlohmann-json, pugixml, Boost, Tailwind, network libs

Prerequisites

Ubuntu 24.x with 110GB free space
Internet connection
USB drive mounted

Usage

Save script as offline-downloader.sh
chmod +x offline-downloader.sh
./offline-downloader.sh
Enter USB path when prompted (e.g. /media/usb)

Script will:

Ask for save directory
Download each category
Compress to .tar.gz
Move to USB
Clean temp files

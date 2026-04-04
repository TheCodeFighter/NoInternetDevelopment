#!/bin/bash
set -e

# ==========================================
# 1. DEFINE PAYLOADS
# ==========================================

DEBS="build-essential cmake clang lldb llvm gdb valgrind sqlite3 libpq-dev libssl-dev"
PYTHON_PKGS="numpy pandas requests fastapi uvicorn psycopg2-binary sqlalchemy pydantic"
DOCKER_IMAGES=("ubuntu:24.04" "alpine:latest" "python:3.12-slim" "postgres:16-alpine")

# C/C++ Sources
URL_NLOHMANN="https://github.com/nlohmann/json/releases/download/v3.11.3/json.tar.xz"
URL_PUGIXML="https://github.com/zeux/pugixml/releases/download/v1.14/pugixml-1.14.tar.gz"
URL_POPPLER="https://poppler.freedesktop.org/poppler-24.02.0.tar.xz"
URL_BOOST="https://boostorg.jfrog.io/artifactory/main/release/1.84.0/source/boost_1_84_0.tar.gz"
URL_CROW="https://github.com/CrowCpp/Crow/archive/refs/tags/v1.2.0.tar.gz"
URL_RADIOLIB="https://github.com/jgromes/RadioLib/archive/refs/tags/v6.4.0.tar.gz"

# Hardware & OS Images
URL_RPI_ZERO_2W="https://downloads.raspberrypi.com/raspios_lite_arm64/images/raspios_lite_arm64-2023-12-11/2023-12-11-raspios-bookworm-arm64-lite.img.xz"
URL_ARDUINO_IDE="https://downloads.arduino.cc/arduino-ide/arduino-ide_2.3.6_Linux_64bit.AppImage"

# VSCode Extensions
URL_VSIX_CPP="https://ms-vscode.gallery.vsassets.io/_apis/public/gallery/publisher/ms-vscode/extension/cpptools/latest/assetbyname/Microsoft.VisualStudio.Services.VSIXPackage"
URL_VSIX_ARDUINO="https://vscode-arduino.gallery.vsassets.io/_apis/public/gallery/publisher/vscode-arduino/extension/vscode-arduino-community/latest/assetbyname/Microsoft.VisualStudio.Services.VSIXPackage"

# Knowledge Base (Kiwix ZIM files)
# Note: StackOverflow is massive (~45GB). Wikipedia dev is ~10GB.
URL_STACKOVERFLOW="https://download.kiwix.org/zim/stackoverflow/stackoverflow.com_en_all_2023-09.zim"

# ==========================================
# 2. USER PROMPT & MANIFEST
# ==========================================

echo "=================================================="
echo "      SOVEREIGN VAULT: DOWNLOAD MANIFEST          "
echo "=================================================="
echo "1. Toolchains & Compilers (GCC, Clang, CMake) via apt"
echo "2. Docker Images (Ubuntu, Alpine, Python, Postgres)"
echo "3. Python Libs (Numpy, Pandas, FastAPI, DB APIs)"
echo "4. Node.js & React/Vite Frontend toolchains"
echo "5. C/C++ Libs (Boost, Nlohmann, Pugixml, Poppler, Crow, RadioLib)"
echo "6. VSCode Extensions (C++, Arduino)"
echo "7. Hardware OS (RPi Zero 2W Lite, Arduino IDE)"
echo "8. Kiwix Offline Knowledge (StackOverflow ~45GB)"
echo "=================================================="

read -p "Enter absolute path to target USB/Disk (e.g., /media/user/USB): " USB_PATH

if [ ! -d "$USB_PATH" ]; then
    echo "Error: Directory $USB_PATH does not exist."
    exit 1
fi

read -p "Verify path: $USB_PATH. Proceed with sequential download & transfer? (y/n): " CONFIRM
if [[ "$CONFIRM" != "y" ]]; then
    echo "Aborting."
    exit 0
fi

# Create target directories
mkdir -p "$USB_PATH"/{debs,docker,python,frontend,cpp_libs,vscode,hardware,docs_knowledge}
STAGING_DIR="./vault_staging"
mkdir -p "$STAGING_DIR"

echo "Using staging directory $STAGING_DIR to compress before moving..."

# ==========================================
# 3. EXECUTION PROCESS (Download -> Compress -> Move)
# ==========================================

# --- 1. Deb Packages ---
echo "[1/8] Downloading Apt Packages..."
mkdir -p "$STAGING_DIR/debs"
cd "$STAGING_DIR/debs"
sudo apt-get update
# Download debs and all dependencies
apt-get download $(apt-cache depends --recurse --no-recommends --no-suggests $DEBS | grep "^\s" | tr -d ' ') $DEBS
cd ../..
tar -czvf "$STAGING_DIR/apt_packages.tar.gz" -C "$STAGING_DIR" debs
mv "$STAGING_DIR/apt_packages.tar.gz" "$USB_PATH/debs/"
rm -rf "$STAGING_DIR/debs"

# --- 2. Docker Images ---
echo "[2/8] Downloading and Saving Docker Images..."
for img in "${DOCKER_IMAGES[@]}"; do
    docker pull "$img"
    SAFE_NAME=$(echo "$img" | tr ':' '_')
    docker save "$img" | gzip > "$STAGING_DIR/${SAFE_NAME}.tar.gz"
    mv "$STAGING_DIR/${SAFE_NAME}.tar.gz" "$USB_PATH/docker/"
done

# --- 3. Python Packages ---
echo "[3/8] Downloading Python Wheels..."
mkdir -p "$STAGING_DIR/python_wheels"
pip download -d "$STAGING_DIR/python_wheels" $PYTHON_PKGS
tar -czvf "$STAGING_DIR/python_wheels.tar.gz" -C "$STAGING_DIR" python_wheels
mv "$STAGING_DIR/python_wheels.tar.gz" "$USB_PATH/python/"
rm -rf "$STAGING_DIR/python_wheels"

# --- 4. Frontend & Node ---
echo "[4/8] Downloading Node.js and Frontend Libs..."
mkdir -p "$STAGING_DIR/frontend"
cd "$STAGING_DIR/frontend"
wget -c "https://nodejs.org/dist/v20.11.1/node-v20.11.1-linux-x64.tar.xz"
npm pack react react-dom vite tailwindcss
cd ../..
tar -czvf "$STAGING_DIR/frontend_tools.tar.gz" -C "$STAGING_DIR" frontend
mv "$STAGING_DIR/frontend_tools.tar.gz" "$USB_PATH/frontend/"
rm -rf "$STAGING_DIR/frontend"

# --- 5. C/C++ Libraries ---
echo "[5/8] Downloading C/C++ Libraries..."
cd "$STAGING_DIR"
wget -c "$URL_NLOHMANN" -O "json.tar.xz"
wget -c "$URL_PUGIXML" -O "pugixml.tar.gz"
wget -c "$URL_POPPLER" -O "poppler.tar.xz"
wget -c "$URL_BOOST" -O "boost.tar.gz"
wget -c "$URL_CROW" -O "crow.tar.gz"
wget -c "$URL_RADIOLIB" -O "radiolib.tar.gz"
mv *.tar.* "$USB_PATH/cpp_libs/"
cd ..

# --- 6. VSCode Extensions ---
echo "[6/8] Downloading VSCode Extensions..."
cd "$STAGING_DIR"
wget -c "$URL_VSIX_CPP" -O "cpptools.vsix"
wget -c "$URL_VSIX_ARDUINO" -O "vscode-arduino.vsix"
mv *.vsix "$USB_PATH/vscode/"
cd ..

# --- 7. Hardware OS ---
echo "[7/8] Downloading Hardware OS Images..."
cd "$STAGING_DIR"
wget -c "$URL_RPI_ZERO_2W" -O "raspios_lite_zero2w.img.xz"
wget -c "$URL_ARDUINO_IDE" -O "arduino-ide.AppImage"
chmod +x "arduino-ide.AppImage"
mv raspios* arduino* "$USB_PATH/hardware/"
cd ..

# --- 8. Knowledge Base (Kiwix) ---
echo "[8/8] Downloading StackOverflow Offline Archive (This will take a while)..."
cd "$STAGING_DIR"
# Using -c to resume if interrupted, as this is a ~45GB file
wget -c "$URL_STACKOVERFLOW" -O "stackoverflow.zim"
wget -c "https://download.kiwix.org/release/kiwix-desktop/kiwix-desktop_x86_64.appimage" -O "kiwix-reader.AppImage"
chmod +x "kiwix-reader.AppImage"
mv stackoverflow.zim kiwix* "$USB_PATH/docs_knowledge/"
cd ..

# Cleanup
rm -rf "$STAGING_DIR"

echo "=================================================="
echo "  VAULT CONSTRUCTION COMPLETE. DRIVES EJECTABLE.  "
echo "=================================================="
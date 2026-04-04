#!/bin/bash
set -euo pipefail
echo "Resources to download (total ~110GB fit):"
echo "1. Docker_Debs+Toolchains (20GB): docker debs, gcc/clang/cmake/arm-toolchain"
echo "2. Python_Node+Libs (10GB): python/node binaries + wheels (numpy pandas requests fastapi flask sqlalchemy psycopg2 yfinance)"
echo "3. OS_Images (5GB): RPi Zero 2W Lite + Arduino IDE"
echo "4. Docs (5GB): Zeal docsets + hardware PDFs"
echo "5. Kiwix_Knowledge (50GB): wikipedia_en_nopic"
echo "6. C_CPP_Libs: nlohmann-json, pugixml, poppler, boost, asio, xml/json/network"
echo "All compressed .tar.gz, Docker/host runnable."
read -p "Enter save dir (USB e.g. /media/usb): " SAVE_DIR
[ -d "$SAVE_DIR" ] || { echo "Invalid dir"; exit 1; }
mkdir -p "$SAVE_DIR"
TEMP=/tmp/offline_res_$$
mkdir -p "$TEMP"
cd "$TEMP"

download_category() {
  local name=$1 cmd=$2
  echo "=== Downloading $name ==="
  mkdir -p "$name"
  cd "$name"
  eval "$cmd"
  cd ..
  tar -czf "${name}.tar.gz" "$name"
  mv "${name}.tar.gz" "$SAVE_DIR/"
  rm -rf "$name"
  echo "$name done"
}

download_category "Docker_Debs_Toolchains" '
sudo apt-get update
mkdir debs
cd debs
apt-get download docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin build-essential gcc g++ cmake clang libstdc++-dev
cd ..
wget -qO- https://developer.arm.com/downloads --quiet | grep -o "https://.*arm-gnu-toolchain.*x86_64.*tar.xz" | head -1 | xargs wget -O arm-toolchain.tar.xz
'

download_category "Python_Node_Libs" '
wget https://www.python.org/ftp/python/3.12.8/Python-3.12.8.tgz
wget https://nodejs.org/dist/v22.11.0/node-v22.11.0-linux-x64.tar.xz
cat > reqs.txt <<EOF
numpy pandas requests fastapi flask sqlalchemy psycopg2-binary yfinance
EOF
python3 -m pip download -d wheels -r reqs.txt
'

download_category "OS_Images" '
wget -O rpi.img.xz https://downloads.raspberrypi.com/raspios_lite_arm64/images/raspios_lite_arm64-2025-03-11/raspios-lite-arm64-2025-03-11.img.xz
wget -O arduino.AppImage https://downloads.arduino.cc/arduino-ide/arduino-ide_2.3.4_Linux_64bit.AppImage
'

download_category "Docs_Zeal" '
wget -r -np -nd -A "*.docset.tgz" https://zealusercontributions.now.sh/api/docsets/ --reject "index.html*"
'

download_category "Kiwix_Knowledge" '
wget -O wikipedia.zim https://download.kiwix.org/zim/wikipedia/wikipedia_en_all_nopic_2025-03.zim
'

download_category "C_CPP_Libs_Frontend" '
wget https://github.com/nlohmann/json/releases/download/v3.11.3/json.tar.xz
wget https://github.com/pugixml/pugixml/releases/download/v1.15/pugixml-1.15.tar.gz
wget https://github.com/boostorg/boost/releases/download/boost-1.86.0/boost-1.86.0.tar.gz
mkdir frontend; cd frontend; wget https://cdn.tailwindcss.com -O tailwind.js
'

echo "All done. Files in $SAVE_DIR as compressed archives."
rm -rf "$TEMP"
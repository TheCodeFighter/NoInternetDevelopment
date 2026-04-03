#!/bin/bash

# Configuration
COMMAND=$1
COMPOSE_FILE="docker-compose.yml"

case "$COMMAND" in
    install)
        echo "=== Initializing Installation and AI Environment ==="
        
        # Update system and install Docker & Compose
        sudo apt-get update
        sudo apt-get install -y docker.io docker-compose-v2 curl gnupg

        # Install NVIDIA drivers if not present
        sudo ubuntu-drivers autoinstall
        
        # Install NVIDIA Container Toolkit
        # Why? It bridges the isolated Docker container to your RTX 4070 hardware.
        curl -fsSL https://nvidia.github.io/libnvidia-container/gpgkey | sudo gpg --yes --dearmor -o /usr/share/keyrings/nvidia-container-toolkit-keyring.gpg
        curl -s -L https://nvidia.github.io/libnvidia-container/stable/deb/nvidia-container-toolkit.list | \
            sed 's#deb https://#deb [signed-by=/usr/share/keyrings/nvidia-container-toolkit-keyring.gpg] https://#g' | \
            sudo tee /etc/apt/sources.list.d/nvidia-container-toolkit.list
        sudo apt-get update
        sudo apt-get install -y nvidia-container-toolkit
        
        # Restart Docker to detect NVIDIA runtime
        sudo systemctl restart docker

        # Create the docker-compose.yml file
        # Volume mapping (./ollama_data) ensures your Mistral/Codestral models persist after container stops.
        cat <<EOF > $COMPOSE_FILE
services:
  ollama:
    image: ollama/ollama:latest
    container_name: ollama
    volumes:
      - ./ollama_data:/root/.ollama
    ports:
      - "11434:11434"
    deploy:
      resources:
        reservations:
          devices:
            - driver: nvidia
              count: 1
              capabilities: [gpu]
    restart: unless-stopped
EOF
        echo "=== Installation successful. $COMPOSE_FILE created. ==="
        echo "Next step: Run './ai_manager.sh up' to start the server."
        ;;
    
    up)
        echo "=== Starting Ollama AI Server ==="
        # '-d' (detached) runs it in the background so you can close the terminal.
        sudo docker compose -f $COMPOSE_FILE up -d
        echo "Server is running. Models are ready for VS Code."
        ;;
    
    down)
        echo "=== Stopping Ollama AI Server ==="
        # 'down' completely stops the container and releases VRAM/RAM back to Ubuntu.
        sudo docker compose -f $COMPOSE_FILE down
        echo "Server stopped. Hardware resources released."
        ;;
        
    *)
        echo "Usage: $0 {install|up|down}"
        echo "  install : Install Docker, NVIDIA toolkit, and create compose file"
        echo "  up      : Start AI server in background"
        echo "  down    : Stop AI server and free up VRAM"
        exit 1
        ;;
esac
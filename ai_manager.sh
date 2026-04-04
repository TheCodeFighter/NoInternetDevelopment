#!/bin/bash

# Configuration
COMMAND=$1
COMPOSE_FILE="docker-compose.yml"

case "$COMMAND" in
    up)
        echo "=== Starting AI Server (Ollama with NVIDIA GPU) ==="
        docker compose -f $COMPOSE_FILE up -d
        echo "Server is UP. Running on port 11434."
        ;;

    setup-models)
        echo "=== Downloading Optimized Models for 8GB VRAM ==="
        
        echo "--- Pulling Mistral Nemo 12B ---"
        docker exec -it ollama ollama pull mistral-nemo
        
        echo "--- Pulling Codestral 22B (Q4) ---"
        docker exec -it ollama ollama pull codestral:22b-v0.1-q4_K_M
        
        # (Autocomplete)
        echo "--- Pulling StarCoder2 3B ---"
        docker exec -it ollama ollama pull starcoder2:3b

        echo "--- Pulling Qwen coder ---"
        docker exec -it ollama ollama pull qwen2.5-coder:1.5b

        # for (@codebase)
        echo "--- Pulling Embedding Model ---"
        docker exec -it ollama ollama pull nomic-embed-text
        
        echo "=== All models installed and optimized! ==="
        ;;
    
    status)
        echo "=== Container Status ==="
        docker compose ps
        echo ""
        echo "--- Loaded Models in Ollama ---"
        docker exec -it ollama ollama list
        ;;

    down)
        echo "=== Stopping Server & Freeing VRAM ==="
        docker compose -f $COMPOSE_FILE down
        ;;
        
    *)
        echo "Usage: $0 {up|setup-models|status|down}"
        exit 1
        ;;
esac
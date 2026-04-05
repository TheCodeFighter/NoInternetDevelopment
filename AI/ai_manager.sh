#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
COMPOSE_FILE="${SCRIPT_DIR}/docker-compose.yml"
CONTAINER_NAME="ollama"
COMMAND="${1:-}"

usage() {
    echo "Usage: $0 {up|setup-models|status|down}"
}

if [[ -z "$COMMAND" ]]; then
    usage
    exit 1
fi

case "$COMMAND" in
    up)
        echo "=== Starting AI server (Ollama with NVIDIA GPU) ==="
        docker compose -f "$COMPOSE_FILE" up -d
        echo "Server is up on port 11434."
        ;;

    setup-models)
        echo "=== Downloading optimized models for 8GB VRAM ==="

        echo "--- Pulling Mistral Nemo ---"
        docker exec "$CONTAINER_NAME" ollama pull mistral-nemo

        echo "--- Pulling Codestral 22B (Q4) ---"
        docker exec "$CONTAINER_NAME" ollama pull codestral:22b-v0.1-q4_K_M

        echo "--- Pulling Qwen coder 1.5B ---"
        docker exec "$CONTAINER_NAME" ollama pull qwen2.5-coder:1.5b

        echo "--- Pulling embedding model ---"
        docker exec "$CONTAINER_NAME" ollama pull nomic-embed-text

        echo "=== Model setup complete ==="
        ;;

    status)
        echo "=== Container status ==="
        docker compose -f "$COMPOSE_FILE" ps
        echo
        echo "--- Loaded models in Ollama ---"
        docker exec "$CONTAINER_NAME" ollama list
        ;;

    down)
        echo "=== Stopping server and freeing VRAM ==="
        docker compose -f "$COMPOSE_FILE" down
        ;;

    *)
        usage
        exit 1
        ;;
esac
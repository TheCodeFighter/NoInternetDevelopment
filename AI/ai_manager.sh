#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
COMPOSE_FILE="${SCRIPT_DIR}/docker-compose.yml"
CONTAINER_NAME="ollama"
OLLAMA_DATA_DIR="${SCRIPT_DIR}/../ollama_data"
RUNTIME_IMAGE="ollama/ollama:latest"
RUN_ID="$(date +%Y%m%d_%H%M%S)"
RUNTIME_ARCHIVE_DEFAULT="${OLLAMA_DATA_DIR}/ollama-runtime-image.tar"
FULL_STACK_ARCHIVE_DEFAULT="${SCRIPT_DIR}/../localai-ai-offline-${RUN_ID}.tar.zst"
COMMAND="${1:-}"
ARG1="${2:-}"
ARG2="${3:-}"
ARG3="${4:-}"
STARTED_BY_THIS_COMMAND=0

required_free_space_mb() {
    # Conservative estimate for runtime image + model pulls + Docker export temp overhead.
    echo 30000
}

docker_root_dir() {
    docker info --format '{{.DockerRootDir}}' 2>/dev/null || echo /var/lib/docker
}

disk_free_mb_for_path() {
    local path="$1"
    df -Pm "$path" 2>/dev/null | awk 'NR==2 {print $4}'
}

preflight_disk_space() {
    local docker_root=""
    local docker_root_free=""
    local target_free=""
    local temp_free=""
    local required_mb=""

    docker_root="$(docker_root_dir)"
    required_mb="$(required_free_space_mb)"
    docker_root_free="$(disk_free_mb_for_path "$docker_root")"
    target_free="$(disk_free_mb_for_path "$(dirname "$WORKFLOW_ARCHIVE_PATH")")"
    temp_free="$(disk_free_mb_for_path "$WORKFLOW_TEMP_DIR")"

    echo "=== Disk space preflight ==="
    echo "Docker root dir: ${docker_root}"
    echo "Docker root free: ${docker_root_free:-unknown} MB"
    echo "Target free     : ${target_free:-unknown} MB"
    echo "Temp free       : ${temp_free:-unknown} MB"
    echo "Estimated need  : ${required_mb} MB"

    if [[ -n "$docker_root_free" && "$docker_root_free" -lt "$required_mb" ]]; then
        echo ""
        echo "Not enough free space on Docker root to run the full offline archive."
        echo "Free space on ${docker_root} must be increased or Docker data-root must be moved to a larger disk."
        echo ""
        return 1
    fi

    if [[ -n "$temp_free" && "$temp_free" -lt 5000 ]]; then
        echo ""
        echo "Temporary directory is too small. Choose a larger temp directory or an external drive path."
        echo ""
        return 1
    fi

    return 0
}

pull_models() {
    echo "--- Pulling Mistral Nemo ---"
    docker exec "$CONTAINER_NAME" ollama pull mistral-nemo:latest

    echo "--- Pulling Codestral 22B (Q4) ---"
    docker exec "$CONTAINER_NAME" ollama pull codestral:22b-v0.1-q4_K_M

    echo "--- Pulling Qwen coder 1.5B ---"
    docker exec "$CONTAINER_NAME" ollama pull qwen2.5-coder:1.5b

    echo "--- Pulling embedding model ---"
    docker exec "$CONTAINER_NAME" ollama pull nomic-embed-text:latest
}

model_manifest_present() {
    local model="$1"
    local name="${model%%:*}"
    local tag="${model##*:}"
    local manifest_path="${OLLAMA_DATA_DIR}/models/manifests/registry.ollama.ai/library/${name}/${tag}"

    [[ -f "$manifest_path" ]]
}

is_ollama_running() {
    [[ "$(docker inspect -f '{{.State.Running}}' "$CONTAINER_NAME" 2>/dev/null || true)" == "true" ]]
}

ensure_ollama_running() {
    if is_ollama_running; then
        echo "Ollama container is already running."
        STARTED_BY_THIS_COMMAND=0
        return
    fi

    echo "Starting Ollama container for model downloads..."
    docker compose -f "$COMPOSE_FILE" up -d
    STARTED_BY_THIS_COMMAND=1
}

export_runtime_image() {
    local archive_path="${1:-$RUNTIME_ARCHIVE_DEFAULT}"

    mkdir -p "$(dirname "$archive_path")"

    if ! docker image inspect "$RUNTIME_IMAGE" >/dev/null 2>&1; then
        echo "Runtime image is not present locally: ${RUNTIME_IMAGE}"
        echo "Run '$0 download-all' first (with internet), then export again."
        exit 1
    fi

    echo "=== Exporting runtime image to disk ==="
    echo "--- Writing: ${archive_path} ---"
    docker image save -o "$archive_path" "$RUNTIME_IMAGE"
    echo "Runtime image export complete."
}

is_truthy() {
    local value="${1:-}"

    case "${value,,}" in
        y|yes|true|1)
            return 0
            ;;
        *)
            return 1
            ;;
    esac
}

tar_supports_zstd() {
    tar --help 2>&1 | grep -q -- '--zstd'
}

normalize_archive_path() {
    local requested_path="$1"
    local default_name="$2"

    if [[ -z "$requested_path" ]]; then
        echo ""
        return 0
    fi

    if [[ -d "$requested_path" ]]; then
        echo "${requested_path%/}/${default_name}"
        return 0
    fi

    if [[ "$requested_path" == */ ]]; then
        echo "${requested_path%/}/${default_name}"
        return 0
    fi

    echo "$requested_path"
}

create_archive_from_dir() {
    local source_dir="$1"
    local archive_path="$2"
    local parent_dir=""
    local base_name=""

    parent_dir="$(dirname "$source_dir")"
    base_name="$(basename "$source_dir")"

    mkdir -p "$(dirname "$archive_path")"

    case "$archive_path" in
        *.tar.zst)
            if tar_supports_zstd; then
                tar --zstd -cf "$archive_path" -C "$parent_dir" "$base_name"
            else
                echo "tar does not support --zstd on this host."
                echo "Use a .tar.gz or .tar output path instead."
                exit 1
            fi
            ;;
        *.tar.gz|*.tgz)
            tar -czf "$archive_path" -C "$parent_dir" "$base_name"
            ;;
        *.tar)
            tar -cf "$archive_path" -C "$parent_dir" "$base_name"
            ;;
        *)
            if tar_supports_zstd; then
                tar --zstd -cf "$archive_path" -C "$parent_dir" "$base_name"
            else
                tar -czf "$archive_path" -C "$parent_dir" "$base_name"
            fi
            ;;
    esac
}

prompt_archive_workflow_options() {
    local default_archive="${1:-$RUNTIME_ARCHIVE_DEFAULT}"
    local default_temp_dir="${2:-/tmp/localai_runtime_export_${RUN_ID}}"
    local default_archive_name="$(basename "$default_archive")"
    local input_cleanup=""

    WORKFLOW_ARCHIVE_PATH="$3"
    WORKFLOW_TEMP_DIR="$4"
    WORKFLOW_CLEANUP_CHOICE="$5"

    if [[ -z "$WORKFLOW_ARCHIVE_PATH" ]]; then
        read -r -p "Target archive path [${default_archive}]: " WORKFLOW_ARCHIVE_PATH
        WORKFLOW_ARCHIVE_PATH="${WORKFLOW_ARCHIVE_PATH:-$default_archive}"
    fi

    WORKFLOW_ARCHIVE_PATH="$(normalize_archive_path "$WORKFLOW_ARCHIVE_PATH" "$default_archive_name")"

    if [[ -z "$WORKFLOW_TEMP_DIR" ]]; then
        read -r -p "Temporary working directory [${default_temp_dir}]: " WORKFLOW_TEMP_DIR
        WORKFLOW_TEMP_DIR="${WORKFLOW_TEMP_DIR:-$default_temp_dir}"
    fi

    if [[ -z "$WORKFLOW_CLEANUP_CHOICE" ]]; then
        read -r -p "Delete temporary working directory at end? [Y/n]: " input_cleanup
        WORKFLOW_CLEANUP_CHOICE="${input_cleanup:-Y}"
    fi
}

prepare_archive_destination() {
    local archive_path="$1"
    local choice=""

    mkdir -p "$(dirname "$archive_path")"

    if [[ ! -f "$archive_path" ]]; then
        return 0
    fi

    while true; do
        read -r -p "Target archive already exists at ${archive_path}. Choose [s]kip or [o]verwrite [default s]: " choice
        choice="${choice:-s}"
        case "${choice,,}" in
            s|skip)
                echo "Skipping archive creation: ${archive_path}"
                return 1
                ;;
            o|overwrite)
                rm -f "$archive_path"
                echo "Overwriting archive: ${archive_path}"
                return 0
                ;;
            *)
                echo "Please type s (skip) or o (overwrite)."
                ;;
        esac
    done
}

export_runtime_image_via_temp() {
    local archive_path="$1"
    local temp_dir="$2"
    local cleanup_choice="$3"
    local temp_archive_path=""
    local temp_dir_preexisting=0
    local temp_dir_normalized="${temp_dir%/}"
    local archive_inside_temp=0

    if ! docker image inspect "$RUNTIME_IMAGE" >/dev/null 2>&1; then
        echo "Runtime image is not present locally: ${RUNTIME_IMAGE}"
        echo "Run '$0 download-all' first (with internet), then archive again."
        exit 1
    fi

    if [[ -d "$temp_dir" ]]; then
        temp_dir_preexisting=1
    fi

    mkdir -p "$(dirname "$archive_path")" "$temp_dir"
    temp_archive_path="${temp_dir%/}/ollama-runtime-image-${RUN_ID}.tar"

    if [[ "$archive_path" == "$temp_dir_normalized"/* ]]; then
        archive_inside_temp=1
    fi

    echo "=== Exporting runtime image via temporary working directory ==="
    echo "--- Temp archive: ${temp_archive_path} ---"
    docker image save -o "$temp_archive_path" "$RUNTIME_IMAGE"

    mv -f "$temp_archive_path" "$archive_path"
    echo "--- Final archive: ${archive_path} ---"

    if is_truthy "$cleanup_choice"; then
        if [[ "$archive_inside_temp" -eq 1 ]]; then
            echo "Archive path is inside temp directory; keeping temp directory to avoid deleting archive."
            echo "Temporary directory kept: ${temp_dir}"
        elif [[ "$temp_dir_preexisting" -eq 0 ]]; then
            rm -rf "$temp_dir"
            echo "Temporary directory removed: ${temp_dir}"
        else
            echo "Temporary directory existed before run, keeping it: ${temp_dir}"
        fi
    else
        echo "Temporary directory kept: ${temp_dir}"
    fi

    echo "Runtime image archive complete."
}

archive_runtime_only() {
    prompt_archive_workflow_options "$RUNTIME_ARCHIVE_DEFAULT" "/tmp/localai_runtime_export_${RUN_ID}" "${1:-}" "${2:-}" "${3:-}"
    if ! prepare_archive_destination "$WORKFLOW_ARCHIVE_PATH"; then
        return 0
    fi
    export_runtime_image_via_temp "$WORKFLOW_ARCHIVE_PATH" "$WORKFLOW_TEMP_DIR" "$WORKFLOW_CLEANUP_CHOICE"
}

archive_full_stack_via_temp() {
    local archive_path="$1"
    local temp_dir="$2"
    local cleanup_choice="$3"
    local temp_dir_preexisting=0
    local temp_dir_normalized="${temp_dir%/}"
    local archive_inside_temp=0
    local bundle_root=""
    local runtime_tar=""

    if ! docker image inspect "$RUNTIME_IMAGE" >/dev/null 2>&1; then
        echo "Runtime image is not present locally: ${RUNTIME_IMAGE}"
        echo "Run '$0 download-all' first (with internet), then archive again."
        exit 1
    fi

    if [[ ! -d "$OLLAMA_DATA_DIR/models" ]]; then
        echo "Model directory not found: ${OLLAMA_DATA_DIR}/models"
        echo "Run '$0 download-all' first so the model data exists."
        exit 1
    fi

    if [[ -d "$temp_dir" ]]; then
        temp_dir_preexisting=1
    fi

    mkdir -p "$temp_dir"
    bundle_root="${temp_dir%/}/localai-ai-offline-${RUN_ID}"
    runtime_tar="${bundle_root}/ollama-runtime-image.tar"

    if [[ "$archive_path" == "$temp_dir_normalized"/* ]]; then
        archive_inside_temp=1
    fi

    rm -rf "$bundle_root"
    mkdir -p "$bundle_root"

    echo "=== Building full offline AI archive via temporary working directory ==="
    echo "--- Copying AI config/scripts ---"
    cp -a "$SCRIPT_DIR" "$bundle_root/AI"

    echo "--- Copying model data (ollama_data) ---"
    cp -a "$OLLAMA_DATA_DIR" "$bundle_root/ollama_data"

    echo "--- Exporting runtime image to bundle ---"
    docker image save -o "$runtime_tar" "$RUNTIME_IMAGE"

    cat > "${bundle_root}/RESTORE.txt" <<EOF
LocalAI Offline Restore

1. Keep AI/ and ollama_data/ as sibling folders after extraction.
2. Load runtime image:
   ./AI/ai_manager.sh import-runtime ./ollama-runtime-image.tar
3. Start service:
   ./AI/ai_manager.sh up
4. Verify:
   ./AI/ai_manager.sh status
   ./AI/ai_manager.sh offline-check ./ollama-runtime-image.tar
EOF

    echo "--- Creating final archive: ${archive_path} ---"
    create_archive_from_dir "$bundle_root" "$archive_path"

    if is_truthy "$cleanup_choice"; then
        rm -rf "$bundle_root"
        if [[ "$archive_inside_temp" -eq 1 ]]; then
            echo "Archive path is inside temp directory; keeping temp directory to avoid deleting archive."
            echo "Temporary directory kept: ${temp_dir}"
        elif [[ "$temp_dir_preexisting" -eq 0 ]]; then
            rm -rf "$temp_dir"
            echo "Temporary directory removed: ${temp_dir}"
        else
            echo "Temporary bundle directory removed; base temp dir kept: ${temp_dir}"
        fi
    else
        echo "Temporary directory kept: ${temp_dir}"
    fi

    echo "Full offline AI archive complete: ${archive_path}"
}

archive_only() {
    prompt_archive_workflow_options "$FULL_STACK_ARCHIVE_DEFAULT" "/tmp/localai_full_archive_${RUN_ID}" "${1:-}" "${2:-}" "${3:-}"
    if ! prepare_archive_destination "$WORKFLOW_ARCHIVE_PATH"; then
        return 0
    fi
    archive_full_stack_via_temp "$WORKFLOW_ARCHIVE_PATH" "$WORKFLOW_TEMP_DIR" "$WORKFLOW_CLEANUP_CHOICE"
}

download_all_stack() {
    echo "=== Downloading full local AI stack to disk ==="
    echo "--- Pulling Ollama runtime image ---"
    docker compose -f "$COMPOSE_FILE" pull

    ensure_ollama_running
    pull_models

    if [[ "$STARTED_BY_THIS_COMMAND" -eq 1 ]]; then
        echo "--- Stopping temporary Ollama container (models remain on disk) ---"
        docker compose -f "$COMPOSE_FILE" stop
    fi

    echo "=== Local AI stack download complete ==="
    echo "Runtime image is cached by Docker; models are stored in ollama_data/."
}

bundle_all() {
    echo "=== Downloading and bundling the full local AI stack ==="
    echo "This runs download-all, then archives the full offline AI stack."

    prompt_archive_workflow_options "$FULL_STACK_ARCHIVE_DEFAULT" "/tmp/localai_full_archive_${RUN_ID}" "${1:-}" "${2:-}" "${3:-}"
    if ! prepare_archive_destination "$WORKFLOW_ARCHIVE_PATH"; then
        echo "Bundle skipped by user choice before download step."
        return 0
    fi

    if ! preflight_disk_space; then
        echo "Aborting before download/export because the host does not have enough free space."
        echo "Use a machine with more free disk space, or move Docker's data-root to a larger disk."
        return 1
    fi

    download_all_stack
    archive_full_stack_via_temp "$WORKFLOW_ARCHIVE_PATH" "$WORKFLOW_TEMP_DIR" "$WORKFLOW_CLEANUP_CHOICE"
    echo "=== Bundle complete ==="
    echo "Extract the archive, then restore with: $0 import-runtime <extracted>/ollama-runtime-image.tar && $0 up"
}

import_runtime_image() {
    local archive_path="${1:-$RUNTIME_ARCHIVE_DEFAULT}"

    if [[ ! -f "$archive_path" ]]; then
        echo "Runtime image archive not found: ${archive_path}"
        echo "Provide a valid tar path or run '$0 export-runtime' on a prepared machine."
        exit 1
    fi

    echo "=== Importing runtime image from disk ==="
    echo "--- Loading: ${archive_path} ---"
    docker image load -i "$archive_path"
    echo "Runtime image import complete."
}

offline_check() {
    local archive_path="${1:-$RUNTIME_ARCHIVE_DEFAULT}"
    local missing=0
    local required_models=(
        "mistral-nemo:latest"
        "codestral:22b-v0.1-q4_K_M"
        "qwen2.5-coder:1.5b"
        "nomic-embed-text:latest"
    )

    echo "=== Offline readiness check (disk-only mode) ==="

    if command -v docker >/dev/null 2>&1; then
        echo "[OK] Docker CLI is installed."
    else
        echo "[MISSING] Docker CLI is not installed."
        missing=1
    fi

    if command -v docker >/dev/null 2>&1; then
        if docker info >/dev/null 2>&1; then
            echo "[OK] Docker daemon is reachable."
        else
            echo "[MISSING] Docker daemon is not running or not reachable."
            missing=1
        fi

        if docker compose version >/dev/null 2>&1; then
            echo "[OK] Docker Compose plugin is available."
        else
            echo "[MISSING] Docker Compose plugin is missing."
            missing=1
        fi

        if docker image inspect "$RUNTIME_IMAGE" >/dev/null 2>&1; then
            echo "[OK] Runtime image is loaded locally: ${RUNTIME_IMAGE}"
        else
            echo "[MISSING] Runtime image is not loaded: ${RUNTIME_IMAGE}"
            if [[ -f "$archive_path" ]]; then
                echo "         Found on disk: ${archive_path}"
                echo "         Run: $0 import-runtime \"${archive_path}\""
            else
                echo "         Run online once: $0 download-all"
                echo "         Or import a copied image tar: $0 import-runtime <path-to-tar>"
            fi
            missing=1
        fi
    fi

    if command -v nvidia-smi >/dev/null 2>&1; then
        echo "[OK] NVIDIA driver tools are installed (nvidia-smi)."
    else
        echo "[MISSING] NVIDIA driver tools are not available (nvidia-smi)."
        echo "         Install NVIDIA drivers and NVIDIA Container Toolkit for GPU mode."
        missing=1
    fi

    if [[ -d "$OLLAMA_DATA_DIR/models/blobs" ]] && find "$OLLAMA_DATA_DIR/models/blobs" -type f -print -quit | grep -q .; then
        echo "[OK] Model blobs exist in ${OLLAMA_DATA_DIR}/models/blobs."
    else
        echo "[MISSING] No model blobs found in ${OLLAMA_DATA_DIR}/models/blobs."
        missing=1
    fi

    for model in "${required_models[@]}"; do
        if model_manifest_present "$model"; then
            echo "[OK] Model manifest present: ${model}"
        else
            echo "[MISSING] Model manifest missing: ${model}"
            missing=1
        fi
    done

    echo
    if [[ "$missing" -eq 0 ]]; then
        echo "Result: READY for pure disk-only operation."
        echo "Start the service with: $0 up"
    else
        echo "Result: NOT READY for pure disk-only operation."
        echo "Fix the missing items above, then run: $0 offline-check"
    fi
}

usage() {
    cat <<EOF
Usage: $0 <command> [args]

Commands:
  up                             Start Ollama container.
  setup-models                   Pull selected models into ollama_data.
  download-all                   Pull runtime image and selected models.
        bundle-all [archive-or-dir] [temp] [cleanup]      Download models + runtime then archive full offline AI stack.
        archive-only [archive-or-dir] [temp] [cleanup]    Archive full offline AI stack only (no downloads).
        archive-runtime-only [archive-or-dir] [temp] [cleanup]
                                                                                         Archive runtime image only.
    export-runtime [archive-path]              Export runtime image to a tar file.
    import-runtime [archive-path]              Import runtime image from a tar file.
  offline-check [archive-path]   Show what is missing for disk-only operation.
  status                         Show container and model status.
  down                           Stop the stack.
EOF
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
        ensure_ollama_running
        pull_models

        echo "=== Model setup complete ==="
        ;;

    download-all)
        download_all_stack
        echo "Tip: run '$0 bundle-all' or '$0 archive-only' to create a full offline AI archive."
        ;;

    bundle-all)
        bundle_all "$ARG1" "$ARG2" "$ARG3"
        ;;

    archive-only)
        archive_only "$ARG1" "$ARG2" "$ARG3"
        ;;

    archive-runtime-only)
        archive_runtime_only "$ARG1" "$ARG2" "$ARG3"
        ;;

    export-runtime)
        export_runtime_image "$ARG1"
        ;;

    import-runtime)
        import_runtime_image "$ARG1"
        ;;

    offline-check)
        offline_check "$ARG1"
        ;;

    status)
        echo "=== Container status ==="
        docker compose -f "$COMPOSE_FILE" ps

        if is_ollama_running; then
            echo
            echo "--- Loaded models in Ollama ---"
            docker exec "$CONTAINER_NAME" ollama list
        else
            echo
            echo "Ollama container is not running. Start it with: $0 up"
        fi
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
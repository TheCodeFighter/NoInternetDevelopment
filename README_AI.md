# Usage

```Shell
chmod +x ai_manager.sh
```

```Shell
./ai_manager.sh up
```

```Shell
./ai_manager.sh setup-models
```

```Shell
./ai_manager.sh down
```

```Shell
./ai_manager.sh *
```

## Local AI Setup Optimization Guide

This guide covers the best practices for running a local AI assistant (Ollama + Continue) on a mid-range GPU (e.g., NVIDIA with 8GB VRAM).

1. Core Model Configuration
To balance intelligence and speed, use separate models for different tasks:

Chat (Brain): Codestral-22B (q4) or Mistral-Small. Great for logic and complex code generation.

Autocomplete (Speed): Qwen2.5-Coder-1.5B. Provides instant "ghost text" as you type.

Apply (Worker): Qwen2.5-Coder-7B or Mistral-Small. Fast enough to merge changes into large files without crashing VRAM.

2. Autocomplete Performance (Zero Latency)
If the gray text feels slow (1-3s delay), check these VS Code settings:

Min Show Delay: Set Editor > Inline Suggest: Min Show Delay to 0.

FIM Mode: Ensure Use Next Edit over FIM autocomplete is NOT selected in the Continue menu; you want FIM (Fill-In-the-Middle) active for standard coding.

Quick Suggestions: Set Editor > Quick Suggestions Delay to 0.

3. The "Apply" Strategy for Large Files
Applying changes to files with 700+ lines can be slow due to VRAM context limits.

Selection over File: Instead of applying to the whole file, highlight the specific function you want to change, then click Apply in the chat sidebar.

Role Assignment: In config.json, assign the "roles": ["apply"] to a lighter model (like Qwen-7B) to speed up the diffing process.

4. Troubleshooting: "AST Tracker" Errors
If logs show Document not found in AST tracker:

Index the Project: Run the command Continue: Index Project to help the AI understand your file structure.

Docker Mounts: If your code is on a Docker mount, ensure the container is running and the path is indexed correctly.

Ignore Unnecessary Files: Create a .continueignore file and add build/, node_modules/, and .git/ to reduce indexing load.

5. Monitoring & VRAM Management
Watch GPU Usage: Use watch -n 1 nvidia-smi or nvtop in the terminal to monitor VRAM.

Free up VRAM: Browsers like Brave use Hardware Acceleration. Disable it or close the browser to free up ~1GB of VRAM for the AI.

Ollama Origins: If you encounter connection issues, set the environment variable:
OLLAMA_ORIGINS="vscode-webview://*"

6. Pro Tip: Use "Edit" Mode
For quick refactoring, use Ctrl + I. It opens a small input field directly in the editor, which is much faster than the full Chat sidebar for minor changes.

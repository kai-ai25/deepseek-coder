#!/bin/bash

# --- System Setup ---
sudo apt update && sudo apt install -y \
    python3-pip \
    git-lfs \
    nvidia-cuda-toolkit-12-3

# --- Model Download ---
mkdir -p /workspace/models
if [ ! -f "/workspace/models/config.json" ]; then
    git lfs install
    huggingface-cli download $MODEL_NAME \
        --local-dir /workspace/models \
        --local-dir-use-symlinks False \
        --resume-download
fi

# --- Python Env ---
pip install -r /workspace/requirements.txt \
    --extra-index-url https://download.pytorch.org/whl/cu118

# --- Permissions ---
chmod +x /workspace/runpod/start.sh

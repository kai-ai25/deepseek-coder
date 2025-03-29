#!/bin/bash
set -euo pipefail

# ======================
# SYSTEM DEPENDENCIES
# ======================
echo "🛠️ Installing system packages..."
sudo apt-get update && sudo apt-get install -y \
    python3-pip \
    python3-dev \
    git-lfs \
    nvidia-cuda-toolkit-12-3 \
    htop \
    tmux \
    jq \
    curl \
    build-essential

# ======================
# GIT LFS SETUP
# ======================
echo "🔧 Configuring Git LFS..."
git lfs install --skip-repo
git config --global credential.helper store
git config --global lfs.concurrenttransfers 8

# ======================
# MODEL DOWNLOAD
# ======================
mkdir -p /workspace/models
cd /workspace/models

if [ ! -f "config.json" ]; then
    echo "⬇️ Downloading model..."
    git lfs clone https://huggingface.co/$MODEL_NAME .
else
    echo "🔄 Model exists, pulling updates..."
    git pull
fi

# ======================
# PYTHON ENVIRONMENT
# ======================
echo "🐍 Setting up Python..."
pip install --upgrade pip
pip install -r /workspace/requirements.txt \
    --extra-index-url https://download.pytorch.org/whl/cu118

# ======================
# VERIFICATION
# ======================
echo "✅ Verifying installations..."
python3 -c "
import torch
assert torch.cuda.is_available(), 'CUDA not available'
print(f'Torch {torch.__version__} | CUDA {torch.version.cuda}')
"

#!/bin/bash
set -euo pipefail

# System deps
sudo apt-get update && sudo apt-get install -y git-lfs python3-pip

# Git LFS setup
sudo git lfs install --system
git config --global lfs.concurrenttransfers 8

# Model download
mkdir -p /workspace/models
[ ! -f "/workspace/models/config.json" ] && \
    git lfs clone https://huggingface.co/deepseek-ai/deepseek-coder-6.7b-instruct /workspace/models

# Python env
pip install -r requirements.txt --extra-index-url https://download.pytorch.org/whl/cu118

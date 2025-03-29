#!/bin/bash
source /workspace/.env

# --- GPU Optimization ---
export PYTORCH_CUDA_ALLOC_CONF="max_split_size_mb:128"
export TOKENIZERS_PARALLELISM=true

# --- Start API ---
uvicorn src.app.api:app \
    --host 0.0.0.0 \
    --port $API_PORT \
    --workers 2 \
    --timeout-keep-alive 300 &

# --- Start UI ---
sleep 10  # Wait for API
python src/app/ui.py \
    --server-port $UI_PORT \
    --server-name 0.0.0.0 \
    --no-gradio-queue

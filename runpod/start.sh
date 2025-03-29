#!/bin/bash
set -euo pipefail  # Exit on any error

# --- Initialize Logging ---
LOG_DIR="/workspace/logs"
mkdir -p "$LOG_DIR"
exec > >(tee -a "$LOG_DIR/startup.log") 2>&1

echo "=== $(date) ==="
echo "Starting DeepSeek Coder Assistant..."

# --- Load Environment ---
if [ ! -f "/workspace/.env" ]; then
    echo "❌ Error: .env file missing!" | tee -a "$LOG_DIR/errors.log"
    exit 1
fi
source /workspace/.env

# --- GPU Configuration ---
export PYTORCH_CUDA_ALLOC_CONF="max_split_size_mb:128"
export TOKENIZERS_PARALLELISM=true
echo "GPU optimization settings applied"

# --- Verify GPU ---
if ! nvidia-smi &> /dev/null; then
    echo "⚠️ Warning: No GPU detected! Falling back to CPU mode" | tee -a "$LOG_DIR/errors.log"
    export CUDA_VISIBLE_DEVICES=""
fi

# --- Start API Server ---
echo "Starting API on port $API_PORT..."
uvicorn src.app.api:app \
    --host 0.0.0.0 \
    --port "$API_PORT" \
    --workers 2 \
    --timeout-keep-alive 300 \
    --log-level debug \
    >> "$LOG_DIR/api.log" 2>&1 &

API_PID=$!
echo "API started (PID: $API_PID)"

# --- Verify API Health ---
sleep 10  # Wait for API startup
if ! curl -s "http://localhost:$API_PORT/health" | grep -q "ok"; then
    echo "❌ API health check failed! See $LOG_DIR/api.log" | tee -a "$LOG_DIR/errors.log"
    exit 1
fi

# --- Start UI ---
echo "Starting UI on port $UI_PORT..."
python src/app/ui.py \
    --server-port "$UI_PORT" \
    --server-name 0.0.0.0 \
    --no-gradio-queue \
    >> "$LOG_DIR/ui.log" 2>&1 &

UI_PID=$!
echo "UI started (PID: $UI_PID)"

# --- Monitoring Loop ---
while sleep 30; do
    if ! kill -0 $API_PID 2>/dev/null; then
        echo "❌ API process died! Restarting..." | tee -a "$LOG_DIR/errors.log"
        # Restart logic here if needed
    fi
    
    if ! kill -0 $UI_PID 2>/dev/null; then
        echo "❌ UI process died! Restarting..." | tee -a "$LOG_DIR/errors.log"
        # Restart logic here if needed
    fi
    
    echo "$(date): System operational"
done

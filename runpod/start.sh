#!/bin/bash
set -euo pipefail

# Initialize logging
LOG_DIR="/workspace/logs"
mkdir -p "$LOG_DIR"
exec > >(tee -a "$LOG_DIR/startup_$(date +%s).log") 2>&1

# Load environment
source /workspace/.env || {
    echo "❌ .env file missing" | tee -a "$LOG_DIR/errors.log"
    exit 1
}

# GPU configuration
export PYTORCH_CUDA_ALLOC_CONF="max_split_size_mb:128"
export TOKENIZERS_PARALLELISM=true

# Start API
echo "🚀 Starting API on port $API_PORT..."
uvicorn src.app.api:app \
    --host 0.0.0.0 \
    --port $API_PORT \
    --workers 1 \
    >> "$LOG_DIR/api.log" 2>&1 &

# Start UI
echo "💻 Starting UI on port $UI_PORT..."
python src/app/ui.py \
    --server-port $UI_PORT \
    --server-name 0.0.0.0 \
    >> "$LOG_DIR/ui.log" 2>&1 &

# Improved health monitoring
echo "👀 Starting health monitoring..."
while sleep 10; do
    HEALTH=$(curl -s "http://localhost:$API_PORT/health")
    if [[ "$HEALTH" != '{"status":"ok"}' ]]; then
        echo "❌ API unhealthy at $(date)" | tee -a "$LOG_DIR/errors.log"
        echo "Last response: $HEALTH" | tee -a "$LOG_DIR/errors.log"
    else
        echo "✅ API healthy at $(date)" >> "$LOG_DIR/health.log"
    fi
done

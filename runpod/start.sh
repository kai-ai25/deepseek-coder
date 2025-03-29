#!/bin/bash
set -euo pipefail

# ======================
# INITIALIZATION
# ======================
source /workspace/.env
mkdir -p $LOG_DIR
exec > >(tee -a "$LOG_DIR/startup_$(date +%s).log") 2>&1

# ======================
# GPU CONFIGURATION
# ======================
export PYTORCH_CUDA_ALLOC_CONF="max_split_size_mb:128"
export TOKENIZERS_PARALLELISM=true
export NCCL_P2P_DISABLE=1  # Fixes A40 multi-GPU issues

# ======================
# START SERVICES
# ======================
echo "🚀 Starting API..."
uvicorn src.app.api:app \
    --host 0.0.0.0 \
    --port $API_PORT \
    --workers 2 \
    --timeout-keep-alive 300 \
    >> "$LOG_DIR/api.log" 2>&1 &

echo "💻 Starting UI..."
python src/app/ui.py \
    --server-port $UI_PORT \
    --server-name 0.0.0.0 \
    >> "$LOG_DIR/ui.log" 2>&1 &

# ======================
# HEALTH MONITORING
# ======================
echo "👀 Monitoring services..."
while sleep 30; do
    # API Health Check
    if ! curl -s "http://localhost:$API_PORT/health" | grep -q "ok"; then
        echo "❌ API unhealthy - restarting..." | tee -a "$LOG_DIR/errors.log"
        pkill -f "uvicorn" && sleep 5
        # Add restart command here
    fi
    
    # GPU Monitoring
    nvidia-smi --query-gpu=utilization.gpu --format=csv >> "$LOG_DIR/gpu.log"
done

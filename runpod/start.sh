#!/bin/bash
set -euo pipefail

# Init
LOG_DIR="/workspace/logs"
mkdir -p "$LOG_DIR"
exec > >(tee -a "$LOG_DIR/startup.log") 2>&1

# Load config
source /workspace/.env || {
    echo "❌ .env load failed" >> "$LOG_DIR/errors.log"
    exit 1
}

# Start services
uvicorn src.app.api:app --host 0.0.0.0 --port ${API_PORT:-8000} >> "$LOG_DIR/api.log" 2>&1 &
python src.app.ui.py --server-port ${UI_PORT:-7860} --server-name 0.0.0.0 >> "$LOG_DIR/ui.log" 2>&1 &

# Health monitor
while sleep 30; do
    curl -s "http://localhost:${API_PORT:-8000}/health" || echo "API unhealthy" >> "$LOG_DIR/errors.log"
done

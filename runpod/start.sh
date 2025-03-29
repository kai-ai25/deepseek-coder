#!/bin/bash
set -euo pipefail

# Initialize logging
LOG_DIR="/workspace/logs"
mkdir -p "$LOG_DIR"
exec &> >(tee -a "$LOG_DIR/startup_$(date +%s).log")

# Load environment
source /workspace/.env || {
    echo "❌ .env file missing" >> "$LOG_DIR/errors.log"
    exit 1
}

# Kill existing services (if any)
echo "🛑 Stopping any existing services..."
pkill -f "uvicorn src.app.api:app" || true
pkill -f "python src/app/ui.py" || true
sleep 2  # Wait for processes to terminate

# Start API (fully detached)
echo "🚀 Starting API on port $API_PORT..."
nohup uvicorn src.app.api:app \
    --host 0.0.0.0 \
    --port $API_PORT \
    --workers 1 \
    >> "$LOG_DIR/api.log" 2>&1 & disown

# Start UI (fully detached)
echo "💻 Starting UI on port $UI_PORT..."
nohup python src/app/ui.py \
    --server-port $UI_PORT \
    --server-name 0.0.0.0 \
    >> "$LOG_DIR/ui.log" 2>&1 & disown

# Verify startup
echo "⏳ Verifying services..."
sleep 5
if curl -s "http://localhost:$API_PORT/health" | grep -q "ok"; then
    echo "✅ Services started successfully"
else
    echo "❌ Service startup failed - check logs in $LOG_DIR/"
fi

exit 0

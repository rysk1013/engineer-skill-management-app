#!/usr/bin/env bash

set -euo pipefail

FRONTEND_URL="${FRONTEND_URL:-http://localhost:3000}"
BACKEND_HEALTH_URL="${BACKEND_HEALTH_URL:-http://localhost:8000/api/v1/health}"

echo "[INFO] Checking frontend..."
curl --fail --silent --show-error \
  --head \
  "$FRONTEND_URL" \
  >/dev/null

echo "[OK] Frontend is reachable: $FRONTEND_URL"

echo "[INFO] Checking backend health..."
curl --fail --silent --show-error \
  "$BACKEND_HEALTH_URL" \
  >/dev/null

echo "[OK] Backend health check passed: $BACKEND_HEALTH_URL"

echo "[INFO] Smoke test completed successfully."

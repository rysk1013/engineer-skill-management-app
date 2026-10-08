#!/usr/bin/env bash

set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

cd "$ROOT_DIR"

FRONTEND_URL="${FRONTEND_URL:-http://localhost:3000}"
BACKEND_HEALTH_URL="${BACKEND_HEALTH_URL:-http://localhost:8000/api/v1/health}"

ENV_FILE="${ENV_FILE:-.env}"
COMPOSE_FILE="${COMPOSE_FILE:-compose.yaml}"

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

echo "[INFO] Checking Redis..."
redis_response="$(
  docker compose \
    --env-file .env \
    -f compose.yaml \
    exec -T redis \
    sh -lc 'redis-cli \
      --user better-auth \
      --pass "$REDIS_BETTER_AUTH_PASSWORD" \
      --no-auth-warning \
      PING'
)"

if [[ "$redis_response" != "PONG" ]]; then
  echo "[ERROR] Redis health check failed."
  exit 1
fi

echo "[OK] Redis health check passed."

echo "[INFO] Smoke test completed successfully."

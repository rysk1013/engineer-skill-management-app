#!/usr/bin/env bash

set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

source "$ROOT_DIR/scripts/lib/common.sh"

cd "$ROOT_DIR"

ENV_FILE=".env"
ENV_EXAMPLE_FILE=".env.example"
BACKEND_ENV_FILE="backend/.env"
BACKEND_EXAMPLE_ENV_FILE="backend/.env.example"
COMPOSE_FILE="compose.yaml"

if [[ ! -f "$ENV_FILE" ]]; then
  echo "[INFO] Creating $ENV_FILE from $ENV_EXAMPLE_FILE..."
  cp "$ENV_EXAMPLE_FILE" "$ENV_FILE"
fi

if [[ ! -f "$BACKEND_ENV_FILE" ]]; then
  echo "[INFO] Creating $BACKEND_ENV_FILE from $BACKEND_EXAMPLE_ENV_FILE.."
  cp "$BACKEND_EXAMPLE_ENV_FILE" "$BACKEND_ENV_FILE"
fi

echo "[INFO] Validating development compose configuration..."
compose_config "$ENV_FILE" "$COMPOSE_FILE"

echo "[INFO] Building development images..."
compose_build "$ENV_FILE" "$COMPOSE_FILE"

echo "[INFO] Starting development containers..."
compose_up "$ENV_FILE" "$COMPOSE_FILE"

if ! grep -Eq '^APP_KEY=.+$' "$BACKEND_ENV_FILE"; then
echo "[INFO] Generating Laravel application key..."
docker compose \
  --env-file "$ENV_FILE" \
  -f "$COMPOSE_FILE" \
  exec backend php artisan key:generate
else
  echo "[INFO] Laravel application key is already configured."
fi

echo "[INFO] Running database migrations..."
docker compose \
  --env-file "$ENV_FILE" \
  -f "$COMPOSE_FILE" \
  exec backend php artisan migrate --force

echo "[INFO] Generating OpenAPI types..."
docker compose \
  --env-file "$ENV_FILE" \
  -f "$COMPOSE_FILE" \
  run --rm openapi pnpm check

echo "[INFO] Running smoke test..."
"$ROOT_DIR/scripts/smoke-test.sh"

echo "[INFO] Development environment setup completed successfully."

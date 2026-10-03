#!/usr/bin/env bash

set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

source "$ROOT_DIR/scripts/lib/common.sh"

cd "$ROOT_DIR"

ENV_FILE=".env.production"
COMPOSE_FILE="compose.production.yaml"

if [[ ! -f "$ENV_FILE" ]]; then
  echo "[ERROR] $ENV_FILE does not exist."
  echo "[INFO] Copy .env.production.example to $ENV_FILE and configure it."
  exit 1
fi

echo "[INFO] Validating production compose configuration..."
compose_config "$ENV_FILE" "$COMPOSE_FILE"

echo "[INFO] Starting production containers..."
compose_up "$ENV_FILE" "$COMPOSE_FILE"

echo "[INFO] Production containers started successfully."

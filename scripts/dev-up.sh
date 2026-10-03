#!/usr/bin/env bash

set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

source "$ROOT_DIR/scripts/lib/common.sh"

cd "$ROOT_DIR"

PROJECT_NAME="engineer-skill-management-app-dev"
ENV_FILE=".env"
COMPOSE_FILE="compose.yaml"

if [[ ! -f "$ENV_FILE" ]]; then
  echo "[ERROR] $ENV_FILE does not exist."
  echo "[INFO] Copy .env.example to $ENV_FILE and configure it."
  exit 1
fi

echo "[INFO] Validating development compose configuration..."
compose_config "$PROJECT_NAME" "$ENV_FILE" "$COMPOSE_FILE"

echo "[INFO] Starting development containers..."
compose_up "$PROJECT_NAME" "$ENV_FILE" "$COMPOSE_FILE"

echo "[INFO] Development containers started successfully."

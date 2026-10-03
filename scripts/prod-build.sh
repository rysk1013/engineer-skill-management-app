#!/usr/bin/env bash

set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

source "$ROOT_DIR/scripts/lib/common.sh"

cd "$ROOT_DIR"

PROJECT_NAME="engineer-skill-management-app-prod"
ENV_FILE=".env.production"
COMPOSE_FILE="compose.production.yaml"

if [[ ! -f "$ENV_FILE" ]]; then
  echo "[ERROR] $ENV_FILE does not exist."
  echo "[INFO] Copy .env.production.example to $ENV_FILE and configure it."
  exit 1
fi

echo "[INFO] Validating production compose configuration..."
compose_config "$PROJECT_NAME" "$ENV_FILE" "$COMPOSE_FILE"

echo "[INFO] Building production images..."
compose_build "$PROJECT_NAME" "$ENV_FILE" "$COMPOSE_FILE"

echo "[INFO] Production images built successfully."

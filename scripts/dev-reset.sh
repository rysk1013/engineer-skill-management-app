#!/usr/bin/env bash

set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

cd "$ROOT_DIR"

PROJECT_NAME="engineer-skill-management-app-dev"
ENV_FILE=".env"
COMPOSE_FILE="compose.yaml"

if [[ ! -f "$ENV_FILE" ]]; then
  echo "[ERROR] $ENV_FILE does not exist."
  echo "[INFO] Run ./scripts/dev-setup.sh first."
  exit 1
fi

echo "[WARN] Development database and named volumes will be deleted."
echo "[INFO] Resetting development environment..."

docker compose \
  -p $PROJECT_NAME \
  --env-file $ENV_FILE \
  -f $COMPOSE_FILE \
  down --volumes --remove-orphans

echo "[INFO] Rebuilding development environment..."
"$ROOT_DIR/scripts/dev-setup.sh"

echo "[INFO] Development environment reset successfully."

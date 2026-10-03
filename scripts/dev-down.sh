#!/usr/bin/env bash

set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

source "$ROOT_DIR/scripts/lib/common.sh"

cd "$ROOT_DIR"

ENV_FILE=".env"
COMPOSE_FILE="compose.yaml"

echo "[INFO] Stopping development containers..."
compose_down "$ENV_FILE" "$COMPOSE_FILE"

echo "[INFO] Development containers stopped successfully."

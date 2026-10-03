#!/usr/bin/env bash

compose_config() {
  local env_file="$1"
  local compose_file="$2"

  docker compose \
    --env-file "$env_file" \
    -f "$compose_file" \
    config >/dev/null
}

compose_up() {
  local env_file="$1"
  local compose_file="$2"

  docker compose \
    --env-file "$env_file" \
    -f "$compose_file" \
    up -d
}

compose_down() {
  local env_file="$1"
  local compose_file="$2"

  docker compose \
    --env-file "$env_file" \
    -f "$compose_file" \
    down
}

compose_build() {
  local env_file="$1"
  local compose_file="$2"

  docker compose \
    --env-file "$env_file" \
    -f "$compose_file" \
    build
}

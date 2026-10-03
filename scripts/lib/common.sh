#!/usr/bin/env bash

compose_config() {
  local project_name="$1"
  local env_file="$2"
  local compose_file="$3"

  docker compose \
    -p "$project_name" \
    --env-file "$env_file" \
    -f "$compose_file" \
    config >/dev/null
}

compose_up() {
  local project_name="$1"
  local env_file="$2"
  local compose_file="$3"

  docker compose \
    -p "$project_name" \
    --env-file "$env_file" \
    -f "$compose_file" \
    up -d
}

compose_down() {
  local project_name="$1"
  local env_file="$2"
  local compose_file="$3"

  docker compose \
    -p "$project_name" \
    --env-file "$env_file" \
    -f "$compose_file" \
    down
}

compose_build() {
  local project_name="$1"
  local env_file="$2"
  local compose_file="$3"

  docker compose \
    -p "$project_name" \
    --env-file "$env_file" \
    -f "$compose_file" \
    build
}

#!/usr/bin/env bash

set -euo pipefail

ACL_FILE="/data/users.acl"

: "${REDIS_BETTER_AUTH_PASSWORD:?REDIS_BETTER_AUTH_PASSWORD is required}"
: "${REDIS_BACKEND_CREDENTIAL_PASSWORD:?REDIS_BACKEND_CREDENTIAL_PASSWORD is required}"

better_auth_password_hash="$(
  printf '%s' "$REDIS_BETTER_AUTH_PASSWORD" \
    | sha256sum \
    | awk '{print $1}'
)"

backend_credential_password_hash="$(
  printf '%s' "$REDIS_BACKEND_CREDENTIAL_PASSWORD" \
    | sha256sum \
    | awk '{print $1}'
)"

cat >"$ACL_FILE" <<EOF
user default off
user better-auth on #${better_auth_password_hash} ~better-auth:* +get +set +del +expire +pexpire +ttl +pttl
user backend-credential on #${backend_credential_password_hash} ~backend-credential:* +get +set +del +expire +pexpire +ttl +pttl
EOF

chmod 600 "$ACL_FILE"

exec redis-server /etc/redis/redis.conf

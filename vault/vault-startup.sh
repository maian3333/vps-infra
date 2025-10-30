#!/bin/sh
set -e

# --- Load envs early (so APP_F4_PASS can come from the file if present) ---
if [ -f vault-secrets.env ]; then
  # shellcheck disable=SC1091
  . vault-secrets.env
fi

# Prefer VAULT_DEV_ROOT_TOKEN_ID (from compose), fallback to APP_F4_PASS, then "root"
ROOT_TOKEN="${VAULT_DEV_ROOT_TOKEN_ID:-${APP_F4_PASS:-root}}"

# Use a valid client address inside the container
export VAULT_ADDR="http://127.0.0.1:8200"

# --- Start Vault dev server ---
vault server -dev -dev-root-token-id="${ROOT_TOKEN}" -dev-listen-address="0.0.0.0:8200" &

# Tiny wait loop so 'vault kv put' won't race the server
for i in $(seq 1 30); do
  if curl -fsS "${VAULT_ADDR}/v1/sys/health" >/dev/null 2>&1; then
    break
  fi
  sleep 0.3
done

# --- Write your secrets (empty defaults are fine) ---
vault kv put secret/infrastructure \
  vps-host="${VPS_HOST:-}" \
  vps-user="${VPS_USER:-}" \
  vps-password="${VPS_PASSWORD:-}" \
  app-f4-pass="${ROOT_TOKEN}" \
  sql-host="${SQL_HOST:-}" \
  sql-port="${SQL_PORT:-}" \
  redis-host="${REDIS_HOST:-}" \
  redis-port="${REDIS_PORT:-}" \
  redis-password="${REDIS_PASSWORD:-}" \
  keycloak-issuer-uri="${KEYCLOAK_ISSUER_URI:-}" \
  client-id="${CLIENT_ID:-}" \
  client-secret="${CLIENT_SECRET:-}" \
  schema-registry-url="${SCHEMA_REGISTRY_URL:-}" \
  s2s-client-id="${S2S_CLIENT_ID:-}" \
  s2s-client-secret="${S2S_CLIENT_SECRET:-}"

# Optional Kafka certs
if [ -f /central-server-config/tls/kafka-broker-cert.pem ]; then
  vault kv put secret/common-kafka \
    kafka-broker-cert="$(cat /central-server-config/tls/kafka-broker-cert.pem)" \
    kafka-broker-key="$(cat /central-server-config/tls/kafka-broker-key.pem)" \
    kafka-ca-cert="$(cat /central-server-config/tls/kafka-ca-cert.pem)"
fi

wait

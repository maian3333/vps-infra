#!/bin/sh
set -eu

# Start Vault in dev mode (root token: root)
vault server -dev -dev-root-token-id=root -dev-listen-address="0.0.0.0:8200" &
sleep 5


# Load environment vars
if [ -f /central-server-config/vault-secrets.env ]; then
  . /central-server-config/vault-secrets.env
fi

# Just write directly — no checks
vault kv put secret/infrastructure \
  vps-host="${VPS_HOST:-}" \
  vps-user="${VPS_USER:-}" \
  vps-password="${VPS_PASSWORD:-}" \
  app-f4-pass="${APP_F4_PASS:-}" \
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

# Keep Vault alive
wait

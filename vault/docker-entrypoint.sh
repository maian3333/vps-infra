#!/bin/bash

# Vault Docker Entrypoint with Initialization
# This script starts Vault and initializes it if needed

set -e

echo "🚀 Starting Vault with auto-initialization..."

# Load environment variables from secrets file
if [ -f "/central-server-config/vault-secrets.env" ]; then
    echo "📋 Loading secrets from environment file..."
    source /central-server-config/vault-secrets.env
    echo "✅ Environment variables loaded successfully"
else
    echo "❌ Error: vault-secrets.env file not found at /central-server-config/"
    exit 1
fi

# Set VAULT_ADDR to use 127.0.0.1 instead of localhost
export VAULT_ADDR="http://127.0.0.1:8200"

# Start Vault server in background
echo "🔧 Starting Vault server..."
vault server -config=/vault/config/vault.hcl &
VAULT_PID=$!

# Give Vault a moment to start up
echo "⏳ Giving Vault time to start..."
sleep 10

# Wait for Vault to be ready
echo "⏳ Waiting for Vault to be ready..."
for i in 1 2 3 4 5 6 7 8 9 10 11 12 13 14 15; do
    echo "🔍 Checking Vault API health (attempt $i/15)..."
    # Check if we get any response (including 503 for sealed vault)
    # Use wget with --server-response to capture HTTP status
    HTTP_STATUS=$(wget -q --timeout=5 --server-response -O - http://127.0.0.1:8200/v1/sys/health 2>&1 | grep "HTTP/" | head -1 | awk '{print $2}' | tr -d '\r\n' || echo "000")
    
    if [ "$HTTP_STATUS" = "200" ] || [ "$HTTP_STATUS" = "503" ]; then
        echo "✅ Vault API is responding (HTTP $HTTP_STATUS)!"
        break
    else
        echo "❌ Vault API not ready (HTTP $HTTP_STATUS), waiting 5 seconds..."
        sleep 5
    fi
    
    if [ $i -eq 15 ]; then
        echo "❌ ERROR: Vault API failed to respond after 15 attempts"
        echo "🔍 Checking if Vault process is still running..."
        if kill -0 $VAULT_PID 2>/dev/null; then
            echo "✅ Vault process is running, but API not ready"
        else
            echo "❌ Vault process has died"
            exit 1
        fi
        exit 1
    fi
done

# Check if already initialized
echo "🔍 Checking Vault initialization status..."
INIT_STATUS=$(vault status -format=json 2>/dev/null | grep -o '"initialized":[^,]*' | cut -d':' -f2 || echo "false")

if [ "$INIT_STATUS" = "false" ]; then
    echo "🔐 Initializing Vault..."
    
    # Initialize Vault
    vault operator init -key-shares=1 -key-threshold=1 -format=json > /tmp/init.json
    
    ROOT_TOKEN=$(grep -o '"root_token":"[^"]*"' /tmp/init.json | cut -d'"' -f4)
    UNSEAL_KEY=$(grep -o '"keys":\["[^"]*"' /tmp/init.json | cut -d'"' -f4)
    
    echo "✅ Vault initialized with root token: ${ROOT_TOKEN:0:20}..."
    
    # Unseal Vault
    echo "🔓 Unsealing Vault..."
    vault operator unseal "$UNSEAL_KEY"
    
    # Login with root token
    vault login "$ROOT_TOKEN"
    
    # Enable KV v2 secrets engine
    echo "🔧 Enabling KV v2 secrets engine..."
    vault secrets enable -path=secret kv-v2
    
    # Store infrastructure secrets
    echo "📝 Storing infrastructure secrets..."
    vault kv put secret/infrastructure \
        vps-host="$VPS_HOST" \
        vps-user="$VPS_USER" \
        vps-password="$VPS_PASSWORD" \
        app-f4-pass="$APP_F4_PASS" \
        sql-host="$SQL_HOST" \
        sql-port="$SQL_PORT" \
        redis-host="$REDIS_HOST" \
        redis-port="$REDIS_PORT" \
        redis-password="$REDIS_PASSWORD" \
        keycloak-issuer-uri="$KEYCLOAK_ISSUER_URI" \
        client-id="$CLIENT_ID" \
        client-secret="$CLIENT_SECRET" \
        schema-registry-url="$SCHEMA_REGISTRY_URL" \
        s2s-client-id="$S2S_CLIENT_ID" \
        s2s-client-secret="$S2S_CLIENT_SECRET"
    
    # Store Kafka SSL certificates
    echo "📝 Storing Kafka SSL certificates..."
    if [ -f "/central-server-config/tls/kafka-broker-cert.pem" ]; then
        vault kv put secret/common-kafka \
            kafka-broker-cert="$(cat /central-server-config/tls/kafka-broker-cert.pem)" \
            kafka-broker-key="$(cat /central-server-config/tls/kafka-broker-key.pem)" \
            kafka-ca-cert="$(cat /central-server-config/tls/kafka-ca-cert.pem)"
        
        echo "✅ SSL certificates stored in Vault"
    else
        echo "⚠️  SSL certificates not found at /central-server-config/tls/"
    fi
    
    echo ""
    echo "🎉 Vault auto-setup complete!"
    echo "📋 Stored secrets:"
    echo "  - secret/infrastructure: 14 infrastructure secrets"
    echo "  - secret/common-kafka: 3 SSL certificates"
    echo ""
    echo "🔑 Root token: $ROOT_TOKEN"
    echo "🚀 Your Spring Boot applications can now fetch secrets from Vault!"
    
else
    echo "✅ Vault already initialized"
    
    # Check if Vault is sealed
    SEALED=$(vault status 2>/dev/null | grep "Sealed" | awk '{print $2}' || echo "true")
    
    if [ "$SEALED" = "true" ]; then
        echo "🔓 Vault is sealed, attempting to unseal with known key..."
        # Try to unseal with key we have
        vault operator unseal "$VAULT_UNSEAL_KEY" || echo "Could not unseal automatically"
    fi
    
    # Login with the actual root token
    echo "🔑 Logging into Vault with existing token..."
    for i in 1 2 3 4 5; do
        if vault login "$VAULT_ROOT_TOKEN" 2>/dev/null; then
            echo "✅ Successfully logged into Vault"
            break
        else
            echo "⏳ Login attempt $i failed, retrying in 3 seconds..."
            sleep 3
        fi
    done
    
    # Enable KV v2 secrets engine if not already enabled
    echo "🔧 Ensuring KV v2 secrets engine is enabled..."
    vault secrets enable -path=secret kv-v2 2>/dev/null || echo "KV secrets engine already enabled"
    
    # Check if secrets exist
    if vault kv get secret/infrastructure >/dev/null 2>&1; then
        INFRA_COUNT="14"
        echo "✅ Infrastructure secrets found"
    else
        INFRA_COUNT="0"
        echo "📝 Storing infrastructure secrets..."
        vault kv put secret/infrastructure \
            vps-host="$VPS_HOST" \
            vps-user="$VPS_USER" \
            vps-password="$VPS_PASSWORD" \
            app-f4-pass="$APP_F4_PASS" \
            sql-host="$SQL_HOST" \
            sql-port="$SQL_PORT" \
            redis-host="$REDIS_HOST" \
            redis-port="$REDIS_PORT" \
            redis-password="$REDIS_PASSWORD" \
            keycloak-issuer-uri="$KEYCLOAK_ISSUER_URI" \
            client-id="$CLIENT_ID" \
            client-secret="$CLIENT_SECRET" \
            schema-registry-url="$SCHEMA_REGISTRY_URL" \
            s2s-client-id="$S2S_CLIENT_ID" \
            s2s-client-secret="$S2S_CLIENT_SECRET"
        INFRA_COUNT="14"
    fi
    
    if vault kv get secret/common-kafka >/dev/null 2>&1; then
        KAFKA_COUNT="3"
        echo "✅ Kafka SSL certificates found"
    else
        KAFKA_COUNT="0"
        echo "📝 Storing Kafka SSL certificates..."
        if [ -f "/central-server-config/tls/kafka-broker-cert.pem" ]; then
            vault kv put secret/common-kafka \
                kafka-broker-cert="$(cat /central-server-config/tls/kafka-broker-cert.pem)" \
                kafka-broker-key="$(cat /central-server-config/tls/kafka-broker-key.pem)" \
                kafka-ca-cert="$(cat /central-server-config/tls/kafka-ca-cert.pem)"
            KAFKA_COUNT="3"
            echo "✅ SSL certificates stored in Vault"
        else
            echo "⚠️  SSL certificates not found at /central-server-config/tls/"
        fi
    fi
    
    echo "📊 Current secrets:"
    echo "  - Infrastructure: $INFRA_COUNT secrets"
    echo "  - Kafka SSL: $KAFKA_COUNT certificates"
fi

echo "🎯 Vault initialization completed successfully!"

# Keep the Vault process running
wait $VAULT_PID
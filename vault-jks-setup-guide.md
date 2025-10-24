# Vault JKS Configuration Guide

## Fixed Configuration

### 1. Environment Variables (.env.example)
```bash
# Vault JKS Remote Configuration - FIXED
VAULT_KAFKA_TRUSTSTORE_LOCATION=http://vault:8200/v1/secret/data/kafka/ssl/truststore
VAULT_KAFKA_KEYSTORE_LOCATION=http://vault:8200/v1/secret/data/kafka/ssl/keystore
VAULT_TOKEN=vault-root-token
```

### 2. Vault Container Configuration (docker-compose.yml)
```yaml
vault:
  environment:
    - VAULT_ADDR=http://0.0.0.0:8200  # FIXED: Use 0.0.0.0 instead of localhost
    - VAULT_API_ADDR=http://0.0.0.0:8200
```

### 3. Application Service Configuration Example
Add these environment variables to any application service that needs JKS access:

```yaml
your-application-service:
  image: your-app:latest
  environment:
    # Vault configuration
    - VAULT_ADDR=http://vault:8200
    - VAULT_TOKEN=vault-root-token
    - VAULT_KAFKA_TRUSTSTORE_LOCATION=http://vault:8200/v1/secret/data/kafka/ssl/truststore
    - VAULT_KAFKA_KEYSTORE_LOCATION=http://vault:8200/v1/secret/data/kafka/ssl/keystore
    - VAULT_KAFKA_TRUSTSTORE_PASSWORD=${APP_F4_PASS}
    - VAULT_KAFKA_KEYSTORE_PASSWORD=${APP_F4_PASS}
    - VAULT_KAFKA_KEY_PASSWORD=${APP_F4_PASS}
    
    # Fallback configuration
    - KAFKA_TRUSTSTORE_LOCATION=file:/app/config/kafka.client.truststore.jks
    - KAFKA_KEYSTORE_LOCATION=file:/app/config/kafka.broker.keystore.jks
    
  volumes:
    # Mount JKS files as fallback
    - ./central-server-config/tls:/app/config/tls:ro
```

## Verification Steps

### 1. Start Services
```bash
docker compose up -d vault vault-setup
```

### 2. Check Vault Status
```bash
# Wait for setup to complete
docker logs vault-setup -f

# Verify Vault is accessible
curl http://localhost:8200/v1/sys/health
```

### 3. Verify JKS in Vault
```bash
# Check if secrets exist
curl -H "X-Vault-Token: vault-root-token" \
     http://localhost:8200/v1/secret/data/kafka/ssl/truststore

curl -H "X-Vault-Token: vault-root-token" \
     http://localhost:8200/v1/secret/data/kafka/ssl/keystore
```

### 4. Test Application Access
```bash
# Start your application
docker compose up -d your-application-service

# Check logs for JKS loading
docker logs your-application-service | grep -i "jks\|keystore\|truststore"
```

## Key Fixes Applied

1. **Protocol Fix**: Changed `https://` to `http://` for Vault API access
2. **Network Fix**: Use `vault:8200` for internal Docker network communication
3. **Authentication**: Added `VAULT_TOKEN` for secure access
4. **Container Network**: Updated Vault to use `0.0.0.0:8200` for proper binding

## Troubleshooting

### Common Issues
- **Port already in use**: Check what's using port 8200: `lsof -i :8200`
- **Connection refused**: Ensure Vault container is running: `docker ps | grep vault`
- **Authentication failed**: Verify token is correct: `vault login vault-root-token`
- **Secrets not found**: Run vault-setup service: `docker compose up vault-setup`

### Expected Success Indicators
- ✅ Vault container healthy and accessible
- ✅ JKS secrets stored in Vault
- ✅ Applications load JKS without errors
- ✅ SSL/TLS connections work properly
#!/bin/sh

# Wait for Vault to be ready
sleep 5

# Login with root token
vault login vault-root-token

# Enable KV secrets engine v2
vault secrets enable -path=secret kv-v2

# Store JKS files in Vault
vault kv put secret/kafka/ssl/truststore \
  file=@/vault/jks/kafka.client.truststore.jks \
  password=f4security

vault kv put secret/kafka/ssl/keystore \
  file=@/vault/jks/kafka.broker.keystore.jks \
  password=f4security

# Create policies for JKS access
cat <<EOF > /tmp/jks-policy.hcl
path "secret/data/kafka/ssl/*" {
  capabilities = ["read"]
}
EOF

vault policy write jks-access /tmp/jks-policy.hcl

# Enable userpass auth method
vault auth enable userpass

# Create a user for Kafka services
vault write auth/userpass/users/kafka \
  password=f4security \
  policies=jks-access

echo "Vault JKS configuration completed!"
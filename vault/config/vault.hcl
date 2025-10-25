# ===================================================================
# Vault configuration file: vault/config/vault.hcl
# Persistent file backend, no TLS, UI enabled.
# ===================================================================

ui = true

# HTTP listener
listener "tcp" {
  address         = "0.0.0.0:8200"   # listen on all interfaces
  cluster_address = "0.0.0.0:8201"
  tls_disable     = 1                # disable TLS for local dev
}

# File storage backend
storage "file" {
  path = "/vault/data"
}

# API and cluster addresses
api_addr     = "http://127.0.0.1:8200"
cluster_addr = "http://127.0.0.1:8201"

# Disable mlock to allow running inside Docker
disable_mlock = true

# (Optional) Lower log level for clarity
log_level = "info"

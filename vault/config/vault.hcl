ui = true

listener "tcp" {
  address = "0.0.0.0:8200"
  tls_disable = 1
}

storage "file" {
  path = "/vault/data"
}

api_addr = "http://0.0.0.0:8200"
cluster_addr = "http://0.0.0.0:8201"
disable_mlock = true

# Enable KV secrets engine for JKS files
disable_sealwrap = true
disable_printable_check = true
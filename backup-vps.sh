#!/bin/bash
set -euo pipefail

# ===== CONFIG =====
BASE_DIR="/home/gcp-vm/phungvip"
INFRA_DIR="$BASE_DIR/vps-infra"
TMP_BASE="/tmp"
DATE=$(date +%F_%H-%M)
TMP_DIR="$TMP_BASE/backup-$DATE"
REMOTE="ggdrive:vps-backup/$DATE"

VOLUMES=(
  vault_data
  kafka-oauth-data
  grafana_data
)

# ===== START =====
echo "=== Backup started at $(date) ==="

mkdir -p "$TMP_DIR/docker-volumes"

# 1) Backup Docker volumes -> tar.gz
for V in "${VOLUMES[@]}"; do
  echo "-> Backing up docker volume: $V"
  docker run --rm \
    -v "$V:/data:ro" \
    -v "$TMP_DIR/docker-volumes:/backup" \
    alpine \
    sh -c "tar czf /backup/${V}.tar.gz -C /data ."
done

# 2) Backup vps-infra (exclude .git + junk + letsencrypt)
echo "-> Uploading vps-infra..."
rclone copy "$INFRA_DIR" "$REMOTE/vps-infra" \
  --exclude ".git/**" \
  --exclude "**/.git/**" \
  --exclude "nginx/letsencrypt/**" \
  --exclude "**/node_modules/**" \
  --exclude "**/target/**" \
  --exclude "**/.cache/**" \
  --progress

# 3) Upload docker volume archives
echo "-> Uploading docker volumes..."
rclone copy "$TMP_DIR/docker-volumes" "$REMOTE/docker-volumes" \
  --filter "+ *.tar.gz" \
  --filter "- *" \
  --progress

# 4) Cleanup
rm -rf "$TMP_DIR"

echo "=== Backup finished at $(date) ==="
echo "Remote location: $REMOTE"

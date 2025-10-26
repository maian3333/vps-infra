#!/usr/bin/env bash
set -euo pipefail

# Optionally index repositories if found
if [ -d .git ] || ls -1 | grep -qE ".git$" 2>/dev/null; then
  gkg index || true
fi

# Start GKG in background (binds to 127.0.0.1:27495)
gkg server start --detached

# Wait for GKG to start
for i in {1..60}; do
  if curl -fsS http://127.0.0.1:27495/ >/dev/null 2>&1; then
    break
  fi
  echo "Waiting for GKG to start..."
  sleep 1
done

echo "Starting TCP forwarder 0.0.0.0:27496 -> 127.0.0.1:27495"
exec socat TCP-LISTEN:27496,fork,reuseaddr,bind=0.0.0.0 TCP:127.0.0.1:27495
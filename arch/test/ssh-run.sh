#!/usr/bin/env bash
# ssh-run.sh — resilient SSH exec into the test VM (TCG boot makes sshd flaky
# for the first minute). Usage: ssh-run.sh <port> <command...>
set -uo pipefail
DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PORT="$1"; shift
for i in $(seq 1 12); do
  if ssh -p "$PORT" -i "$DIR/keys/test_key" \
      -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null \
      -o ConnectTimeout=30 -o ServerAliveInterval=15 \
      root@127.0.0.1 "$@"; then
    exit 0
  fi
  echo "[ssh-run] attempt $i failed — retrying in 15s" >&2
  sleep 15
done
echo "[ssh-run] giving up after 12 attempts" >&2
exit 1

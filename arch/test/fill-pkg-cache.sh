#!/usr/bin/env bash
# arch/test/fill-pkg-cache.sh — pre-download every package the VM install test
# needs into arch/test/pkg-cache/ (gitignored), so the VM's pacstrap phase
# serves from the 9p share instead of re-downloading ~1.6 GB per run.
#
# NEVER RUN IN CI (Docker + multi-GB downloads). Safe to re-run: pacman skips
# packages already in the cache.
set -euo pipefail
[[ -n ${CI:-} ]] && { echo "REFUSING TO RUN: package-cache filling must never run in CI." >&2; exit 1; }

DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO="$(cd "$DIR/../.." && pwd)"
CACHE="$DIR/vm-share/pkg-cache"
mkdir -p "$CACHE"

# Union of: packages the live ISO env installs + the generated install-target list
PKGS=$(python3 - "$REPO" <<'PYEOF'
import json, re, sys
repo = sys.argv[1]
pkgs = set()
# live ISO packages
for line in open(f"{repo}/arch/iso/packages.x86_64"):
    line = line.split("#", 1)[0].strip()
    if line and not line.startswith("!"):
        pkgs.add(line)
# generated install-target list (build-iso.sh syncs it into the airootfs)
cfg = json.load(open(f"{repo}/arch/iso/airootfs/root/archinstall-config/user_configuration.json"))
pkgs.update(cfg.get("packages", []))
print(" ".join(sorted(pkgs)))
PYEOF
)
COUNT=$(echo "$PKGS" | wc -w | tr -d ' ')
echo "downloading $COUNT top-level packages (+deps) into $CACHE"

# --cachedir points at the shared folder; -Sw resolves the full dep tree
docker run --rm --platform linux/amd64 --security-opt seccomp=unconfined \
  -v "$CACHE":/cache \
  archlinux:latest \
  bash -euo pipefail -c '
    pacman -Syu --noconfirm --disable-sandbox >/dev/null
    mkdir -p /cache
    pacman -Sw --noconfirm --cachedir /cache '"$PKGS"' >/dev/null
    echo "cache now holds: $(ls /cache | wc -l) packages"
  '
echo "done: $CACHE"

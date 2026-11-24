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

# Union of: live ISO env packages + the bootstrap install list + everything
# post-install.sh will install (full pacman lists) — the host network seeds
# the cache so the in-guest batches mostly hit it.
PKGS=$(python3 - "$REPO" <<'PYEOF'
import sys
repo = sys.argv[1]
pkgs = set()
for listfile in ("arch/iso/packages.x86_64",
                 "arch/iso/packages-bootstrap.txt",
                 "packages-pacman.txt",
                 "packages-pacman-gaming.txt"):
    try:
        for line in open(f"{repo}/{listfile}"):
            line = line.split("#", 1)[0].strip()
            if line and not line.startswith("!"):
                pkgs.add(line)
    except FileNotFoundError:
        pass
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

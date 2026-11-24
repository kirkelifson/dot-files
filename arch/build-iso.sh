#!/usr/bin/env bash
# arch/build-iso.sh — build the custom Arch ISO in Docker (works from macOS/Linux).
#
# Runs mkarchiso inside the official archlinux container against this repo's
# arch/iso profile. No Arch install required. Output: arch/iso/out/*.iso
#
# Usage:
#   ./arch/build-iso.sh            # build
#   ./arch/build-iso.sh --shell    # drop into the build container instead
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ISO_DIR="$SCRIPT_DIR/iso"
WORKDIR="${TMPDIR:-/tmp}/archiso-work"

if ! command -v docker >/dev/null 2>&1; then
  echo "error: docker not found (Docker Desktop / colima). Install it, or build on any Arch machine:" >&2
  echo "  sudo pacman -S archiso && cd $ISO_DIR && sudo mkarchiso -v -w /tmp/archiso-work ." >&2
  exit 1
fi

# Preflight: every file the build (and the install it produces) needs must be
# present BEFORE any work starts. Report ALL missing files at once.
missing=()
[[ -f "$SCRIPT_DIR/archinstall/user_credentials.json" ]] \
  || missing+=("arch/archinstall/user_credentials.json — plaintext user password baked into the ISO; copy archinstall/user_credentials.json.example and set a real password")
[[ -f "$SCRIPT_DIR/archinstall/user_configuration.json" ]] \
  || missing+=("arch/archinstall/user_configuration.json — archinstall config (4.x schema: disk_config merged in; device is a placeholder patched at runtime by autostart.sh)")
[[ -f "$ISO_DIR/airootfs/root/autostart.sh" ]] \
  || missing+=("arch/iso/airootfs/root/autostart.sh — boot-time installer driver")
[[ -f "$SCRIPT_DIR/ssh/authorized_keys" ]] \
  || missing+=("arch/ssh/authorized_keys — your SSH pubkey; without it post-install hardens sshd with no way in over the network")
[[ -f "$SCRIPT_DIR/sway/config" ]] || missing+=("arch/sway/config — sway session config")
[[ -f "$SCRIPT_DIR/sway/foot.ini" ]] || missing+=("arch/sway/foot.ini — foot terminal config")
ls "$SCRIPT_DIR"/sway/scripts/shot-* >/dev/null 2>&1 \
  || missing+=("arch/sway/scripts/shot-* — screenshot scripts")
for list in packages-pacman.txt packages-pacman-gaming.txt; do
  [[ -f "$SCRIPT_DIR/../$list" ]] || missing+=("$list — installed-system package list")
done
if (( ${#missing[@]} )); then
  echo "error: build preflight failed — ${#missing[@]} required file(s) missing:" >&2
  printf '  - %s\n' "${missing[@]}" >&2
  exit 1
fi

mkdir -p "$WORKDIR"

# A completed build leaves a run-once marker; mkarchiso then skips silently.
# Clear the work dir when it holds a finished build so reruns actually build.
if [[ -e "$WORKDIR/build._build_buildmode_iso" ]]; then
  echo "[build-iso] work dir holds a completed build — clearing for a fresh run"
  rm -rf "$WORKDIR"
  mkdir -p "$WORKDIR"
fi

# Sync archinstall configs into the airootfs (mkarchiso bundles airootfs files
# as-is; the credentials file is copied only if present — it is gitignored).
mkdir -p "$ISO_DIR/airootfs/root/archinstall-config"
# Purge anything stale first: a leftover layout JSON with a hardcoded device
# must never ride along into a new ISO.
rm -f "$ISO_DIR/airootfs/root/archinstall-config/"*.json

cp "$SCRIPT_DIR"/archinstall/*.json "$ISO_DIR/airootfs/root/archinstall-config/"

# Generate the installed-system package list from the repo package files —
# packages-pacman.txt (+ gaming) are the single source of truth, so the
# archinstall JSON never needs manual syncing. Runs AFTER the cp above so
# the generated list wins.
python3 - "$SCRIPT_DIR" <<'PYEOF'
import json, os, sys

base = sys.argv[1]

def read_pkg_list(path):
    if not os.path.exists(path):
        return []
    pkgs = []
    for line in open(path):
        line = line.split("#", 1)[0].strip()
        if line:
            pkgs.append(line)
    return pkgs

pkgs = read_pkg_list(os.path.join(base, "..", "packages-pacman.txt"))
pkgs += [p for p in read_pkg_list(os.path.join(base, "..", "packages-pacman-gaming.txt"))
         if p not in pkgs]

src = os.path.join(base, "iso/airootfs/root/archinstall-config/user_configuration.json")
cfg = json.load(open(src))
cfg["packages"] = pkgs
json.dump(cfg, open(src, "w"), indent=2)
print(f"[build-iso] generated package list: {len(pkgs)} packages")
PYEOF

if [[ -f "$SCRIPT_DIR/archinstall/user_credentials.json" ]]; then
  cp "$SCRIPT_DIR/archinstall/user_credentials.json" "$ISO_DIR/airootfs/root/archinstall-config/"
fi

# /etc/localtime is gitignored (chroot leakage) but MUST exist in the live
# environment, or systemd-firstboot hijacks tty1 with its interactive
# timezone wizard before the autologin can launch the installer.
ln -sfn /usr/share/zoneinfo/UTC "$ISO_DIR/airootfs/etc/localtime"
# Belt and braces: mask firstboot outright.
ln -sfn /dev/null "$ISO_DIR/airootfs/etc/systemd/system/systemd-firstboot.service"

DOCKER_ARGS=(
  --rm
  --platform linux/amd64    # archlinux image is amd64-only; runs via Rosetta on Apple Silicon
  --security-opt seccomp=unconfined  # pacman's sandbox seccomp fails under emulation otherwise
  --privileged              # squashfs/loop device setup during build
  -v "$ISO_DIR":/profile
  -v "$WORKDIR":/work
  # Persistent pacman package cache — rebuilds only download NEW/updated
  # packages instead of the full set every time. Gitignored; delete to reset.
  -v "$ISO_DIR/.pkg-cache":/var/cache/pacman/pkg
  archlinux:latest
)
mkdir -p "$ISO_DIR/.pkg-cache"
# Only allocate a TTY when running from an interactive terminal
if [[ -t 0 ]]; then
  DOCKER_ARGS=("-it" "${DOCKER_ARGS[@]}")
fi

if [[ "${1:-}" == "--shell" ]]; then
  echo "[build-iso] interactive container; profile mounted at /profile, work at /work"
  exec docker run "${DOCKER_ARGS[@]}" bash
fi

echo "[build-iso] building ISO (profile: $ISO_DIR)"
echo "[build-iso] work dir: $WORKDIR (reused between runs; delete to force a full rebuild)"
echo ""

docker run "${DOCKER_ARGS[@]}" bash -euo pipefail -c '
  # --disable-sandbox: pacman seccomp fails under Rosetta emulation
  pacman -Syu --noconfirm --disable-sandbox archiso >/dev/null
  cd /profile
  mkarchiso -v -w /work .
'

echo ""
echo "[build-iso] done. ISO:"
ls -lh "$ISO_DIR"/out/*.iso
echo ""
echo "Flash from macOS (plug in USB, then):"
echo "  diskutil list                       # find the USB disk, e.g. disk4"
echo "  diskutil unmountDisk /dev/disk4"
echo "  sudo dd if=$ISO_DIR/out/archlinux-*.iso of=/dev/rdisk4 bs=4M status=progress"
echo ""
echo "If out/ is root-owned:  sudo chown -R \"\$(id -un)\" \"$ISO_DIR/out\""

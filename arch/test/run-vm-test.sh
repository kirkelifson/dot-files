#!/usr/bin/env bash
# arch/test/run-vm-test.sh — full local VM verification of the arch install kit.
#
# NEVER RUN IN CI: boots QEMU with TCG emulation, drives the unattended
# archinstall over QMP, and (with --post-install) validates post-install.sh
# over SSH. Requires an arm64/x86_64 Mac with qemu + tesseract installed.
#
# Stages:
#   run-vm-test.sh install        # fresh 40G disk, ISO install, ends after completion
#   run-vm-test.sh prep-ssh       # ISO chroot: sshd + keys + 9p share for post-install
#   run-vm-test.sh post-install   # run post-install.sh in the installed system over SSH
#   run-vm-test.sh verify         # assert post-install outcomes over SSH
#
# The VM is launched by this script if none is running; artifacts (disk,
# vars.fd, shots, keys) stay in this directory and are gitignored.
set -euo pipefail

[[ -n ${CI:-} ]] && { echo "REFUSING TO RUN: VM tests must never run in CI (GitHub Actions etc.)." >&2; exit 1; }

DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO="$(cd "$DIR/../.." && pwd)"
ISO="$(ls -t "$REPO"/arch/iso/out/*.iso 2>/dev/null | head -n1 || true)"
[[ -n "$ISO" ]] || { echo "no ISO — run ./arch/build-iso.sh first" >&2; exit 1; }

DISK="$DIR/test-disk.qcow2"
VARS="$DIR/vars.fd"
MON=/tmp/arch-vm-qmp.sock
SSH_PORT=2222
# Host side of post-install's in-guest sshd (:8631). Host 8631 is taken by
# this Mac's own sshd, so the host side maps to 18631; guest stays 8631.
SSH_PORT_POST=18631
SHARE_TAG=vmshare
SHARE_DIR="$DIR/vm-share"
KEY="$DIR/keys/test_key"

# Preflight: required files checked BEFORE any VM work, all missing reported.
# keys/test_key and keys/rootpw are generated locally (gitignored) — test_key
# is created on demand in launch_vm; rootpw must be created once by hand.
missing=()
command -v /opt/homebrew/bin/qemu-system-x86_64 >/dev/null 2>&1 \
  || { command -v qemu-system-x86_64 >/dev/null 2>&1 || missing+=("qemu-system-x86_64 — brew install qemu"); }
[[ -f /opt/homebrew/share/qemu/edk2-i386-vars.fd || -f /usr/share/OVMF/OVMF_VARS.fd ]] \
  || missing+=("edk2/OVMF vars firmware — brew install qemu (macOS) or OVMF (Linux)")
case "${1:-}" in
  install) ;;
  *) [[ -f "$DISK" ]] || missing+=("test-disk.qcow2 — run './run-vm-test.sh install' first to create it") ;;
esac
case "${1:-}" in
  install|prep-ssh|post-install)
    [[ -f "$DIR/keys/rootpw" ]] \
      || missing+=("arch/test/keys/rootpw — throwaway VM root password; create with: umask 077; printf 'vmtest123\\n' > arch/test/keys/rootpw")
    ;;
esac
if (( ${#missing[@]} )); then
  echo "error: harness preflight failed — ${#missing[@]} required file(s)/tool(s) missing:" >&2
  printf '  - %s\n' "${missing[@]}" >&2
  exit 1
fi

vm_running() { pgrep -f "qemu-system-x86_64.*$DISK" >/dev/null 2>&1; }
qmp() { (cd "$DIR" && python3 qmp.py "$@"); }
wait_screen() { (cd "$DIR" && python3 waitfor.py "$1" "${2:-600}" "${3:-15}"); }
type_keys() { qmp key "$1"; }

launch_vm() {
  vm_running && return 0
  rm -f "$VARS"
  cp /opt/homebrew/share/qemu/edk2-i386-vars.fd "$VARS" 2>/dev/null \
    || cp /usr/share/OVMF/OVMF_VARS.fd "$VARS"
  rm -f "$MON"
  mkdir -p "$SHARE_DIR"
  # Test-only throwaway SSH key (gitignored) — never your real one.
  [[ -f "$KEY" ]] || ssh-keygen -t ed25519 -N "" -f "$KEY" -C "arch-vm-test" >/dev/null
  cp "$KEY.pub" "$SHARE_DIR/authorized_keys"
  cp "$REPO/arch/post-install.sh" "$SHARE_DIR/post-install.sh"
  cp "$DIR/setup-installed.sh" "$SHARE_DIR/setup-installed.sh"
  # VM_WITH_CD=0 boots the installed disk (no ISO attached)
  local CD_ARGS=()
  if [[ ${VM_WITH_CD:-1} == 1 ]]; then
    CD_ARGS=(-cdrom "$ISO" -boot d)
  fi
  # hostfwd 2222->sshd and 18631->post-install's hardened sshd (:8631 in-guest)
  /opt/homebrew/bin/qemu-system-x86_64 \
    -accel tcg,thread=multi -cpu max -smp 4 -m 4096 -machine q35 \
    -drive if=pflash,format=raw,readonly=on,file=/opt/homebrew/share/qemu/edk2-x86_64-code.fd \
    -drive if=pflash,format=raw,file="$VARS" \
    -drive file="$DISK",if=virtio,format=qcow2 \
    ${CD_ARGS[@]+"${CD_ARGS[@]}"} \
    -netdev "user,id=n0,hostfwd=tcp:127.0.0.1:${SSH_PORT}-:22,hostfwd=tcp:127.0.0.1:${SSH_PORT_POST}-:8631" \
    -device virtio-net-pci,netdev=n0 \
    -virtfs "local,path=$SHARE_DIR,mount_tag=$SHARE_TAG,security_model=none,id=vshare" \
    -display none -qmp "unix:$MON,server,nowait" &
  sleep 5
  vm_running || { echo "qemu failed to start" >&2; exit 1; }
}

stage_install() {
  [[ -f "$DISK" ]] && { echo "test-disk.qcow2 exists — delete it for a fresh install:"; echo "  rm $DISK"; exit 1; }
  qemu-img create -f qcow2 "$DISK" 40G >/dev/null
  launch_vm
  echo "== waiting for installer target prompt (TCG boot is slow) =="
  wait_screen "Type the device" 600 15
  # The P3 won't exist in a VM — cancel autostart to seed the package cache
  # from the 9p share (if filled via fill-pkg-cache.sh), then restart it.
  qmp keyraw ctrl+c
  sleep 2
  cat > "$DIR/cmds.tmp" <<'EOF'
mkdir -p /share /var/cache/pacman/pkg
mount -t 9p -o trans=virtio,version=9p2000.L vmshare /share
cp -R -n /share/pkg-cache/. /var/cache/pacman/pkg/
bash /root/autostart.sh
EOF
  qmp keysfile "$DIR/cmds.tmp" 4
  sleep 3
  wait_screen "Type the device" 60 5
  type_keys "/dev/vda"
  qmp keyraw ret
  # hard-target prompt: retype the path to confirm the wipe
  wait_screen "Retype the device path" 60 5
  type_keys "/dev/vda"
  qmp keyraw ret
  wait_screen "Press Enter to start" 60 5
  qmp keyraw ret
  echo "== unattended install running — watch shots/wait-now.png =="
  wait_screen "completed without any errors" 2700 60
  echo "== INSTALL COMPLETE =="
  qmp shot "$DIR/shots/install-done.png" || true
}

stage_prep_ssh() {
  launch_vm
  # Reboot into the ISO env (cdrom is attached; -boot d puts it first).
  (cd "$DIR" && python3 vm-reset.py reset)
  wait_screen "Type the device" 600 15
  qmp keyraw ctrl+c   # do NOT install again — we chroot the existing install
  sleep 2
  cat > "$DIR/cmds.tmp" <<'EOF'
mkdir -p /share
mount -t 9p -o trans=virtio,version=9p2000.L vmshare /share
ls /share/setup-installed.sh
bash /share/setup-installed.sh
EOF
  qmp keysfile "$DIR/cmds.tmp" 4
  echo "== chroot prep running (sshd, keys, 9p mount unit) =="
  wait_screen "setup-installed: DONE" 600 10
}

stage_post_install() {
  launch_vm
  # Boot the installed system: eject cd, reset.
  (cd "$DIR" && python3 vm-reset.py boot-disk)
  echo "== waiting for sshd in the installed system =="
  for _ in $(seq 1 60); do
    nc -z 127.0.0.1 "$SSH_PORT" 2>/dev/null && break
    sleep 10
  done
  nc -z 127.0.0.1 "$SSH_PORT" || { echo "sshd never came up on :$SSH_PORT" >&2; exit 1; }
  echo "== running post-install.sh (sudo NOPASSWD was set in prep) — 10-40 min under TCG =="
  printf 'n\n' | ssh -p "$SSH_PORT" -i "$KEY" -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null \
    root@127.0.0.1 "bash /mnt/testshare/post-install.sh"
  echo "== post-install finished =="
}

stage_verify() {
  echo "== verifying post-install outcomes over ssh :$SSH_PORT_POST =="
  SSH="ssh -p $SSH_PORT_POST -i $KEY -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null root@127.0.0.1"
  $SSH 'echo; echo "--- sshd on 8631:"; ss -tlnp | grep 8631
echo "--- multilib:"; grep -A1 "^\[multilib\]" /etc/pacman.conf | head -2
echo "--- zram:"; zramctl | head -2
echo "--- river config:"; ls /home/xtc/.config/river 2>/dev/null || ls /home/*/.config/river
echo "--- bootctl:"; cat /boot/loader/loader.conf
echo "--- dot-files:"; ls -d /home/xtc/dot-files 2>/dev/null || ls -d /home/*/dot-files
echo "--- gaming spot-check:"; pacman -Q steam lutris wine 2>/dev/null || pacman -Q | grep -icE "steam|lutris|wine"
echo "--- pkg count:"; pacman -Q | wc -l'
}

stage_watch() {
  # View the VM in a window on your desktop (boots the installed disk).
  vm_running && { echo "a headless VM is already running — kill it first: pkill -f qemu-system" >&2; exit 1; }
  rm -f "$VARS" "$MON"
  cp /opt/homebrew/share/qemu/edk2-i386-vars.fd "$VARS" 2>/dev/null \
    || cp /usr/share/OVMF/OVMF_VARS.fd "$VARS"
  mkdir -p "$SHARE_DIR"
  /opt/homebrew/bin/qemu-system-x86_64 \
    -accel tcg,thread=multi -cpu max -smp 4 -m 4096 -machine q35 \
    -drive if=pflash,format=raw,readonly=on,file=/opt/homebrew/share/qemu/edk2-x86_64-code.fd \
    -drive if=pflash,format=raw,file="$VARS" \
    -drive file="$DISK",if=virtio,format=qcow2 \
    -netdev "user,id=n0,hostfwd=tcp:127.0.0.1:${SSH_PORT}-:22,hostfwd=tcp:127.0.0.1:${SSH_PORT_POST}-:8631" \
    -device virtio-net-pci,netdev=n0 \
    -display default,show-cursor=on \
    "$@"
  echo "VM window closed."
}

case "${1:-}" in
  install)      stage_install ;;
  prep-ssh)     stage_prep_ssh ;;
  post-install) stage_post_install ;;
  verify)       stage_verify ;;
  watch)        stage_watch "$@" ;;
  *) echo "usage: $0 {install|prep-ssh|post-install|verify|watch}" >&2; exit 1 ;;
esac

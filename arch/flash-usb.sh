#!/usr/bin/env bash
# arch/flash-usb.sh — write the built ISO to a USB stick (macOS or Linux).
#
# Usage:
#   ./arch/find-usb.sh              # first: find your USB device id
#   ./arch/flash-usb.sh /dev/rdisk4 # macOS — you must supply the device
#   ./arch/flash-usb.sh /dev/sdb    # Linux  — you must supply the device
#
# The device is REQUIRED and the whole disk is overwritten.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
OS="$(uname -s)"
DEV="${1:-}"

if [[ -z "$DEV" ]]; then
  echo "error: no device given." >&2
  echo "Run ./arch/find-usb.sh to identify your USB stick, then:" >&2
  echo "  $0 /dev/rdiskN   # macOS" >&2
  echo "  $0 /dev/sdX      # Linux" >&2
  exit 1
fi

ISO="$(ls -t "$SCRIPT_DIR"/iso/out/*.iso 2>/dev/null | head -n1 || true)"
if [[ -z "${ISO:-}" ]]; then
  echo "error: no ISO found in $SCRIPT_DIR/iso/out/ — run ./arch/build-iso.sh first" >&2
  exit 1
fi
echo "ISO: $ISO ($(du -h "$ISO" | cut -f1))"
echo "Target: $DEV  (entire disk will be overwritten)"

case "$OS" in
  Darwin)
    # Accept both /dev/diskN and /dev/rdiskN; normalize to rdisk for dd.
    [[ "$DEV" == /dev/disk* ]] && DEV="${DEV/disk/rdisk}"
    DISK="${DEV/rdisk/disk}"   # unmount/eject need the block device
    if ! diskutil info "$DISK" >/dev/null 2>&1; then
      echo "error: $DISK does not exist — run ./arch/find-usb.sh" >&2
      exit 1
    fi
    diskutil unmountDisk "$DISK"
    sudo dd "if=$ISO" "of=$DEV" bs=4m status=progress
    diskutil eject "$DISK"
    ;;
  Linux)
    if [[ ! -b "$DEV" ]]; then
      echo "error: $DEV is not a block device — run ./arch/find-usb.sh" >&2
      exit 1
    fi
    sudo umount "${DEV}?"* 2>/dev/null || true
    sudo dd "if=$ISO" "of=$DEV" bs=4M status=progress oflag=direct sync
    sync
    ;;
  *)
    echo "error: unsupported OS $OS" >&2
    exit 1
    ;;
esac

echo ""
echo "Done. $DEV written with $(basename "$ISO") and ejected — boot it via F12 on the Gigabyte board."

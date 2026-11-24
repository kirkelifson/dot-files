#!/usr/bin/env bash
# arch/find-usb.sh — list candidate USB/removable disks for flashing.
# Run this first, then pass the chosen device to flash-usb.sh.
set -euo pipefail

OS="$(uname -s)"
case "$OS" in
  Darwin)
    echo "External/removable disks (macOS):"
    echo ""
    diskutil list external 2>/dev/null || diskutil list
    echo ""
    echo "Device to pass to flash-usb.sh is the /dev/rdiskN identifier"
    echo "(use rdisk, not disk — raw device, much faster to write)."
    echo ""
    echo "Current removable volumes:"
    diskutil list external 2>/dev/null | grep -E "^/dev" || true
    ;;
  Linux)
    echo "Removable disks (Linux):"
    echo ""
    lsblk -do NAME,PATH,SIZE,MODEL,TRAN,RM
    echo ""
    echo "Device to pass to flash-usb.sh is the PATH of the disk (not a"
    echo "partition) with TRAN=usb — e.g. /dev/sdb. RM=1 marks removable."
    ;;
  *)
    echo "error: unsupported OS $OS" >&2
    exit 1
    ;;
esac

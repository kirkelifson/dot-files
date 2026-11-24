#!/bin/bash
# dot-files/iso/airootfs/root/autostart.sh — runs on boot of the live ISO (as root, via /root/.zprofile).
# Boots into the unattended archinstall (4.x) using the bundled config — but first
# shows the drive inventory and lets the user confirm or override the target.
set -e
CONFIG_DIR=/root/archinstall-config
CONFIG="$CONFIG_DIR/user_configuration.json"

# Auto-detect the Crucial P3 by model — printed as a HINT only. The user
# still types the target explicitly below (bare Enter never proceeds).
P3_DEVS=$(lsblk -d -n -o NAME,MODEL | awk 'tolower($0) ~ /crucial.*p3/ {print "/dev/"$1}')
if [[ "$(echo "$P3_DEVS" | grep -c .)" -eq 1 ]]; then
  DETECTED="$(echo "$P3_DEVS" | head -1)"
  echo "Detected Crucial P3 at $DETECTED — suggested target (you still type it below)."
else
  DETECTED=""
  echo "NOTE: could not uniquely identify the Crucial P3 (candidates: '$P3_DEVS')."
  echo "      Pick the target from the inventory below by MODEL/SERIAL."
fi

echo ""
echo "=============== Drive inventory ==============="
lsblk -d -o NAME,MODEL,SERIAL,SIZE,TYPE
echo "--- stable /dev/disk/by-id paths (whole disks only) ---"
# ls -l is deliberate: it shows the symlink targets (model/serial are
# embedded in the by-id names, which is the point of this listing).
# shellcheck disable=SC2012
ls -l /dev/disk/by-id/ | awk '/nvme|mmcblk|sd[a-z]+$/ && !/part/'
echo "==============================================="
echo ""
echo "Reference (from ARCH.md): Samsung 980 Pro = Windows (NEVER touch),"
echo "Crucial P3 = Arch target — on this machine expected at /dev/nvme0n1."
echo "Verify against the MODEL/SERIAL columns above: device enumeration is"
echo "NOT guaranteed, so the inventory is the source of truth, not the path."
echo ""

# Require explicit input: bare Enter NEVER proceeds with any default, so a
# wrong proposal cannot be accepted by accident. Target is confirmed by
# retyping the exact device path after seeing its model/serial/size.
while true; do
  read -r -p "Type the device to wipe and install to (e.g. /dev/nvme0n1): " TARGET
  if [[ -z "$TARGET" ]]; then
    echo "  You must type the device explicitly — there is no silent default."
    continue
  fi
  if [[ ! -b "$TARGET" ]]; then
    echo "  '$TARGET' is not a block device — try again."
    continue
  fi
  TARGET_MODEL=$(lsblk -d -n -o MODEL "$TARGET")
  TARGET_SERIAL=$(lsblk -d -n -o SERIAL "$TARGET")
  # -b for bytes (plain integer for numfmt; human units like '40G' need --from)
  TARGET_SIZE_H=$(lsblk -b -d -n -o SIZE "$TARGET" 2>/dev/null | numfmt --to=iec --suffix=B 2>/dev/null || echo "?")
  echo ""
  echo "  $TARGET = ${TARGET_MODEL:-unknown model} / serial ${TARGET_SERIAL:-?} / ${TARGET_SIZE_H:-?}"
  if [[ "$TARGET_MODEL" == *980*Pro* ]]; then
    echo "  *** THIS IS THE SAMSUNG 980 PRO — THE WINDOWS DRIVE. DO NOT INSTALL HERE. ***"
  fi
  read -r -p "  Retype the device path exactly to confirm wiping it: " CONFIRM
  if [[ "$CONFIRM" == "$TARGET" ]]; then
    break
  fi
  echo "  Confirmation did not match — starting over."
done

# Patch the config for the chosen target: device path, and the root partition
# sized to "rest of disk" (ESP is 1 GiB starting at 1 MiB; leave 1 MiB GPT tail).
python3 - "$CONFIG" "$TARGET" <<'PYEOF'
import json, subprocess, sys

config_path, target = sys.argv[1], sys.argv[2]
ESP_MIB, ROOT_START_MIB, TAIL_MIB = 1024, 1025, 1

total_bytes = int(subprocess.check_output(
    # -d = the disk only: without it, lsblk also lists children
    # (partitions), and a disk with anything on it yields two lines.
    ["lsblk", "-b", "-d", "-n", "-o", "SIZE", target]).strip())
root_mib = total_bytes // (1024 * 1024) - ROOT_START_MIB - TAIL_MIB
if root_mib < 10:
    sys.exit(f"target {target} too small for the layout ({total_bytes} bytes)")

sector = {"unit": "B", "value": 512}
size = lambda v, unit: {"unit": unit, "value": v, "sector_size": sector}

cfg = json.load(open(config_path))
mod = cfg["disk_config"]["device_modifications"][0]
mod["device"] = target
esp, root = mod["partitions"]
esp["start"], esp["size"] = size(1, "MiB"), size(ESP_MIB, "MiB")
root["start"], root["size"] = size(ROOT_START_MIB, "MiB"), size(root_mib, "MiB")

json.dump(cfg, open(config_path, "w"), indent=2)
print(f"config patched: device={target} esp=1GiB root={root_mib}GiB")
PYEOF

# Final sanity display before anything destructive happens.
MODEL=$(lsblk -d -n -o MODEL "$TARGET")
echo ""
echo ">>> Arch will be installed to: $TARGET ($MODEL) — the disk will be WIPED."
read -r -p ">>> Press Enter to start, or Ctrl+C to abort."

CREDS_ARGS=()
[[ -f "$CONFIG_DIR/user_credentials.json" ]] && CREDS_ARGS=(--creds "$CONFIG_DIR/user_credentials.json")

echo ">>> Starting archinstall — live progress below (full log: /var/log/archinstall/install.log)"

archinstall \
  --config "$CONFIG" \
  "${CREDS_ARGS[@]}" \
  --silent &
INSTALL_PID=$!

# --silent suppresses the console; tail the log so progress is visible.
# -F waits for the log to appear; --pid exits tail when archinstall does.
tail -n +1 -F /var/log/archinstall/install.log --pid "$INSTALL_PID"
wait "$INSTALL_PID" || archinstall  # fall back to interactive if the config path fails

echo "Install finished. Reboot with 'reboot' when ready (remove USB)."

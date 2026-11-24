#!/bin/bash
# arch/test/setup-installed.sh — VM-ONLY: prep the freshly installed system for
# post-install validation over SSH. Run from the live ISO env (run-vm-test.sh
# prep-ssh mounts the 9p share and executes this). Never run on real metal,
# never in CI: it installs a throwaway SSH key and NOPASSWD sudo for the
# installed user.
set -uo pipefail
trap 'echo "setup-installed: FAILED at line $LINENO (see /share/setup.log)"' ERR
[[ -n ${CI:-} ]] && { echo "REFUSING: test-only script, never in CI." >&2; exit 1; }

MNT=/mnt
# NOTE: must NOT be under /mnt — setup mounts the installed root at /mnt,
# which would shadow the share and kill the script (set -e).
SHARE=/share

# Full log to the 9p share — survives VM state, readable from the host.
exec > >(tee /share/setup.log) 2>&1

# 9p share into the ISO env (idempotent)
mkdir -p "$SHARE"
mountpoint -q "$SHARE" || mount -t 9p -o trans=virtio,version=9p2000.L vmshare "$SHARE"

# Installed system: btrfs root on the virtio disk. archinstall may have created
# @/@home subvolumes — mount the right ones (a plain mount only shows the
# default subvolume, silently hiding /home and breaking key installation).
ROOT_DEV=$(lsblk -nrpo NAME,FSTYPE,SIZE /dev/vda | awk '$2=="btrfs"{print $1; exit}')
ESP_DEV=$(lsblk -nrpo NAME,FSTYPE,SIZE /dev/vda | awk '$2=="vfat"{print $1; exit}')
mountpoint -q "$MNT" && umount -R "$MNT" 2>/dev/null
mkdir -p "$MNT"
mount "$ROOT_DEV" "$MNT"
if [[ -d "$MNT/@" ]]; then
  umount "$MNT"
  mount -o subvol=@ "$ROOT_DEV" "$MNT"
  mkdir -p "$MNT/home"
  mount -o subvol=@home "$ROOT_DEV" "$MNT/home"
  echo "setup-installed: btrfs subvolumes @ + @home mounted"
fi
mount "$ESP_DEV" "$MNT/boot" 2>/dev/null || true

TARGET_USER=$(awk -F: '$3==1000{print $1; exit}' "$MNT/etc/passwd")
UID_NUM=$(awk -F: -v u="$TARGET_USER" '$1==u{print $3}' "$MNT/etc/passwd")
GID_NUM=$(awk -F: -v u="$TARGET_USER" '$1==u{print $4}' "$MNT/etc/passwd")
echo "setup-installed: target user = $TARGET_USER (root_dev=$ROOT_DEV)"

# chroot DNS: the installed resolv.conf points at the systemd-resolved stub,
# which is not running inside the chroot — use the live env's.
cp /etc/resolv.conf "$MNT/etc/resolv.conf"

arch-chroot "$MNT" pacman -Sy --noconfirm --needed openssh
# Host keys NOW, not at boot (sshd -t fails with "no hostkeys available" otherwise)
arch-chroot "$MNT" ssh-keygen -A
arch-chroot "$MNT" systemctl enable sshd.service

# Throwaway test keys for root AND the user (VM-only)
mkdir -p "$MNT/root/.ssh"
cp "$SHARE/authorized_keys" "$MNT/root/.ssh/authorized_keys"
chmod 700 "$MNT/root/.ssh" && chmod 600 "$MNT/root/.ssh/authorized_keys"

U="$MNT/home/$TARGET_USER"
mkdir -p "$U/.ssh"
cp "$SHARE/authorized_keys" "$U/.ssh/authorized_keys"
chmod 700 "$U/.ssh" && chmod 600 "$U/.ssh/authorized_keys"
chown "$UID_NUM:$GID_NUM" "$U" "$U/.ssh" "$U/.ssh/authorized_keys"

# NOPASSWD sudo for the user (VM-only; lets post-install run ./install as user)
echo "$TARGET_USER ALL=NOPASSWD: ALL" > "$MNT/etc/sudoers.d/99-vm-test"
chmod 440 "$MNT/etc/sudoers.d/99-vm-test"

# 9p share auto-mount in the installed system (post-install runs from it)
cat > "$MNT/etc/systemd/system/mnt-testshare.mount" <<EOF
[Unit]
Description=VM test share (arch/test harness — VM only)
[Mount]
What=vmshare
Where=/mnt/testshare
Type=9p
Options=trans=virtio,version=9p2000.L
[Install]
WantedBy=multi-user.target
EOF
mkdir -p "$MNT/mnt/testshare"
arch-chroot "$MNT" systemctl enable mnt-testshare.mount
printf '9p\n9pnet\n9pnet_virtio\n' > "$MNT/etc/modules-load.d/vm-test-9p.conf"
sync; sync  # flush before any reset — btrfs loses <30s-old writes on hard reset

# Minimal deterministic sshd_config + throwaway root password (VM-only).
# A hard QMP reset loses <30s-old writes (btrfs commit interval), so these
# land here — inside the prep — and get an explicit sync before shutdown.
cat > "$MNT/etc/ssh/sshd_config" <<'EOF'
PermitRootLogin yes
PubkeyAuthentication yes
PasswordAuthentication yes
AuthorizedKeysFile .ssh/authorized_keys
StrictModes yes
UsePAM yes
Subsystem sftp /usr/lib/ssh/sftp-server
EOF
arch-chroot "$MNT" bash -c 'echo root:vmtest123 | chpasswd'

echo "--- verification ---"
V=0
[[ "$(arch-chroot "$MNT" systemctl is-enabled sshd)" == enabled ]] \
  && echo "PASS: sshd enabled" || { echo "FAIL: sshd enabled"; V=1; }
arch-chroot "$MNT" sshd -t && echo "PASS: sshd -t" || { echo "FAIL: sshd -t"; V=1; }
grep -q "^PermitRootLogin yes" "$MNT/etc/ssh/sshd_config" \
  && echo "PASS: PermitRootLogin yes" || { echo "FAIL: PermitRootLogin"; V=1; }
grep -Eq '^root:\$[a-zA-Z0-9]' "$MNT/etc/shadow" \
  && echo "PASS: root password hash set" || { echo "FAIL: root password"; V=1; }
[[ -s "$MNT/root/.ssh/authorized_keys" ]] \
  && echo "PASS: root authorized_keys" || { echo "FAIL: root authorized_keys"; V=1; }
[[ -s "$U/.ssh/authorized_keys" ]] \
  && echo "PASS: user authorized_keys" || { echo "FAIL: user authorized_keys"; V=1; }
[[ -s "$MNT/etc/sudoers.d/99-vm-test" ]] \
  && echo "PASS: sudoers nopasswd" || { echo "FAIL: sudoers nopasswd"; V=1; }
grep -q "$TARGET_USER" "$MNT/etc/sudoers.d/99-vm-test" \
  && echo "PASS: sudoers targets $TARGET_USER" || { echo "FAIL: sudoers user"; V=1; }
[[ -s "$MNT/etc/systemd/system/mnt-testshare.mount" ]] \
  && echo "PASS: 9p mount unit" || { echo "FAIL: 9p mount unit"; V=1; }
[[ -n "$(find "$MNT/etc/ssh" -maxdepth 1 -name 'ssh_host*' -print -quit)" ]] && echo "PASS: host keys" || { echo "FAIL: host keys"; V=1; }
[[ $V -eq 0 ]] || { echo "setup-installed: FAILED verification"; exit 1; }
echo "setup-installed: DONE — eject the cd and reset to boot the installed system"

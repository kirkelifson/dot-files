#!/bin/bash
# post-install.sh — dot-files Arch desktop finishing pass.
# Run ON THE INSTALLED SYSTEM (as the user with sudo), not from the live ISO.
# Source: ~/dot-files/arch/post-install.sh — see ../ARCH.md for the full plan.
set -euo pipefail

REPO_URL="https://github.com/kirkelifson/dot-files.git"
GAMING_LIST_URL="https://raw.githubusercontent.com/kirkelifson/dot-files/main/packages-pacman-gaming.txt"

step() { printf '\n\033[1;34m[+]\033[0m %s\n' "$*"; }
warn() { printf '\033[1;33m[!]\033[0m %s\n' "$*"; }
die()  { printf '\033[1;31m[x]\033[0m %s\n' "$*" >&2; exit 1; }

[[ $EUID -eq 0 ]] || die "Run with sudo (sudo bash post-install.sh)."

# Target user: auto-detect the primary /home user, overridable with
# TARGET_USER=<name> (e.g. sudo TARGET_USER=xtc bash post-install.sh).
if [[ -z ${TARGET_USER:-} ]]; then
  for d in /home/*; do
    u="${d##*/}"
    [[ "$u" == "lost+found" || "$u" == .* ]] && continue
    TARGET_USER="$u"
    break
  done
fi
id "$TARGET_USER" >/dev/null 2>&1 || die "Could not determine the target user (guessed: '${TARGET_USER:-none}'). Re-run with: sudo TARGET_USER=<name> bash post-install.sh"
step "Target user: $TARGET_USER"

step "Multilib repository"
if ! grep -q '^\[multilib\]' /etc/pacman.conf; then
  # Uncomment the multilib block (header + its Include line, idempotent)
  sed -i '/^#\[multilib\]/{N;s/^#\[multilib\]\n#Include = \(.*\)$/[multilib]\nInclude = \1/}' /etc/pacman.conf
  # Verify the multilib block now has both header and Include (SC2015-safe form)
  if ! { grep -q '^\[multilib\]' /etc/pacman.conf \
         && grep -A1 '^\[multilib\]' /etc/pacman.conf | grep -q '^Include'; }; then
    die "Could not enable [multilib] in /etc/pacman.conf — enable it by hand (uncomment [multilib] and its Include line)."
  fi
  warn "Enabled [multilib] in /etc/pacman.conf."
fi
pacman -Syu --noconfirm

# GPU driver FIRST: packages below (mangohud, gaming stack) depend on the
# virtual `vulkan-driver`, and pacman resolves virtual deps to the
# alphabetically-first provider — without vulkan-radeon installed first it
# picks nvidia-utils. Full-AMD build: make RADV the provider from the start.
step "GPU driver (AMD — RADV via mesa; amdgpu is in the kernel, nothing DKMS)"
pacman -S --needed --noconfirm mesa vulkan-radeon vulkan-tools vulkan-mesa-layers \
  lib32-mesa lib32-vulkan-radeon lib32-vulkan-icd-loader lib32-vulkan-mesa-layers

step "Dot-files: clone and run installer"
if [[ -d "/home/$TARGET_USER/dot-files" ]]; then
  sudo -u "$TARGET_USER" git -C "/home/$TARGET_USER/dot-files" pull --ff-only || true
else
  sudo -u "$TARGET_USER" git clone "$REPO_URL" "/home/$TARGET_USER/dot-files"
fi
cd "/home/$TARGET_USER/dot-files"

# Preflight: the kit files post-install (and the session it sets up) need,
# checked BEFORE any package installs. Report ALL missing files at once.
missing=()
[[ -f arch/ssh/authorized_keys ]] \
  || missing+=("arch/ssh/authorized_keys — sshd gets hardened pubkey-only; without keys you cannot ssh in")
[[ -f arch/sway/config ]] || missing+=("arch/sway/config — sway session config")
[[ -f arch/sway/foot.ini ]] || missing+=("arch/sway/foot.ini — foot terminal config")
ls arch/sway/scripts/shot-* >/dev/null 2>&1 || missing+=("arch/sway/scripts/shot-* — screenshot scripts")
[[ -f packages-pacman.txt ]] || missing+=("packages-pacman.txt — installed-system package list")
if (( ${#missing[@]} )); then
  echo "error: post-install preflight failed — ${#missing[@]} required file(s) missing from $PWD:" >&2
  printf '  - %s\n' "${missing[@]}" >&2
  echo "(git -C $PWD pull first, or push arch/ from the repo you maintain and re-clone)" >&2
  exit 1
fi

pacman -S --needed --noconfirm - < <(grep -v '^#' packages-pacman.txt | grep -v '^$')

step "Gaming packages"
if [[ -f packages-pacman-gaming.txt ]]; then
  pacman -S --needed --noconfirm - < <(grep -v '^#' packages-pacman-gaming.txt | grep -v '^$')
else
  curl -fsSL "$GAMING_LIST_URL" | pacman -S --needed --noconfirm -
fi

step "zram (zram-generator, zstd, 32 GB)"
cat > /etc/systemd/zram-generator.conf <<'EOF'
[zram0]
zram-size = ram / 2
compression-algorithm = zstd
EOF
systemctl enable --now systemd-zram-setup@zram0.service 2>/dev/null || true

step "systemd-boot: 3s timeout, Arch default"
CONF="/boot/loader/loader.conf"
printf 'timeout 3\ndefault arch.conf\n' > "$CONF"
bootctl update --no-variables 2>/dev/null || bootctl install --no-variables

step "Boot order: Arch first, Windows second"
ARCH_ID=$(efibootmgr | awk '/Linux Boot Manager/{print $1; exit}' | sed 's/Boot0*//; s/\*//')
WIN_ID=$(efibootmgr | awk '/Windows Boot Manager/{print $1; exit}' | sed 's/Boot0*//; s/\*//')
if [[ -n ${ARCH_ID} && -n ${WIN_ID} ]]; then
  efibootmgr -o "${ARCH_ID},${WIN_ID}"
  echo "Boot order: Arch (${ARCH_ID}) -> Windows (${WIN_ID})"
else
  warn "Could not determine both boot entries; fix with: efibootmgr -o <arch>,<windows>"
fi

step "Windows clock: RealTimeIsUniversal (fixes time skew)"
# Run this in Windows once (admin PowerShell), not here:
warn "In Windows (admin): reg add \"HKLM\\SYSTEM\\CurrentControlSet\\Control\\TimeZoneInformation\" /v RealTimeIsUniversal /t REG_DWORD /d 1 /f"

step "Secure Boot (sbctl) — interactive"
read -rp "Set up Secure Boot now? [y/N] " SB
if [[ ${SB,,} == y ]]; then
  pacman -S --needed --noconfirm sbctl
  sbctl status || true
  sbctl create-keys
  # Keep Microsoft keys so the Windows half keeps booting
  sbctl enroll-keys --firmware-builtin
  sbctl sign -s /boot/vmlinuz-linux
  sbctl sign -s /boot/amd-ucode.img
  sbctl sign -s /boot/EFI/BOOT/BOOTX64.EFI
  sbctl sign -s /boot/EFI/systemd/systemd-bootx64.efi
  sbctl verify
  warn "Reboot into firmware, confirm Secure Boot is ON, then check: sbctl status && vulkaninfo --summary"
  warn "AMD-only build: amdgpu is in-tree, so no module-signing work under lockdown."
else
  warn "Skipped. Run later — steps in ARCH.md §10."
fi

step "SSH: LAN-only, port 8631, pubkey auth only"
SSHD_DIR=/etc/ssh/sshd_config.d
install -d -m 755 "$SSHD_DIR"
# Primary LAN IPv4: whatever the default route egresses through.
LAN_IP=$(ip -4 route get 1.1.1.1 2>/dev/null | awk '{for(i=1;i<=NF;i++) if ($i=="src") print $(i+1); exit}' || true)
if [[ -n ${LAN_IP:-} ]]; then
  LISTEN="ListenAddress ${LAN_IP}"
  echo "Binding sshd to LAN address: ${LAN_IP}"
else
  LISTEN="# ListenAddress not set — no default-route address detected"
  warn "Could not detect a LAN address; sshd will listen on all interfaces."
fi
cat > "$SSHD_DIR/10-lan-hardening.conf" <<EOF
# Managed by dot-files arch/post-install.sh
Port 8631
${LISTEN}
PubkeyAuthentication yes
PasswordAuthentication no
KbdInteractiveAuthentication no
PermitRootLogin no
AllowUsers ${TARGET_USER}
EOF
AK_SRC="/home/$TARGET_USER/dot-files/arch/ssh/authorized_keys"
if [[ -f "$AK_SRC" ]] && grep -Eq '^(ssh-|ecdsa-|sk-)' "$AK_SRC"; then
  install -d -o "$TARGET_USER" -g "$TARGET_USER" -m 700 "/home/$TARGET_USER/.ssh"
  install -o "$TARGET_USER" -g "$TARGET_USER" -m 600 "$AK_SRC" "/home/$TARGET_USER/.ssh/authorized_keys"
  echo "Installed $(grep -cE '^(ssh-|ecdsa-|sk-)' "$AK_SRC") authorized key(s) for $TARGET_USER."
else
  warn "No public keys in ${AK_SRC} — add keys there, then: install -o $TARGET_USER -g $TARGET_USER -m 600 $AK_SRC /home/$TARGET_USER/.ssh/authorized_keys"
fi
sshd -t || die "sshd config test failed — fix $SSHD_DIR/10-lan-hardening.conf"
systemctl enable --now sshd.service
ss -tlnp | grep -E ':8631\b' || warn "sshd is not listening on 8631 yet — check: systemctl status sshd"

step "sway config: config + screenshot scripts → ~/.config/sway"
install -d -o "$TARGET_USER" -g "$TARGET_USER" "/home/$TARGET_USER/.config/sway/scripts"
install -o "$TARGET_USER" -g "$TARGET_USER" -m 644 "/home/$TARGET_USER/dot-files/arch/sway/config" "/home/$TARGET_USER/.config/sway/config"
install -o "$TARGET_USER" -g "$TARGET_USER" -m 755 "/home/$TARGET_USER/dot-files/arch/sway/scripts/shot-"* "/home/$TARGET_USER/.config/sway/scripts/"

step "foot terminal config (14pt — foot's 8pt default is tiny at 4K)"
install -d -o "$TARGET_USER" -g "$TARGET_USER" "/home/$TARGET_USER/.config/foot"
install -o "$TARGET_USER" -g "$TARGET_USER" -m 644 "/home/$TARGET_USER/dot-files/arch/sway/foot.ini" "/home/$TARGET_USER/.config/foot/foot.ini"

# AUR packages via paru. makepkg refuses to run as root, so the helper is
# built as $TARGET_USER and installed with pacman as root (no password
# prompts). Firefox covers the browser if this step fails.
if [[ -s packages-aur.txt ]]; then
  step "AUR helper (paru) + packages-aur.txt"
  BUILD=$(mktemp -d); chown "$TARGET_USER":"$TARGET_USER" "$BUILD"
  if sudo -u "$TARGET_USER" git clone -q --depth 1 https://aur.archlinux.org/paru.git "$BUILD/paru" \
     && sudo -u "$TARGET_USER" bash -c "cd '$BUILD/paru' && makepkg -f --noconfirm >/dev/null 2>&1" \
     && pacman -U --noconfirm "$BUILD"/paru/paru-*.pkg.tar.zst; then
    sudo -u "$TARGET_USER" paru -S --needed --noconfirm - < packages-aur.txt \
      || warn "paru AUR install had failures — run: paru -S --needed <pkg> as $TARGET_USER"
    pacman -Q 1password >/dev/null 2>&1 \
      && echo "  1password installed" || warn "1password not installed (check paru output)"
  else
    warn "paru build failed — AUR packages skipped (firefox is the browser)"
  fi
  rm -rf "$BUILD"
else
  warn "packages-aur.txt missing or empty — AUR packages skipped"
fi

step "Silence TDX probe warning (AMD/VMs have no Intel TDX; the module logs an error every boot)"
printf 'blacklist tdx-host\n' > /etc/modprobe.d/blacklist-tdx-host.conf

step "Remove NVIDIA userspace (full-AMD build — pulled in by vulkan-driver provider choice)"
# vulkan-radeon is installed by now, so nothing depends on nvidia-utils.
pacman -Rns --noconfirm nvidia-utils lib32-nvidia-utils 2>/dev/null \
  || echo "  (nvidia stack not present — nothing to remove)"

step "Finishing touches"
# archinstall can leave root-owned files in the user's home (e.g. fish config)
chown -R "$TARGET_USER":"$TARGET_USER" "/home/$TARGET_USER" || warn "chown of /home/$TARGET_USER failed"
sudo -u "$TARGET_USER" bash -c 'cd ~/dot-files && ./install' || warn "./install had warnings — review output above"
pacman -S --needed --noconfirm --asdeps - < <(grep -v '^#' packages-pacman.txt | grep -v '^$') >/dev/null 2>&1 || true

step "Done. Next: reboot, then run ~/dot-files/arch/verify-install.sh (as your user, no sudo needed for most checks)."

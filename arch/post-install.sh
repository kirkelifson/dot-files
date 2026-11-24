#!/bin/bash
# post-install.sh — dot-files Arch desktop finishing pass.
# Run ON THE INSTALLED SYSTEM (as the user with sudo), not from the live ISO.
# Source: ~/dot-files/arch/post-install.sh — see ../ARCH.md for the full plan.
set -euo pipefail

REPO_URL="https://github.com/kirkelifson/dot-files.git"
GAMING_LIST_URL="https://raw.githubusercontent.com/kirkelifson/dot-files/master/packages-pacman-gaming.txt"

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
  lib32-mesa lib32-vulkan-radeon lib32-vulkan-icd-loader lib32-vulkan-mesa-layers libva-utils

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

step "Snapper: root snapshot timeline (hourly) + cleanup"
if [[ ! -f /etc/snapper/configs/root ]]; then
  pacman -S --needed --noconfirm snapper
  snapper -c root create-config / || warn "snapper create-config failed — set up by hand (Arch Wiki: Snapper)"
fi
if [[ -f /etc/snapper/configs/root ]]; then
  # Tighten retention — the 10/10/10/10 default is heavy on a busy root
  sed -i -e 's/^TIMELINE_LIMIT_HOURLY=.*/TIMELINE_LIMIT_HOURLY="5"/' \
         -e 's/^TIMELINE_LIMIT_DAILY=.*/TIMELINE_LIMIT_DAILY="7"/' \
         -e 's/^TIMELINE_LIMIT_WEEKLY=.*/TIMELINE_LIMIT_WEEKLY="0"/' \
         -e 's/^TIMELINE_LIMIT_MONTHLY=.*/TIMELINE_LIMIT_MONTHLY="0"/' \
         -e 's/^TIMELINE_LIMIT_YEARLY=.*/TIMELINE_LIMIT_YEARLY="0"/' /etc/snapper/configs/root
  systemctl enable --now snapper-timeline.timer snapper-cleanup.timer
fi

step "systemd-boot: 3s timeout, Arch default"
CONF="/boot/loader/loader.conf"
printf 'timeout 3\ndefault arch.conf\n' > "$CONF"
bootctl update --no-variables 2>/dev/null || bootctl install --no-variables

step "Fallback initramfs (archinstall only builds 'default'; re-enable fallback)"
PRESET=/etc/mkinitcpio.d/linux.preset
if grep -q "^PRESETS=('default')$" "$PRESET" 2>/dev/null; then
  sed -i "s/^PRESETS=('default')$/PRESETS=('default' 'fallback')/" "$PRESET"
  sed -i 's/^#fallback_image/fallback_image/' "$PRESET"
  mkinitcpio -P
  echo "  Fallback initramfs rebuilt."
elif [[ -f /boot/initramfs-linux-fallback.img ]]; then
  echo "  Fallback initramfs already present."
else
  mkinitcpio -P
  echo "  Rebuilt all initramfs presets."
fi

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
  # Create authorized_keys only if absent — never clobber host-local edits.
  AK_DST="/home/$TARGET_USER/.ssh/authorized_keys"
  if [[ -e $AK_DST ]]; then
    echo "  $AK_DST already exists — left untouched (add keys to it directly)."
  else
    install -o "$TARGET_USER" -g "$TARGET_USER" -m 600 "$AK_SRC" "$AK_DST"
    echo "Installed $(grep -cE '^(ssh-|ecdsa-|sk-)' "$AK_SRC") authorized key(s) for $TARGET_USER."
  fi
else
  warn "No public keys in ${AK_SRC} — add keys there, then re-run this step"
fi
sshd -t || die "sshd config test failed — fix $SSHD_DIR/10-lan-hardening.conf"
systemctl enable --now sshd.service
ss -tlnp | grep -E ':8631\b' || warn "sshd is not listening on 8631 yet — check: systemctl status sshd"

step "sway config: symlink config + scripts → ~/.config/sway"
# Symlinks, not copies: edits in the repo apply live, and local edits are
# easy to see/commit. Back up any pre-existing regular files first.
SWAY_DIR="/home/$TARGET_USER/.config/sway"
install -d -o "$TARGET_USER" -g "$TARGET_USER" "$SWAY_DIR/scripts"
for rel in config scripts/autotile scripts/shot-region scripts/shot-full scripts/set-wallpaper scripts/toggle-nightlight scripts/generate-wallpapers; do
  src="/home/$TARGET_USER/dot-files/arch/sway/$rel"
  dst="$SWAY_DIR/$rel"
  [[ -e $dst && ! -L $dst ]] && mv "$dst" "$dst.pre-symlink"
  ln -sfn "$src" "$dst"
done
# Waybar config ships in the main dot-files installer (link_config_dirs) —
# nothing to do here unless it's missing (e.g. installer never ran):
if [[ ! -L "/home/$TARGET_USER/.config/waybar" ]]; then
  ln -sfn "/home/$TARGET_USER/dot-files/.config/waybar" "/home/$TARGET_USER/.config/waybar"
fi

step "foot terminal config (14pt — foot's 8pt default is tiny at 4K)"
install -d -o "$TARGET_USER" -g "$TARGET_USER" "/home/$TARGET_USER/.config/foot"
FOOT_DST="/home/$TARGET_USER/.config/foot/foot.ini"
[[ -e $FOOT_DST && ! -L $FOOT_DST ]] && mv "$FOOT_DST" "$FOOT_DST.pre-symlink"
ln -sfn "/home/$TARGET_USER/dot-files/arch/sway/foot.ini" "$FOOT_DST"

# AUR packages via paru. makepkg refuses to run as root, so the helper is
# built as $TARGET_USER and installed with pacman as root (no password
# prompts). Firefox covers the browser if this step fails.
if [[ -s packages-aur.txt ]]; then
  step "AUR helper (paru) + packages-aur.txt"
  BUILD=$(mktemp -d); chown "$TARGET_USER":"$TARGET_USER" "$BUILD"
  if sudo -u "$TARGET_USER" git clone -q --depth 1 https://aur.archlinux.org/paru.git "$BUILD/paru" \
     && sudo -u "$TARGET_USER" bash -c "cd '$BUILD/paru' && makepkg -f --noconfirm >/dev/null 2>&1" \
     && pacman -U --noconfirm "$BUILD"/paru/paru-*.pkg.tar.zst; then
    # paru -S cannot be used from a script: it shells out to `sudo pacman`
    # as $TARGET_USER, which prompts for a password root can't answer
    # (root's credentials don't carry through `sudo -u`). And `paru -S -`
    # feeds # comment lines to pacman as package targets, aborting the
    # batch. Instead: clone from AUR, import any PGP signing keys, install
    # repo deps as root, recurse into AUR deps (makepkg never needs sudo),
    # makepkg as $TARGET_USER, pacman -U as root.
    build_aur() {
      local pkg="$1" depth="${2:-0}" srcinfo dep key
      if (( depth > 4 )); then
        warn "$pkg: dependency nesting deeper than 5 levels — build manually"
        return 1
      fi
      if pacman -Q "$pkg" >/dev/null 2>&1; then
        (( depth == 0 )) && echo "  AUR: $pkg (already installed)"
        return 0
      fi
      echo "  AUR: $pkg"
      sudo -u "$TARGET_USER" git clone -q --depth 1 "https://aur.archlinux.org/$pkg.git" "$BUILD/$pkg" \
        || { warn "$pkg: clone from AUR failed"; return 1; }
      srcinfo=$(sudo -u "$TARGET_USER" bash -c "cd '$BUILD/$pkg' && makepkg --printsrcinfo")
      # Import PGP keys the sources are signed with, else makepkg aborts
      # on signature verification (e.g. 1Password's release key).
      while IFS= read -r key; do
        sudo -u "$TARGET_USER" gpg --batch --keyserver keys.openpgp.org --recv-keys "$key" \
          || sudo -u "$TARGET_USER" gpg --batch --keyserver keyserver.ubuntu.com --recv-keys "$key" \
          || warn "$pkg: could not import signing key $key — signature check may fail"
      done < <(awk '/validpgpkeys =/ {print $3}' <<<"$srcinfo")
      # One unresolvable dep must not abort the others: repo deps install
      # individually as root, AUR deps recurse (they're not in pacman repos).
      # Field-match $1 exactly so optdepends (optional, trailing ": desc")
      # are excluded — SRCINFO lines are tab-indented, so no ^ anchor.
      for dep in $(awk '$1 ~ /^(make|check)?depends(_[a-z0-9]+)?$/ && $2 == "=" {print $3}' <<<"$srcinfo" | sort -u); do
        if pacman -Si "$dep" >/dev/null 2>&1; then
          pacman -S --needed --noconfirm "$dep" >/dev/null \
            || warn "$pkg: repo dep $dep failed to install — makepkg will likely fail"
        else
          build_aur "$dep" $((depth + 1)) || warn "$pkg: AUR dep $dep failed"
        fi
      done
      if sudo -u "$TARGET_USER" bash -c "cd '$BUILD/$pkg' && makepkg -f --noconfirm" \
         && pacman -U --noconfirm "$BUILD/$pkg"/*.pkg.tar.zst; then
        echo "  $pkg installed"
      else
        warn "$pkg: makepkg or pacman -U failed — check output above"
        return 1
      fi
    }
    while IFS= read -r pkg; do
      pkg="${pkg%%#*}"; pkg="${pkg//[[:space:]]/}" # strip comments/whitespace
      [[ -z $pkg ]] && continue
      build_aur "$pkg" 0 || true
    done < packages-aur.txt
    pacman -Q 1password >/dev/null 2>&1 \
      && echo "  1password installed" || warn "1password not installed — see AUR output above"
  else
    warn "paru build failed — AUR packages skipped (firefox is the browser)"
  fi
  rm -rf "$BUILD"
else
  warn "packages-aur.txt missing or empty — AUR packages skipped"
fi

step "Display manager (sddm) — installs with the desktop batch, enable now"
systemctl enable sddm.service 2>/dev/null \
  || warn "sddm not enabled — check: systemctl enable sddm"

step "Bluetooth: enable the service when an adapter is present"
if pacman -Q bluez >/dev/null 2>&1 && ls /sys/class/bluetooth/hci* >/dev/null 2>&1; then
  rfkill unblock bluetooth 2>/dev/null || true
  systemctl enable --now bluetooth.service || warn "bluetooth service failed to start"
else
  echo "  No Bluetooth adapter detected — service left off"
fi

step "Silence TDX probe warning (AMD/VMs have no Intel TDX; the module logs an error every boot)"
printf 'blacklist tdx-host\n' > /etc/modprobe.d/blacklist-tdx-host.conf

step "System tuning (Ryzen 5900X / desktop workstation)"
# -- makepkg: use all threads for builds and native march --
if grep -q '^#MAKEFLAGS=' /etc/makepkg.conf; then
  sed -i 's/^#MAKEFLAGS=.*/MAKEFLAGS="-j$(nproc)"/' /etc/makepkg.conf
fi
# Native CPU optimisation for locally-compiled packages (AUR etc.)
if grep -q '^\(CFLAGS=.*\)-march=x86-64 -mtune=generic' /etc/makepkg.conf; then
  sed -i 's/-march=x86-64 -mtune=generic/-march=native -mtune=native/' /etc/makepkg.conf
fi
# Use all cores for ZSTD package compression (already default for -T0 but explicit)
if grep -q '^COMPRESSZST=.*-T0' /etc/makepkg.conf; then
  :  # already parallel
elif grep -q '^COMPRESSZST=' /etc/makepkg.conf; then
  sed -i "s/^COMPRESSZST=.*/COMPRESSZST=(zstd -c -T0 -)/" /etc/makepkg.conf
fi

# -- CPU governor: performance for desktop (not laptop) --
cat > /etc/tmpfiles.d/cpu-governor.conf <<'EOF'
# Set all CPU cores to performance governor at boot
w /sys/devices/system/cpu/cpu*/cpufreq/scaling_governor - - - - performance
EOF
# Also apply right now
for g in /sys/devices/system/cpu/cpu*/cpufreq/scaling_governor; do
  echo performance > "$g" 2>/dev/null || true
done

# -- amd_pstate EPP: prefer performance on desktop --
cat > /etc/tmpfiles.d/amd-pstate-epp.conf <<'EOF'
w /sys/devices/system/cpu/cpu*/cpufreq/energy_performance_preference - - - - performance
EOF
for e in /sys/devices/system/cpu/cpu*/cpufreq/energy_performance_preference; do
  echo performance > "$e" 2>/dev/null || true
done

# -- I/O scheduler: none for NVMe (already direct to hardware) --
for sched in /sys/block/nvme*/queue/scheduler; do
  echo none > "$sched" 2>/dev/null || true
done
cat > /etc/udev/rules.d/60-io-scheduler.rules <<'EOF'
# NVMe: no scheduler (hardware handles queuing)
ACTION=="add|change", KERNEL=="nvme*", ATTR{queue/scheduler}="none"
# SATA/USB: mq-deadline
ACTION=="add|change", KERNEL=="sd*", ATTR{queue/scheduler}="mq-deadline"
EOF

# -- VM tuning for 64GB RAM desktop --
cat > /etc/sysctl.d/99-desktop-tuning.conf <<'EOF'
# Lower swappiness — plenty of RAM, prefer keeping things in memory
vm.swappiness = 10
# Reduce vfs_cache_pressure — keep dentries/inodes cached longer
vm.vfs_cache_pressure = 50
# Larger dirty page ratio — NVMe can handle big flushes
vm.dirty_ratio = 30
vm.dirty_background_ratio = 10
# Increase inotify watches for large projects (IDEs, file watchers)
fs.inotify.max_user_watches = 524288
fs.inotify.max_user_instances = 1024
EOF
sysctl --system > /dev/null 2>&1

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

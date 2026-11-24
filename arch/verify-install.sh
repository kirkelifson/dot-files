#!/bin/bash
# verify-install.sh — health check for the Arch desktop build (arch/README.md).
# Run as your normal user; sections needing root note it themselves.
set -u

PASS=0; FAIL=0; WARN=0
ok()   { printf '  \033[32m✓\033[0m %s\n' "$1"; PASS=$((PASS+1)); }
bad()  { printf '  \033[31m✗\033[0m %s\n' "$1"; FAIL=$((FAIL+1)); }
warn() { printf '  \033[33m!\033[0m %s\n' "$1"; WARN=$((WARN+1)); }
hdr()  { printf '\n\033[1m== %s ==\033[0m\n' "$1"; }

have() { command -v "$1" >/dev/null 2>&1; }

hdr "Secure Boot"
if have mokutil && mokutil --sb-state 2>/dev/null | grep -q 'SecureBoot enabled'; then
  ok "Secure Boot: enabled"
else
  warn "Secure Boot: not enabled (fine if intentional — arch/README.md §10)"
fi
if have sbctl; then sbctl status 2>/dev/null | head -3 || warn "sbctl present but status failed"; else warn "sbctl not installed"; fi

hdr "Kernel / CPU"
ok "Kernel: $(uname -r)"
PSTATE=$(cat /sys/devices/system/cpu/amd_pstate/status 2>/dev/null)
[[ $PSTATE == active ]] && ok "amd_pstate: active" || warn "amd_pstate: '${PSTATE:-missing}' (want active)"
have sensors && ok "lm_sensors present: $(sensors -u 2>/dev/null | awk -F': ' '/temp1_input/{printf "%.0f°C\n",$2; exit}')"

hdr "GPU (expect AMD / RADV)"
lspci | grep -qi 'vga\|3d' && ok "GPU present: $(lspci | grep -i 'vga\|3d' | head -1 | cut -d: -f3- | sed 's/^ *//')" || bad "No GPU found via lspci (pciutils missing?)"
lsmod | grep -q '^amdgpu ' && ok "amdgpu kernel module loaded" || bad "amdgpu module not loaded"
if have vulkaninfo; then
  vulkaninfo --summary 2>/dev/null | grep -qi 'radv' && ok "Vulkan ICD: RADV (AMD) present" \
    || bad "No RADV Vulkan ICD — check vulkan-radeon and lib32-vulkan-radeon"
  vulkaninfo --summary 2>/dev/null | grep -qi 'nvidia' && warn "NVIDIA ICD also present — leftover from the 2080 Ti (post-install.sh removes it; now: pacman -Rns nvidia-utils lib32-nvidia-utils)" || true
else
  warn "vulkaninfo missing (vulkan-tools)"
fi
if have vainfo; then
  vainfo 2>/dev/null | grep -q 'VA-API' && ok "VA-API working (video decode)" || warn "vainfo produced no VA-API entry points"
else
  warn "vainfo missing (libva-utils)"
fi

hdr "Display / refresh / VRR"
if have swaymsg && [ -n "$SWAYSOCK" ]; then
  swaymsg -t get_outputs -p 2>/dev/null | grep -qE '3840x2160 @ 14[34]\.' \
    && ok "144 Hz mode active (sway)" \
    || warn "No 3840x2160@144 mode — check swaymsg -t get_outputs and DP-1/DSC"
  swaymsg -t get_outputs -p 2>/dev/null | grep -qi 'Adaptive sync: enabled' \
    && ok "Adaptive sync (VRR) enabled" || warn "Adaptive sync off — check the adaptive_sync line in arch/sway/config"
elif have wlr-randr && [ -n "$WAYLAND_DISPLAY" ]; then
  wlr-randr 2>/dev/null | grep -q '3840x2160@144' \
    && ok "144 Hz mode active (wlr-randr)" \
    || warn "No 3840x2160@144 mode — run wlr-randr and check DP-1/DSC"
  wlr-randr 2>/dev/null | grep -qi 'adaptive-sync.*enabled\|adaptive.*on' \
    && ok "Adaptive sync (VRR) enabled" || warn "Adaptive sync off — check the output block in arch/sway/config"
elif have kscreen-doctor; then
  kscreen-doctor -o 2>/dev/null | grep -Ei '3840x2160.*144|mode.*144' >/dev/null \
    && ok "144 Hz mode active" || warn "144 Hz not detected — check kscreen-doctor -o and DisplayPort/DSC"
  kscreen-doctor -o 2>/dev/null | grep -qi 'adaptiveSync.*enabled\|adaptive.*true' \
    && ok "Adaptive sync (VRR) enabled" || warn "Adaptive sync not confirmed — enable per-monitor in KDE Display settings"
elif have hyprctl; then
  hyprctl monitors 2>/dev/null | grep -q '@144' && ok "144 Hz mode active (Hyprland)" || warn "No @144 mode in hyprctl monitors"
  warn "VRR: check hyprctl monitors 'vrr' field while a game is fullscreen"
else
  warn "No compositor session detected — display checks need a running Wayland session"
fi

hdr "sway WM"
[[ -f "$HOME/.config/sway/config" ]] && ok "\$HOME/.config/sway/config installed" \
  || bad "sway config missing — run post-install.sh or install dot-files/arch/sway/config"
pacman -Q sway >/dev/null 2>&1 && ok "sway installed" || bad "sway MISSING"
for p in waybar foot wofi mako swaylock swayidle grim slurp cliphist playerctl brightnessctl polkit-gnome xdg-desktop-portal-wlr pamixer dex gammastep asciiquarium; do
  pacman -Q "$p" >/dev/null 2>&1 && ok "$p installed" || warn "$p missing (sway companion)"
done

hdr "Dual boot / firmware entries"
if have efibootmgr; then
  ORDER=$(efibootmgr | awk '/BootOrder/{print $2}')
  ARCH=$(efibootmgr | awk '/Linux Boot Manager/{print $1; exit}')
  WIN=$(efibootmgr  | awk '/Windows Boot Manager/{print $1; exit}')
  [[ -n $ARCH ]] && ok "Arch boot entry present: $ARCH" || bad "No 'Linux Boot Manager' NVRAM entry"
  [[ -n $WIN  ]] && ok "Windows boot entry present: $WIN" || warn "No Windows entry (expected if dual booting)"
  ARCH_NUM=${ARCH#Boot}; ARCH_NUM=${ARCH_NUM%\*}
  [[ -n $ARCH_NUM && $ORDER == "$ARCH_NUM",* ]] && ok "Arch is first in BootOrder ($ORDER)" || warn "Arch not first: BootOrder=$ORDER (fix: efibootmgr -o <arch>,<windows>)"
  if [[ -r /boot ]]; then
    ls /boot/EFI/BOOT/BOOTX64.EFI >/dev/null 2>&1 && ok "systemd-boot present on Arch's ESP" || bad "/boot/EFI/BOOT/BOOTX64.EFI missing — bootloader not installed on this ESP"
    [[ -e /boot/initramfs-linux-fallback.img ]] && ok "fallback initramfs present" || bad "initramfs-linux-fallback.img missing — sudo mkinitcpio -P"
  else
    warn "/boot not readable as this user (fmask 0177) — boot file checks skipped (verify with: sudo ls /boot/EFI/BOOT)"
  fi
  # Preset check works without root — catches archinstall's default-only preset
  PRESET=/etc/mkinitcpio.d/linux.preset
  if [[ -r $PRESET ]]; then
    grep -q "'fallback'" "$PRESET" && ok "mkinitcpio preset includes fallback" \
      || bad "mkinitcpio preset missing fallback — re-run post-install.sh or: sudo sed -i \"s/^PRESETS=.*/PRESETS=('default' 'fallback')/\" $PRESET && sudo mkinitcpio -P"
  fi
  have bootctl && { bootctl status 2>/dev/null | grep -q "systemd-boot" && ok "systemd-boot installed and reporting" || bad "bootctl does not report systemd-boot"; } || warn "bootctl missing (systemd pkg?)"
else
  bad "efibootmgr missing"
fi

hdr "Filesystem (btrfs layout from arch/README.md §2)"
ROOT_SRC=$(findmnt -n -o SOURCE / 2>/dev/null)
ROOT_OPTS=$(findmnt -n -o OPTIONS / 2>/dev/null)
if [[ $ROOT_SRC == *"@/"* || $ROOT_SRC == *"[/@]"* ]]; then
  ok "root mounted from btrfs subvolume (@): $ROOT_SRC"
elif [[ $ROOT_OPTS == *subvol=* ]]; then
  ok "root mounted from btrfs subvolume: $ROOT_SRC ($(echo "$ROOT_OPTS" | grep -oP 'subvol=[^ ,]*'))"
else
  warn "root mount: '$ROOT_SRC' — expected a btrfs subvolume"
fi
findmnt -n -o FSTYPE / | grep -q btrfs && ok "root filesystem is btrfs" || bad "root is not btrfs: $(findmnt -n -o FSTYPE /)"
FSTAB_NVME=$(grep -c "nvme" /etc/fstab 2>/dev/null || echo 0)
(( FSTAB_NVME > 0 )) && ok "fstab references $FSTAB_NVME nvme line(s)" || bad "fstab has no nvme entries — installs may not survive reboot"
findmnt -n -o OPTIONS / | grep -q "ssd" && ok "btrfs mounted with ssd option" || true
warn "RealTimeIsUniversal not verifiable from Linux — set it once in Windows (post-install.sh prints the command)"

hdr "Time"
if have timedatectl; then
  timedatectl show -p NTPSynchronized --value 2>/dev/null | grep -q yes && ok "NTP time synchronized" \
    || warn "NTP not synchronized yet: timedatectl set-ntp true"
  timedatectl show -p Timezone --value 2>/dev/null | grep -q America/New_York && ok "timezone America/New_York" \
    || warn "timezone: $(timedatectl show -p Timezone --value 2>/dev/null) (expected America/New_York)"
else
  warn "timedatectl missing (systemd?)"
fi

hdr "Memory / swap"
Z=$(zramctl --output DISKSIZE 2>/dev/null | awk 'NR==2{print $1}')
[[ -n $Z ]] && ok "zram active: $Z" || warn "zram not active (systemd-zram-setup@zram0)"

hdr "Snapshots (snapper)"
if have snapper; then
  ok "snapper installed"
  [[ -d /.snapshots ]] && ok "/.snapshots present" || warn "/.snapshots missing — create the snapper config (Arch Wiki: Snapper)"
  systemctl is-enabled --quiet snapper-timeline.timer && ok "snapper-timeline.timer enabled (hourly snapshots)" \
    || warn "snapper-timeline.timer not enabled — automatic snapshots are off"
  systemctl is-enabled --quiet snapper-cleanup.timer && ok "snapper-cleanup.timer enabled" \
    || warn "snapper-cleanup.timer not enabled — old snapshots accumulate forever"
else
  warn "snapper not installed — no rollback safety net for updates"
fi

hdr "Update visibility"
if have checkupdates; then
  ok "checkupdates available (pacman-contrib)"
else
  warn "checkupdates missing (pacman-contrib) — the weekly update nudge has nothing to run"
fi
if systemctl --user is-enabled --quiet check-updates.timer 2>/dev/null; then
  ok "check-updates.timer enabled (weekly update nudge)"
else
  warn "check-updates.timer not enabled — pending updates are invisible (arch/systemd/user)"
fi

hdr "Services"
for svc in NetworkManager sddm; do
  systemctl is-active --quiet "$svc" && ok "$svc running" || bad "$svc not running"
done
have bluetoothctl && { systemctl is-active --quiet bluetooth && ok "bluetooth running" || warn "bluetooth service off"; } || warn "bluez not installed"

hdr "SSH (LAN-only, port 8631, pubkey auth)"
systemctl is-active --quiet sshd && ok "sshd running" || bad "sshd not running (systemctl enable --now sshd)"
LISTEN=$(ss -tln 2>/dev/null | awk '/:8631 /{print $4; exit}')
[[ -n $LISTEN ]] && ok "listening: $LISTEN" || bad "nothing listening on port 8631"
if [[ -n $LISTEN && $LISTEN == 10.0.0.* ]]; then
  ok "bound to LAN address only ($LISTEN)"
elif [[ -n $LISTEN ]]; then
  warn "sshd bound to $LISTEN — expected a 10.0.0.x LAN address"
fi
if grep -qs 'PasswordAuthentication no' /etc/ssh/sshd_config.d/10-lan-hardening.conf; then
  ok "password auth disabled (pubkey only)"
else
  bad "password auth not disabled — check /etc/ssh/sshd_config.d/10-lan-hardening.conf"
fi
[[ -s "$HOME/.ssh/authorized_keys" ]] && ok "authorized_keys present ($(grep -cE '^(ssh-|ecdsa-|sk-)' "$HOME/.ssh/authorized_keys") key(s))" \
  || bad "\$HOME/.ssh/authorized_keys empty/missing — add keys in \$HOME/dot-files/arch/ssh/authorized_keys, then re-run post-install.sh"

hdr "Packages (spot checks)"
for p in fish git neovim tmux steam gamemode mangohud lutris protontricks corectrl btrfs-progs podman; do
  pacman -Q "$p" >/dev/null 2>&1 && ok "$p installed" || bad "$p MISSING"
done
pacman -Q lib32-mangohud >/dev/null 2>&1 && ok "lib32-mangohud installed" || bad "lib32-mangohud MISSING (multilib enabled?)"
grep -q '^\[multilib\]' /etc/pacman.conf 2>/dev/null && ok "[multilib] enabled in pacman.conf" || bad "[multilib] NOT enabled"

hdr "Dot-files"
if [[ -d $HOME/dot-files/.git ]]; then
  ok "dot-files cloned ($HOME/dot-files)"
  [[ $(getent passwd "$USER" | cut -d: -f7) == *fish* ]] && ok "fish is your login shell" || warn "login shell is not fish (chsh needed)"
  [[ -L $HOME/.tmux.conf ]] && ok ".tmux.conf linked" || warn ".tmux.conf not symlinked — run ./install in ~/dot-files"
else
  bad "\$HOME/dot-files missing"
fi

hdr "Gaming runtime"
CONFDIR="$HOME/.local/share/Steam"
[[ -d $CONFDIR ]] && ok "Steam prefix exists" || warn "Steam not yet run (first launch creates prefix)"
have gamemoderun && ok "gamemoderun available" || bad "gamemoderun missing"
have mangohud && ok "mangohud available" || bad "mangohud missing"

printf '\n\033[1mResult:\033[0m %d pass, %d fail, %d warn\n' "$PASS" "$FAIL" "$WARN"
[[ $FAIL -eq 0 ]] && echo "All hard checks passed — fix the warns at your leisure." || echo "Fix the ✗ items above (arch/README.md has the sections)."
exit $FAIL

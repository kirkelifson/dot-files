#!/usr/bin/env bash
# arch/profiledef.sh — custom Arch ISO profile (dot-files desktop).
# Build on any Arch machine:  sudo pacman -S archiso && sudo mkarchiso -v -w /tmp/archiso-work .
# Output ISO lands in ./out/ — dd to a USB and boot.
# Based on /usr/share/archiso/configs/releng/; only overrides listed below.

# This file is sourced by mkarchiso, not executed standalone: its variables
# are the interface. SC2034 ("appears unused") is a false positive here.
# shellcheck shell=bash disable=SC2034,SC2154

airootfs_image_type="squashfs"
airootfs_image_squashfs_tool="mksquashfs"
# zstd instead of the xz default: ~2-3 min faster builds, ~20% larger ISO
# (a USB stick is not the bottleneck; build time is).
airootfs_image_tool_options=('-comp' 'zstd' '-Xcompression-level' '3' '-b' '1M')
iso_label="DOTFILES_$(date +%Y%m)"
iso_application="dot-files Arch desktop installer"
iso_version="$(date +%Y.%m.%d)"
iso_name="dot-files"
install_dir="arch"

# Silence the TDX probe error every boot (no Intel TDX on AMD/VMs):
# the tdx-host module logs "virt/tdx: TDX not supported by the host
# platform" on any non-TDX machine. Blacklist it on the live medium;
# post-install.sh writes the same blacklist into the installed system.
kernel_params_x86_64="modprobe.blacklist=tdx-host"

# Required by mkarchiso: repo config used to build the live environment
pacman_conf="$(dirname "${BASH_SOURCE[0]}")/pacman.conf"
bootmodes=('bios.syslinux' 'uefi.systemd-boot')

# Packages on the live medium itself (installer + rescue tools).
packages="$(dirname "${BASH_SOURCE[0]}")/packages.x86_64"

# Explicit modes for airootfs files (mkarchiso doesn't preserve exec bits on its own)
file_permissions=(
  ["/root/autostart.sh"]="0:0:755"
  ["/root/.zprofile"]="0:0:644"
)

# NOTE: archinstall JSON configs are bundled as plain airootfs files in
# airootfs/root/archinstall-config/ (build-iso.sh syncs them from
# ../archinstall/). mkarchiso never calls profiledef's old
# _customize_airootfs hook, so that mechanism does nothing.

_customize_airootfs() {
  # Bundle the archinstall JSON configs where autostart.sh expects them.
  mkdir -p "${work_dir}/${arch}/airootfs/root/archinstall-config"
  cp "$(dirname "${BASH_SOURCE[0]}")/../archinstall/"*.json \
     "${work_dir}/${arch}/airootfs/root/archinstall-config/"
}

_customize_bootstrap() {
  :
}

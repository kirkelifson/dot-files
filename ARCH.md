# ARCH.md — Arch Linux desktop build (dev + gaming)

Plan for the current desktop: **Windows 11 and Arch Linux on separate NVMe
drives, dual-booted from the firmware menu.** Windows owns the Samsung 980
Pro 1 TB; Arch owns the Crucial P3 1 TB. Nothing in this plan touches the
Windows disk or its partitions.

Omarchy stays on the 13" MacBook only; this is a **plain Arch** build.
The dot-files install already supports plain Arch (pacman path, Omarchy
detection is opt-in), so `./install` works as-is once packages are in.

## Target hardware

| Part | Notes for Linux |
|---|---|
| Ryzen 9 5900X (Zen 3) | `amd_pstate` driver, `amd-ucode` |
| Gigabyte B550 Vision D-P | Onboard Intel NICs work in-tree; needs BIOS F10+ for the 5900X |
| 64 GB DDR4-3200 CL16 | Enable XMP in BIOS or it runs at 2133 |
| Samsung 980 Pro 1 TB (M2A, CPU-attached) | Windows only — never repartitioned, never touched by the Arch install |
| Crucial P3 1 TB 2280 (M2B or M2C, chipset slot) | Arch root. PCIe 3.0 x4 — matches the chipset slots exactly, so slot choice costs nothing. QLC, DRAM-less: fine for OS/dev, wrong disk for Steam libraries or VM images |
| 2× Samsung 850 Evo 500 GB SATA | Steam library + Proton prefixes / VMs, builds, scratch |
| 2× Seagate 3 TB 7200rpm | Bulk data — likely NTFS migrating from Windows (§6) |
| AMD Radeon RX 7900 XT | RDNA 3 — amdgpu + RADV work out of the box (§3). Needs recent `linux-firmware` |
| Thermaltake Toughpower GF1 850 W | Headroom for 7900 XT (~355 W) + 5900X |
| LG 27GP950-B 3840×2160 144 Hz | FreeSync Premium Pro (VESA Adaptive-Sync) — VRR works out of the box on AMD (§5). 4K@144 needs DSC over DP 1.4 |

### Why the drives stay where they are

M2A (between the PCIe slots, CPU-attached) is the only PCIe 4.0 x4 M.2 on
B550; M2B/M2C run through the chipset at PCIe 3.0 x4. The 980 Pro is a 4.0
drive — it belongs in M2A, where it already is. The P3 is a 3.0 drive and
can't saturate a chipset slot, so it loses nothing in M2B/M2C. Swapping
them would slow Windows and help Arch zero.

Secure Boot is unaffected by slot placement either way: keys live in
firmware NVRAM and signatures live in each OS's ESP, referenced by
partition GUID — not physical slot. Re-seating drives only changes which
device is `nvme0n1` vs `nvme1n1`, which can reorder boot entries (fix in
BIOS or with `efibootmgr`).

## 1. Before installing

- Update the BIOS to F10+ if it's older (5900X support).
- Enable XMP — DDR4-3200 is pointless at JEDEC 2133.
- **Nothing on the Windows side.** No shrinking, no BitLocker suspension,
  no Fast Startup changes — the Arch install never touches that disk.

## 2. Install outline

Arch takes the **whole P3** (wiped):

- **ESP, 1 GB, FAT32** — systemd-boot. Its own drive means Windows updates
  can't clobber it and vice versa: the worst case for any Windows update is
  boot order, never a broken install.
- **Root** — btrfs subvolumes `@`, `@home`, plus `@log` and `@pkg`
  (`/var/log`, pacman cache) so churn stays out of snapshots. Snapper
  runs on `@`: hourly timeline + cleanup timers, and `snap-pacman`
  takes pre/post snapshots around pacman transactions.
- **No swap partition** — 64 GB RAM + zram (zram-generator, zstd, ~32 GB).
- Same username as the other machines so dot-files paths line up.

```
packages: base linux linux-firmware amd-ucode btrfs-progs \
  zram-generator networkmanager sudo fish git efibootmgr sbctl
```

After install, `efibootmgr` to confirm Arch's entry exists and is first;
Windows Boot Manager stays a second NVRAM entry. If Windows updates flip
the order, F12 or `efibootmgr -o` fixes it in one step (§8).

## 3. GPU — AMD / RADV

```
mesa                    # OpenGL + VA-API video decode
vulkan-radeon           # RADV — the AMD Vulkan driver
vulkan-tools            # vkcube / vulkaninfo sanity checks
vulkan-mesa-layers
lib32-mesa
lib32-vulkan-radeon
lib32-vulkan-icd-loader
lib32-vulkan-mesa-layers
```

RADV only, never amdvlk (deprecated upstream; two ICDs installed = games
randomly picking drivers). amdgpu and firmware come from the kernel +
`linux-firmware` — nothing to add. Sanity: `vulkaninfo --summary`,
`vkcube`, `vainfo`, `glxinfo -B`.

river + wlroots + AMD is the best-supported GPU/WM combo on Wayland — no
quirks. VRR: `wlr-randr --output DP-1 --adaptive-sync on` (already in
`arch/river/init`).

> **UPDATE (2026-11):** Arch's `river` moved to 0.5.x — a non-monolithic
> rewrite that dropped `riverctl`, breaking the kit's init. The kit now
> targets **sway** (same wlroots toolchain — waybar/foot/wofi/mako/swaybg/
> swaylock/swayidle/grim/slurp all carry over; the init is now the
> declarative `arch/sway/config`). river 0.5.x can be revisited when its
> ecosystem matures. The historical river notes below are kept for context.

## 4. Window manager — sway (dwm-style, Wayland)

**river.** dwm's model done properly on Wayland — tags, dynamic tiling,
master/stack — but configured at **runtime** with `riverctl` (plain shell
script, no recompiling). In the official repos, actively developed,
wlroots-based. (dwl is the literal dwm-on-Wayland option but is AUR-only
and upstream-unmaintained since Aug 2025; not worth patching against a
moving wlroots target.)

All companions are official repos, wired in `arch/river/init`:
rivertile (layouts, ships with river), waybar (status bar), foot
(terminal), wofi (launcher), mako/swaync (notifications), swaybg,
swaylock, swayidle, grim+slurp (screenshots), wl-clipboard+cliphist,
playerctl (media keys), brightnessctl, gammastep (night light),
polkit-gnome (privilege prompts), xdg-desktop-portal-wlr (screen share),
wlr-randr (mode + VRR flags), xorg-xwayland.

```
river waybar foot wofi mako swaybg swaylock swayidle grim slurp \
  wl-clipboard cliphist playerctl brightnessctl gammastep swaync \
  polkit-gnome xdg-desktop-portal-wlr wlr-randr xorg-xwayland
```

Recovery fallback if river ever fights you: `pacman -S plasma-meta sddm
konsole` — one command, and KDE's display config is the easiest place to
debug 4K/DSC/VRR.

## 5. Display — LG 27GP950-B

- 4K @ 144 Hz over **DisplayPort with DSC** (DP 1.4 + DSC). HDMI 2.1 also
  does 4K144 but DP is the reliable path — use DP.
- Pin the mode: `wlr-randr` line in `arch/river/init`.
- VRR: enable Adaptive-Sync (river init already does) and the monitor OSD
  if it was off. Verify with Mangohud's frametime graph — jagged floor =
  VRR not engaging.
- HDR: leave off on the desktop; per-game via gamescope if ever needed.

## 6. Storage layout

| Disk | Role |
|---|---|
| 980 Pro (M2A) | Windows — untouched |
| Crucial P3 (M2B/M2C) | ESP + btrfs root — Arch |
| 850 Evo #1 | Steam library + Proton prefixes |
| 850 Evo #2 | VMs / builds / scratch |
| 3 TB ×2 | Bulk data (two volumes or mirrored) |

Windows-side disks:

- NTFS reads/writes fine with the in-kernel `ntfs3` driver. Don't use FUSE
  ntfs-3g except for exotic ACL cases.
- Decide per disk: keep NTFS (Windows-recoverable) or reformat to
  ext4/btrfs once data is migrated. Reformat anything the system touches.
- If Windows uses Fast Startup, disable it (`powercfg /h off`) before
  reading its NTFS volumes from Linux — Linux refuses dirty NTFS.
- **Back up anything important before reformatting** — that step is the
  risky one, not the Arch install.

## 7. Gaming layer (`packages-pacman-gaming.txt`)

Separate file so non-gaming machines skip it:

```
# Gaming — requires [multilib] in /etc/pacman.conf
steam
ttf-liberation          # Steam UI font fix
gamemode                # CPU governor + perf switching
mangohud
lib32-mangohud
lutris                  # GOG/Epic/older Windows titles
protontricks            # per-game winetricks for Proton prefixes
lib32-libpulse          # 32-bit audio in Proton games
```

- Steam launch options pattern: `gamemoderun mangohud %command%`.
- Proton: enable Steam Play for all titles; GE-Proton (protonup-qt, AUR)
  per-game only — Valve Proton is the stability baseline.
- `vm.max_map_count` is already 1048576 on Arch — nothing to tune.
- Controllers: `bluez bluez-utils`; Xbox pads work with stock `xpad`.
- AUR helper: `paru`. Pin AUR to explicit installs — no blanket `paru -Syu`
  on a dev box.
- ntsync is automatic when `/dev/ntsync` exists, but Valve's fsync is
  equal-or-faster — treat as a per-game experiment, not config.
- Kernel anti-cheat titles (Valorant, Fortnite, …) have no Linux build —
  those live in the Windows half of the dual boot.

## 8. Dual-boot operation

Two drives, two ESPs, two NVRAM entries — there is very little to
harden because neither OS can damage the other's bootloader.

1. **OS selection at the firmware boot menu (F12 on Gigabyte).** Arch's
   systemd-boot defaults to Arch (`timeout 3`); Windows stays a separate
   NVRAM entry. No cross-ESP chainloading, ever.
2. **Windows updates resetting boot order** — re-assert with
   `efibootmgr -o <arch>,<windows>` (entries via `efibootmgr -v`) or just
   pick at F12; both entries always exist on separate drives.
3. **Time skew** — Windows registry
   `HKLM\SYSTEM\CurrentControlSet\Control\TimeZoneInformation`,
   `RealTimeIsUniversal` (DWORD) = 1. Arch is already UTC.
4. **Fast Startup dirty NTFS** — `powercfg /h off` in Windows if you ever
   mount its data volumes from Linux (§6).

## 9. Secure Boot

Enabling SB on Linux doesn't make kernel anti-cheat games run (they're
Windows-only anyway); what it buys is hardening plus the launchers that
merely check SB/TPM state. Cheap with sbctl, and an all-AMD build has no
out-of-tree modules — amdgpu is in-tree — so there's no driver-signing
maintenance at all.

```bash
pacman -S sbctl
sbctl status                 # Setup Mode should say Disabled
sbctl create-keys
sbctl enroll-keys --firmware-builtin   # keeps Microsoft keys so Windows keeps booting signed
sbctl sign -s /boot/vmlinuz-linux -s /boot/amd-ucode.img \
  -s /boot/EFI/BOOT/BOOTX64.EFI -s /boot/EFI/systemd/systemd-bootx64.efi
sbctl verify                 # all green
reboot → sbctl status        # "Secure Boot: enabled"
```

- sbctl installs a pacman hook that re-signs the kernel on every update.
- If firmware is in Setup Mode, `enroll-keys` handles it; if it refuses,
  clear keys in firmware setup first.
- A BIOS flash resets the keys — keep `sbctl status` in the post-update
  checklist.
- Signing the Windows bootloader from the Arch side is unnecessary:
  Windows already boots fine under the retained Microsoft keys.

## 10. Preconfigured Arch image (one-click install from USB)

Custom archiso with an unattended archinstall config — not a disk image
(a disk image bakes in hardware UUIDs and goes stale; archiso installs
fresh packages every time). **The ISO builds in Docker** — no Arch install
needed, works from the Mac (`arch/build-iso.sh`, ~5.5 min, zstd squashfs),
and `arch/flash-usb.sh` writes it to the USB stick when you plug it in.

**Split of responsibilities — the ISO installs almost nothing:**

- The baked archinstall list is a **minimal bootstrap**
  (`arch/iso/packages-bootstrap.txt`: git, openssh, networkmanager) —
  just enough to boot to a TTY with network and ssh. The unattended
  install takes minutes, not half an hour.
- `arch/post-install.sh` does the rest after first boot: the full
  desktop + gaming stack (`packages-pacman{,-gaming}.txt`), the AUR list
  (`packages-aur.txt` via paru), GPU stack, zram, sshd hardening,
  sway/foot config, boot order, sbctl (interactive). First boot after
  the install is a TTY login; run post-install, reboot, land in sway.

**When an ISO rebuild IS needed** (these are the only things baked in):

- `arch/iso/packages-bootstrap.txt` — the install-time package list
- `arch/iso/airootfs/**` — `autostart.sh`, archinstall configs, motd, etc.
- `arch/iso/profiledef.sh`, boot configs, `pacman.conf`,
  `arch/iso/packages.x86_64` (the live environment's own packages)
- archiso version bumps or a wedged workdir (`build-iso.sh` handles that)

**When a rebuild is NOT needed** (pulled from GitHub at post-install
time — push the repo, then re-run post-install on the target):

- `packages-pacman.txt`, `packages-pacman-gaming.txt`, `packages-aur.txt`
- `arch/post-install.sh`, `arch/verify-install.sh`,
  `arch/ssh/authorized_keys`
- `arch/sway/**` (sway config, foot.ini, screenshot scripts)
- Everything else in the dot-files repo (`./install` links it)
- VM test cycles: `run-vm-test.sh prep-ssh|post-install|verify` boot the
  existing test disk — no ISO attached

**Files live in `arch/` — see `arch/README.md` for build + usage:**

- `arch/build-iso.sh` — Docker build (archlinux image, Rosetta on
  Apple Silicon; emulation quirks handled); preflight-checks all
  required files and reports missing ones before starting
- `arch/flash-usb.sh` — interactive USB flasher for macOS/Linux
- `arch/archinstall/user_configuration.json` — unattended config
  (4.x schema: disk_config merged in; the device is a placeholder
  `/dev/REPLACED-BY-AUTOSTART` patched at runtime by `autostart.sh`)
- `arch/iso/` — custom archiso profile; boots straight into the installer
- `arch/post-install.sh` — desktop + gaming stack, AUR, dot-files
  `./install`, zram, sshd hardening (8631, pubkey-only), sddm enable,
  boot order, sbctl Secure Boot (interactive)
- `arch/verify-install.sh` — health check: Secure Boot, driver, 144 Hz,
  VRR, boot entries, zram, services, package spot-checks; exit code =
  number of failures
- `arch/test/` — local QEMU harness that replays the whole install
  (never in CI; see `arch/test/README.md`)

What it can't automate: disk target confirmation (typed + retype-to-
confirm by design), Secure Boot key enrollment (firmware screen), BIOS
settings (F10+, XMP).

## 11. 5900X tuning

- `amd_pstate=active` is the kernel default — confirm:
  `cat /sys/devices/system/cpu/amd_pstate/status`.
- Governor: `power-profiles-daemon` — `performance` for sessions,
  `balanced` otherwise; gamemode handles in-game switching.
- `corectl` (corectrl): CPU **and GPU** control, fan curves, per-app
  profiles, undervolt on AMD — it does control the GPU on this build
  (relevant given PSU headroom discussions).
- `lm_sensors` + `sensors-detect` once — k10temp gives Tctl for the
  desktop/overlay display.

## 12. What NOT to add

- **Omarchy anything** — laptop-only.
- **Grub / rEFInd** — systemd-boot + firmware menu is enough, and sbctl
  integration is systemd-boot-first.
- **Anything on the Windows ESP** — never chainload, mount, or repair it
  from Arch; separate drives already guarantee isolation.
- **nouveau** — irrelevant on AMD, listed so nobody re-adds it.
- **amdvlk** on the RADV path.
- **Custom kernels (TKG/CachyOS patches)** — stock, or `linux-zen` if
  frame pacing ever bothers; patch sets rot.
- **LUKS retrofit** — decide full-disk encryption BEFORE first real use;
  converting btrfs root to LUKS afterwards means a reinstall. LUKS +
  Secure Boot + dual boot at once is possible but is its own project, not
  day one.

## 13. Order of operations

0. Build the ISO: `./arch/build-iso.sh`, then flash when the USB is
   plugged in: `./arch/flash-usb.sh`.
1. BIOS: F10+ firmware, XMP on, confirm the 980 Pro sits in M2A and the
   P3 in a chipset M.2 slot, boot from USB.
2. Boot custom ISO (§10) or manual install: **wipe the P3** — ESP + btrfs
   root, systemd-boot, zram, user account.
3. Enable multilib, `pacman -Syu`.
4. `pacman -S --needed - < packages-pacman.txt` → `./install`.
5. GPU packages (§3) + reboot; verify with `vulkaninfo --summary`.
6. river + 4K 144 Hz + adaptive sync (§4, §5).
7. Dual-boot basics (§8): efibootmgr order, RealTimeIsUniversal.
8. Secure Boot (§9): sbctl keys, sign, verify.
9. `packages-pacman-gaming.txt`, paru, Steam, Proton.
10. Storage: mount/format SATA disks per §6; Steam library to the 850 Evo.
11. Verify: `vulkaninfo --summary`, 144 Hz active, VRR engaging via
    Mangohud frametimes, `gamemoderun` working, and one F12 reboot into
    Windows to confirm both halves still boot.

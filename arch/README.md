# dot-files/arch/ — preconfigured Arch install kit

Everything the ARCH.md §10 image plan describes, as buildable files.

## Layout

```
arch/
├── README.md                  ← this file
├── build-iso.sh               ← build the ISO in Docker (no Arch install needed)
├── find-usb.sh                ← list USB/removable disks to find the device id
├── flash-usb.sh               ← write the built ISO to the device YOU pass in
├── post-install.sh            ← run on the INSTALLED system (sudo): gaming/GPU/dotfiles/sbctl/river config
├── verify-install.sh          ← run as your user after install: health check
├── river/
│   ├── init                   ← river WM runtime config (keybinds, tags, autostart, 4K144 VRR)
│   └── scripts/shot-*         ← screenshot helpers bound to $mod+S / $mod+Shift+S
├── archinstall/
│   ├── user_configuration.json   ← unattended archinstall 4.x config (disk layout, packages, services)
│   └── user_credentials.json     ← CREATE THIS (never commit): {"users": [{"username": "kirk", "!password": "...", "sudo": true}]}
└── iso/                       ← custom archiso profile
    ├── profiledef.sh
    ├── packages.x86_64           ← packages on the LIVE ISO only
    └── airootfs/root/autostart.sh ← boots → unattended archinstall
```

## Build the ISO (in Docker — works from macOS or Linux)

```bash
./arch/build-iso.sh          # build; ISO lands in arch/iso/out/
./arch/build-iso.sh --shell  # interactive container for poking around
```

- Uses the official `archlinux:latest` image; requires Docker Desktop (or
  colima) running. On Apple Silicon it runs amd64 via Rosetta
  (`--platform linux/amd64` + `seccomp=unconfined` + pacman
  `--disable-sandbox` — emulation quirks already handled by the script).
- Build work dir: `$TMPDIR/archiso-work`. The script clears it
  automatically when it holds a completed build (otherwise mkarchiso
  treats the rerun as already done). Output is root-owned →
  `sudo chown -R $USER out/`.
- Native Arch alternative: `sudo pacman -S archiso && cd arch/iso &&
  sudo mkarchiso -v -w /tmp/archiso-work .`

## Flash the USB (no Linux required)

```bash
./arch/find-usb.sh           # identify the USB stick's device id
./arch/flash-usb.sh /dev/rdisk4   # macOS — you supply the device
./arch/flash-usb.sh /dev/sdb      # Linux — you supply the device
```

The device argument is required (no prompts) — `find-usb.sh` exists
specifically so you can look it up first. The whole disk is overwritten
and the stick is ejected when done. Boot via F12 on the Gigabyte board.

## Install flow (dedicated-drive dual boot: Arch on the Crucial P3, Windows untouched on its own 980 Pro)

1. **In BIOS**: update to F10+ if needed, enable XMP. Verify drive slots —
   980 Pro (Windows) in M2A (CPU-attached), Crucial P3 (Arch) in a chipset
   M.2 slot. Note Secure Boot state — install with SB **off** (Setup Mode)
   and enroll keys later via sbctl. Nothing needs doing in Windows.
2. Nothing to set by hand — the target drive is picked at boot: the installer
   lists all drives, proposes the Crucial P3 (auto-detected by model), and you
   confirm or type another device before anything is wiped.
3. Boot the USB. It shows the drive inventory, waits for you to confirm the
   target (Ctrl+C cancels), then wipes the target disk and installs: ESP at
   /boot, btrfs root, the packages, fish, zram, your user — with live log
   progress on the console.
4. Reboot into Arch, then:
   ```bash
   cd ~/dot-files/arch && sudo bash post-install.sh     # gaming stack, AMD GPU, dot-files, sbctl, boot order
   bash verify-install.sh                               # full health check (exit code = failure count)
   ```
5. In Windows: set RealTimeIsUniversal (command printed by post-install.sh).

## Editing

- Change target disk: picked interactively at boot (P3 auto-detected by model;
  any device can be typed in).
- **Packages on the installed system**: edit `packages-pacman.txt` and
  `packages-pacman-gaming.txt` — `build-iso.sh` generates the archinstall
  package list from them at build time (single source of truth). The list
  in `user_configuration.json` is only a fallback for manual archinstall.
- Change username: also edit `user_configuration.json` → `users` AND
  `post-install.sh`'s `/home/kirk` paths.

## Caveats

- archinstall's JSON `disk_layout` support is finicky between versions. If
  `--silent` install fails at partitioning, run `archinstall` interactively
  and replicate the layout (1 GB ESP + btrfs rest) — everything else is
  already unattended via the config file.
- Secure Boot can't be automated (firmware screen). post-install.sh does the
  sbctl half interactively; flipping SB on is done in BIOS.
- If the disk layout JSON ever errors, the ISO's autostart falls back to a
  plain interactive archinstall — you still get the right package set from
  the config JSON.
- The ISO is built from fresh package mirrors each time, so a stale build
  work dir is fine; a genuinely old ISO may fail signature checks — rebuild.

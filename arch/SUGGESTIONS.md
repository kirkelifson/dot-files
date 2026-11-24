# Arch Install — Suggestions

Ideas for the arch kit (`arch/`) and the installed desktop, grounded in the
current state of the kit and the machine. Nothing here is implemented yet;
each item notes where it would live.

## Security

1. **Add a firewall — the biggest gap.** post-install hardens sshd
   (pubkey-only, port 8631, AllowUsers) but nothing filters traffic: every
   LAN host can reach SSH, the hermes dashboard on 0.0.0.0:9119, and any
   future service. Add an nftables base chain in post-install: default
   drop, allow established/loopback + the LAN subnet (10.0.0.0/24).
   Related: decide whether the hermes dashboard should be LAN-wide at all —
   plain HTTP on 0.0.0.0 also disables browser secure-context features; a
   loopback bind + SSH tunnel is the safer default.

2. **Pin the runtime package-list fetch.** `arch/post-install.sh:8` pulls
   `packages/pacman-gaming.txt` from raw.githubusercontent.com/**master**
   and pipes it to pacman **as root**. Pin the URL to a full commit SHA
   (or verify a checksum fetched out-of-band) — a compromised GitHub
   account otherwise becomes root code-execution on every fresh install.

3. **Finish Secure Boot.** post-install's sbctl step is interactive and
   hasn't been run on this machine (sbctl isn't installed). Beyond enrolling
   keys: add the sbctl pacman hook so kernel/systemd-boot updates re-sign
   automatically, otherwise the next kernel update bricks the boot.

4. **AUR upgrade review pass.** The post-install paru recipe builds AUR
   packages from git master. Suggest eyeballing PKGBUILD diffs before
   re-running post-install on the installed machine, or pinning commits in
   `packages/aur.txt` for the small set it installs. (1password already
   verifies its PGP signature — good.)

5. **btrfs scrub timer.** snapper timeline is on, but scrubbing isn't:
   `systemctl enable --now btrfs-scrub@-.timer` (monthly) catches bit rot
   that snapshots would otherwise replicate faithfully.

## Development

6. **Lint parity with CI.** CI runs shellcheck over every bash script, but
   neither shellcheck nor shfmt is installed locally — you can't run what
   CI runs. Add both to `packages/pacman.txt`, plus a small fish function
   or `just` recipe that replicates the CI lint commands.

7. **`just` as the repo task runner.** The ISO build, VM-test invocations,
   and lint commands are long one-liners living in README prose.
   A `justfile` at the repo root makes them runnable and discoverable.

8. **`atuin`.** Synced, full-text-searchable shell history (Ctrl-R that
    actually works). One conflict to resolve first: `fish_postexec`
    deletes failed commands from history — decide whether atuin's history
    is filtered the same way.

9. **Container orchestration.** podman is installed but nothing
    composes: add `podman-compose` (or docker-compose against the podman
    socket). Rootless podman looks configured (subuid present) — worth a
    verify-install check that it actually works (`podman run hello-world`).

10. **Small sharp tools**: `tshark` (packet inspection when the 2.5GbE
    NIC misbehaves), `xh` (curl with JSON ergonomics), `aria2`
    (resumable/parallel downloads).

## Gaming

11. **`gamescope`.** Not installed, and sway/wlroots has no HDR —
    `gamescope --hdr-enabled` is the only HDR path (arch/README.md notes this).
    It also solves per-game fractional scaling and tearing quirks.

12. **`heroic-games-launcher` (AUR)** — GOG/Epic front-end next to Steam;
    pairs with protonup-qt (already installed) for ProtonGE management.

13. **Proton experiments**: with a 7900 XT, try `PROTON_USE_NTSYNC=1` on
    modern Proton builds (kernel supports ntsync) for throughput in
    CPU-bound titles; measure with `hyperfine`-style before/after frametime
    via the MangoHud overlay. MangoHud is installed but opt-in — consider
    `MANGOHUD=1` in a game-launch wrapper instead of globally.

## Look & feel (joy)

14. **Theme the desktop from the wallpaper.** You already generate seamless
    wallpapers — `wallust` (or pywal) can extract a palette and repaint
    waybar accents, sway `client.focused` borders, and foot colors to
    match. Hook it into `set-wallpaper` so the whole desktop shifts with
    the background.

15. **Restyle the sddm theme.** The login screen is a cloned elarun with a
    swapped background — functional but dated. A minimal custom QML
    matching the waybar palette (dark panel, no user list, clock) would
    make the login feel like the rest of the setup.

16. **pacman.conf cosmetics.** Still at defaults: add `Color` and
    `ILoveCandy` (the pacman progress bar becomes Pac-Man — free joy).
    post-install can write these idempotently.

## Install kit / image generation

17. **Mirrorlist automation.** Add `reflector` + `reflector.timer` so
    pacman always uses fast, fresh mirrors — big `pacman -Syu` runs (and
    the VM test's package-cache seeding) get noticeably faster.

18. **CI smoke-boot for the ISO.** `arch/test/` is local-only by design,
    but a *separate*, minimal public CI job could boot the built ISO
    headless in QEMU and assert the kernel reaches the archinstall
    environment — catching ISO breakage (e.g. a bad package list) before
    you flash a USB stick. Keep the full VM-test suite local; this is just
    "does it boot".

19. **ISO checksums + reproducible builds.** `build-iso.sh` should emit
    `SHA256SUMS` next to the ISO (and optionally a signed digest once
    sbctl keys exist). Setting `SOURCE_DATE_EPOCH` / normalizing mtimes
    gets close to reproducible ISOs, so two builds of the same commit are
    byte-comparable — a strong tamper check for a security-sensitive image.

## Verified non-issues

Checked and found healthy — recorded so they aren't re-investigated:

- **SSD trim**: `/` mounts with `discard=async` (btrfs default on recent
  kernels), so the disabled `fstrim.timer` is redundant, not a miss.
- **snapper + snap-pac**: timeline snapshots and pacman pre/post snapshots
  are both configured.
- **journald** is persistent (`/var/log/journal` exists).
- **GPU stack is complete**: mesa + vulkan-radeon + all lib32 companions,
  with the virtual-provider ordering handled explicitly in post-install.
- **Rootless podman**: subuid/subgid are configured.
- **Boot security posture**: sshd is pubkey-only on a nonstandard port
  with AllowUsers; credentials and SSH keys are gitignored with gitleaks
  in CI.

# Usage — tools and scripts on arch-desktop

Every script this machine's dot-files install and how it fits together:
desktop session, the waybar module helpers, audio, game streaming, tmux
tooling, shell functions, and system maintenance. Key bindings live in
[KEYBOARD.md](KEYBOARD.md) — this file lists the tools they call.

The configs own the behavior; this file only catalogues. If a script
changes, re-sync the line here. Everything under `bin/` is on PATH via
`~/bin → ~/dot-files/bin`.

## Desktop session (sway)

Wired from `arch/sway/config` → shipped as `~/.config/sway/scripts/` by
post-install.

| Script | What it does |
|---|---|
| `launcher` | Mod+d picker: apps, home files, shell commands, sway windows, calc, web search. `> cmd` runs, `= expr` calc, `web q` search; plain no-match runs as shell |
| `sway-keys` | Mod+/ searchable cheat sheet of every sway binding; can run `exec` bindings from the menu |
| `screensaver` | The idle chain's control point: `start` (aquarium), `should-lock`, `lock`, `start-force` (Mod+Shift+l). Consults `idle-gate` so fullscreen/mic-live windows suppress idle |
| `idle-gate` / `idle-resume` | Choke points for swayidle timeouts: gate skips while screensaver shouldn't fire; resume covers return-to-desk lock-on-input |
| `autotile` | dwm-style dynamic splits (wide→horizontal, tall→vertical); toggle with Mod+a; `autotile retile` = Mod+Shift+t one-shot regroup |
| `dim-inactive` | Dims non-focused windows to 85%, restores on focus |
| `shot-region` / `shot-full` | Mod+s / Mod+Shift+s screenshots (grim+slurp) → file + clipboard |
| `generate-wallpapers` | Regenerates the wallpaper tiles in `~/.config/sway/wallpapers/` |
| `set-wallpaper` | Mod+w (or `set-wallpaper <name>`); also mirrors the choice into the SDDM background |
| `update-sddm-background` | Run as root: syncs SDDM's login background to the current wallpaper |
| `toggle-nightlight` | Mod+n — single toggle for gammastep; writes the state file the waybar module reads |

## Waybar modules and their helpers

All modules live in `~/dot-files/.config/waybar/config` (JSONC); helpers
are the `exec` targets in `bin/`.

| Helper | Module | Purpose |
|---|---|---|
| `waybar-spark` | `custom/spark-*` | Rolling hover charts for CPU/temp/GPU/mem; alert classes feed `waybar-alerts` |
| `waybar-net-rate` | `custom/net-rate` | Fixed-width live throughput |
| `waybar-net-health` | `custom/net-health` | Gateway latency + packet loss quality check |
| `waybar-bluetooth` + `waybar-bluetooth-menu` | `custom/bluetooth` | Device icons; click = connect/disconnect/scan/pair menu |
| `waybar-media` + `waybar-media-menu` | `custom/media` | Now-playing (MPRIS, with the Firefox stale-bus workaround); stays visible paused; click = play/pause, right = source picker |
| `somafm` + `waybar-somafm-menu` | `custom/somafm` | SomaFM radio: click play/pause, scroll volume, right = channel picker, middle = stop |
| `waybar-calendar` | `clock` click | Month-calendar popup |
| `waybar-nightlight` | `custom/nightlight` | Blue-light filter button (shares state with `toggle-nightlight`) |
| `keepawake` | `custom/keepawake` | ☀️/🌙 idle-inhibit toggle (screensaver + lock + DPMS); resets on logout/reboot |
| `waybar-alerts` | (systemd user `waybar-alerts.service`) | Toasts when spark alert states persist |

Waybar configs are JSONC — validate by stripping `//` lines before
`json.loads`.

## Audio

| Script | What it does |
|---|---|
| `audio-dev` | Cycle or set the default sink/source through WirePlumber (persists across reboots); waybar VOL right/middle-click |
| `somafm` | SomaFM player CLI: `somafm toggle|stop|vol ±N|watch`, `somafm channel <id>` |
| `cava-spectrogram` | Scrolling heat-map spectrogram (feeds from `cava` raw output); `cspec` alias |
| `keepawake` | ☀️/🌙 idle-inhibit toggle. ⚠️ While ON the screensaver, auto-lock and DPMS-off chain are all inhibited — the machine stays unlocked indefinitely; switch it off before walking away. Resets on logout/reboot |

`~/.config/fish/local.fish` (gitignored) is the place for machine-local
audio or other overrides.

## Game streaming (Sunshine + Moonlight)

Sunshine runs as the systemd user unit `app-dev.lizardbyte.app.Sunshine`;
its `global_prep_cmd` calls one script for every client (MacBook
Moonlight included):

| Command | What it does |
|---|---|
| `sunshine-prep connect` | Wakes the DPMS-off display; snapshots the listening state (default sink + per-sink mutes) for the session |
| `sunshine-prep disconnect` | Restores that snapshot (default sink + mutes — audio comes home to the host), pauses all MPRIS players when *disconnect silence* is on, then locks the session |
| `sunshine-prep quiet on\|off\|toggle\|status` | The disconnect-silence option — sticky across reboots (marker in `~/.local/state/`). See the script header for the what-no-MPRIS caveat |

The host keeps playing locally during a stream (Sunshine only taps the
sink monitor) — the disconnect restore is what puts things back.

## tmux tooling

Prefix `C-a`; the tmux-side bindings are in
[KEYBOARD.md](KEYBOARD.md#terminal-multiplexer--tmux).

| Script | What it does |
|---|---|
| `tmux-sessionizer` (`C-a f`) | Fuzzy-pick a project dir → create/attach its session |
| `tmux-agents` (`C-a A`) | Multi-agent session: agent pane + comparison grid + git + monitor + debug windows |
| `tmux-fit-layout` | client-attached hook: fit the agents grid to laptop vs external width |
| `tmux-worktree` (`C-a W`) | Git worktree for a branch + its own agents session |
| `tmux-git-status` | Status-bar git: branch, ahead/behind, dirty, loud conflict warning |
| `tai` | Standalone project-centric agentic tmux sessions (per-harness named) |
| `tai-monitor` | Lazygit monitor pane for `tai` sessions |
| `tai-relayout` | Re-applies `tai` window proportions after resize (window-resized hook) |

## Shell (fish)

Functions in `~/.config/fish/functions/`.

| Function | What it does |
|---|---|
| `cmdgen` (`Ctrl+G`) | Replace the command line with a Hermes-generated shell command |
| `bt-scan` (+ `__bt_*` helpers) | Scan nearby Bluetooth devices: vendor, UUIDs, signal bars |
| `bt-watch` | Live signal strength for one Bluetooth device |
| `lmstudio` | Probe an LM Studio endpoint and list served models |
| `dotfiles-lint` | Run the dot-files CI lint suite locally (shellcheck/fish -n/Brewfile/actionlint/gitleaks) |
| `fish_prompt` | Custom prompt; failed commands are logged to `failed_history` by the postexec hook in config.fish |

Default fzf bindings (Ctrl+T / Ctrl+R / Alt+C) come from `fzf --fish`,
sourced in the interactive block.

## AI / model tooling

| Script | What it does |
|---|---|
| `lmstudio-sync` | Sync the shared LM Studio model set across machines over HTTP |
| `lmstudio-catalog.py` | Staff-picks + Hugging Face catalog browser, RAM-aware |

## System maintenance

| Script / unit | What it does |
|---|---|
| `check-updates` + `check-updates.service`/`.timer` | Weekly (Fri noon, persistent) user-timer update check → desktop notification (units in `arch/systemd/user/`) |
| `check-updates-notify` | The notification half (mako click target) |
| `sys-update` | Pacman update terminal (sudo password prompt inside); also the notification's click action |
| `update-server` | Purge packages marked for uninstall. ⚠️ Uninstalls packages — check `packages/` before running |
| `ssh-hosts` | List hosts from `~/.ssh/config` |
| `pacman.conf` tuning | `ParallelDownloads=10` (set by post-install) |

## Everything else in `bin/` (portable one-off utilities)

| Script | What it does |
|---|---|
| `apt-gpg KEY` | Add an apt GPG key (Debian/Ubuntu machines) |
| `bin` | Decimal → binary (`bin 16`) |
| `compressibility` | gzip/bz2-compressed size of files, dirs, or stdin |
| `git-top-contributors` | Contributors by commit count |
| `grep-rails PATTERN` | Rails-tree grep (app/config/lib/spec) |
| `hex2int` | Hex → integer |
| `oldest-line` | Find the oldest changed line in a repo |
| `osx-restart-dock/finder/menubar` | macOS UI restarts |
| `password` | Random password generator (Ruby) |
| `plan` / `weekly-plan` | Open today's / this week's `~/plan/MM-DD-YY.plan` note |
| `sentry-user-ids` | Flatten a CSV id column to a comma-joined list |
| `load-ocaml` | macOS opam init helper |

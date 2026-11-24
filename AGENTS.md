# AGENTS.md

Guidance for coding agents working in this repo.

## What this is

Personal dotfiles — fish, vim/nvim, tmux, git, plus per-OS package lists and
an unattended Arch install kit (`arch/`). `./install` links everything into
the home directory; it is idempotent and safe to re-run at any time.

## Repo layout

- `install` — organized as linear stage functions (`install_system_packages`,
  `link_dotfiles`, `setup_fish_shell`, …) called in order at the bottom of the
  file; skim that final block to see the whole flow. Heavy steps (bulk
  packages, runtime compilation, `chsh`) are skipped when `$CI` is set, or
  forced locally with `DOTFILES_CI=1 ./install` (e.g. a fast relink).
- `.config/` — fish, nvim, ghostty, waybar, fastfetch, mise, mako, gtk-3.0,
  gtk-4.0. `install`
  links fish/waybar/fastfetch, nvim, ghostty and the mise fragment (Omarchy
  exceptions below); ghostty on macOS links into
  `~/Library/Application Support/com.mitchellh.ghostty/`. mako (Wayland
  notification daemon) links on Linux only, not on Omarchy.
- `packages/` — `apt.txt`, `pacman.txt`, `pacman-gaming.txt`, `aur.txt`,
  `freebsd.txt`; `Brewfile` at the repo root for macOS. Keep apt references on
  resolute (Ubuntu 26.04), never noble.
- `bin/` — utility scripts, linked to `~/bin`. Per-project search dirs for
  `tmux-sessionizer` are edited in that script.
- `test_install.py` — unit tests for `install`; run it after installer edits.
- `arch/` — unattended Arch install kit; see `arch/README.md` and
  `arch/test/README.md`.

## Conventions

- **Fish**: environment variables and PATH go in the top of
  `.config/fish/config.fish` (it runs for EVERY shell instance, including
  non-interactive); aliases, abbreviations, and integrations go inside the
  `if status is-interactive` block. `fish_add_path` dedupes. Machine-local
  settings belong in `~/.config/fish/local.fish` (gitignored, sourced if
  present).
- **Guard optional binaries** (`if type -q eza; alias ls='…'; end`) so machines
  without a tool degrade to stock behavior instead of breaking the alias.
- **Validate before claiming done**: `fish -n` on fish files, `bash -n` on
  shell scripts, `vim -Nu ~/.vimrc -es -c quit` for vimrc, `sway --validate`
  for sway configs, `ruby -c Brewfile` (it is a Ruby DSL).
- The config files are their own documentation — read the file instead of
  assuming a binding, alias, or setting exists (or doesn't).

## CI (`.github/workflows/`)

- `lint.yml` — shellcheck (scripts found by shebang), `fish -n` over
  `.config/fish/`, `ruby -c` on the Brewfile, actionlint, gitleaks.
- `test-install.yml` — runs `./install` for real (root in an `ubuntu:26.04`
  container so `chsh` skips PAM; also macOS), asserts symlinks resolve into
  the repo, re-runs it to prove idempotency, and loads the configs headless.
- `packages.yml` — every package name still resolves in its repos (push +
  weekly; upstream removals aren't triggered by commits here).
- `arch-kit.yml` — superficial checks only. `arch/test/` is local-only and
  must never run in CI (its scripts self-guard).

## Omarchy exceptions (Arch + Hyprland)

`install` detects Omarchy and avoids clobbering files its tooling rewrites:
- nvim and ghostty configs are NOT linked (Omarchy owns them; its theme/font
  commands edit them in place).
- `~/.config/tmux/tmux.conf` is written as a one-line REGULAR file (not a
  symlink — Omarchy's `refresh` would `cp -f` write through it) pointing at
  the linked `~/.tmux.conf`.
- mise config is linked into `~/.config/mise/conf.d/dot-files.toml` instead of
  replacing the directory; `mise use -g` may update the linked fragment —
  that's intentional, review before committing.
- Both `~/.gitconfig` and Omarchy's `~/.config/git/config` are read; this
  repo's `pull.ff = only` + Omarchy's `pull.rebase` means a diverged
  `git pull` aborts instead of rebasing.

## Arch kit rules (`arch/`)

- Rebuild the ISO only when `arch/iso/**` or `arch/archinstall/**` change;
  everything else (post-install.sh, dot-files, package lists) flows from
  GitHub when post-install runs on the target.
- The installed system's target user is `xtc`; the Samsung 980 Pro holds
  Windows and must never be an install target.
- Machine-specific creds (`arch/archinstall/user_credentials.json`,
  `arch/test/keys/`) are gitignored — never commit them. SSH pubkeys in
  `arch/ssh/` are fine.

## Machine-specific settings

Anything host-specific that shouldn't be committed goes in
`~/.config/fish/local.fish` (fish) or is edited directly on the host
(e.g. `search_dirs` in `bin/tmux-sessionizer`).

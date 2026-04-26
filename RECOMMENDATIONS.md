# Recommendations

Improvements identified during dotfiles review. Checked off as completed.

## SSH / Remote Machines

- [ ] **SSH config management** — Add a base `~/.ssh/config` template to the repo with common settings: keepalive intervals, connection multiplexing (`ControlMaster`), agent forwarding defaults. The install script could link or merge it.

## Fish Shell

- [ ] **`ls` aliases should use `eza`** — `eza` is installed but fish config still has platform-diverging `ls -Goh` / `ls -ltrGh` aliases. Replace with a single `eza -l --git --time-style=relative` alias (works the same on macOS, Linux, and Arch). Eliminates the Darwin/Linux branch entirely.

- [ ] **`search` alias should use `rg`** — The `search` alias calls `grep -R -C3 -n`, but `ripgrep` is already installed. `rg` is faster, respects `.gitignore`, and handles binary files. A drop-in alias: `alias search='rg -C3'`.

- [ ] **`dog` alias is now redundant** — `dog="pygmentize -g"` predates `bat`. Since `bat` is installed and handles more formats with better UX, replace with `alias dog='bat'` or just drop it and use `bat` directly.

- [ ] **`bat` as man pager** — Set `MANPAGER` so man pages render with syntax highlighting: `set -gx MANPAGER "sh -c 'col -bx | bat -l man -p'"`. Goes in the non-interactive section of config.fish.

- [ ] **`bat` preview in fzf** — Add `set -gx FZF_DEFAULT_OPTS '--preview "bat --color=always --line-range :200 {}"'` to config.fish. Makes Ctrl-T file picker show highlighted previews.

- [ ] **`fish_postexec.fish` is untracked** — The function (which deletes failed commands from history and restores them to the prompt) is sitting outside the repo. Either commit it or add it to `.gitignore` if intentionally machine-local.

## Vim

- [ ] **`re=1` forces old regex engine** — `.vimrc:14` sets `set re=1` (NFA engine). This was a workaround for Ruby syntax slowness circa 2014 but causes hangs with complex patterns in newer Vim. Remove it or set `re=0` (auto-select).

## Tmux

- [ ] **Wayland clipboard** — `.tmux.conf` detects Darwin vs. Linux and uses `xclip` on Linux. On modern Wayland sessions (common on Arch, newer Ubuntu) `xclip` doesn't reach the compositor. Add a nested check: if `$WAYLAND_DISPLAY` is set, use `wl-copy` (from `wl-clipboard`) instead of `xclip`.

## Install Script

- [ ] **Arch Linux / pacman support** — The install script handles Darwin (brew) and Debian/Ubuntu (apt-get) but falls through silently on Arch. Since you have a local Arch machine, add a `pacman` branch. An `else` that checks `command -v pacman` and installs from a `packages-pacman.txt` (or just core tools inline) would make the script usable there.

- [ ] **FreeBSD / pkg support** — You SSH into FreeBSD servers. The install script has no `pkg` path. At minimum, detect `command -v pkg` and print a list of equivalents rather than silently skipping.

- [ ] **`packages-apt.txt` has packages not in default repos** — `eza`, `curlie`, and `bandwhich` are not available in default Debian/Ubuntu apt repos (they're Rust-ecosystem tools distributed via GitHub releases or cargo). The install script will silently fail on them on a fresh server. Either remove them from the apt list and add a cargo-install fallback, or add a note/link to their install instructions.

## Brewfile / Package Gaps

- [ ] **`git-absorb` missing from Brewfile** — Checked off in a previous review but not present in the Brewfile. Add `brew "git-absorb"`.

- [ ] **`hyperfine` missing from Brewfile** — Same situation. Add `brew "hyperfine"`.

- [ ] **`age` missing from Brewfile** — Marked done in a previous review but not in the Brewfile. Add `brew "age"`.

## Git

- [ ] **`gitconfig` lacks `includeIf` for machine-specific identity** — `.gitconfig` has your personal email hardcoded. On work machines or shared servers this is awkward. Add an `[includeIf "gitdir:~/work/"]` block pointing to a `~/.gitconfig-work` (not committed) with a different `user.email`. The install script could template it.

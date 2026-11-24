# Suggestions

Open improvements for the dot-files repo. Items are removed once verified
done on the machine.

## SSH / Remote Machines

- [ ] **SSH config management** — Add a base `~/.ssh/config` template to the repo with common settings: keepalive intervals, connection multiplexing (`ControlMaster`), agent forwarding defaults. The install script could link or merge it.

## Fish Shell

- [ ] **`ls` aliases should use `eza`** — `eza` is installed but fish config still has platform-diverging `ls -Goh` / `ls -ltrGh` aliases. Replace with a single `eza -l --git --time-style=relative` alias (works the same on macOS, Linux, and Arch). Eliminates the Darwin/Linux branch entirely.

- [ ] **`search` alias should use `rg`** — The `search` alias calls `grep --color=auto -R -C3 -n`, but `ripgrep` is already installed. `rg` is faster, respects `.gitignore`, and handles binary files. A drop-in alias: `alias search='rg -C3'`.

- [ ] **`dog` alias is now redundant** — `dog="pygmentize -g"` predates `bat`. Since `bat` is installed and handles more formats with better UX, replace with `alias dog='bat'` or just drop it and use `bat` directly.

- [ ] **`bat` as man pager** — Set `MANPAGER` so man pages render with syntax highlighting: `set -gx MANPAGER "sh -c 'col -bx | bat -l man -p'"`. Goes in the non-interactive section of config.fish.

- [ ] **`bat` preview in fzf** — Add `set -gx FZF_DEFAULT_OPTS '--preview "bat --color=always --line-range :200 {}"'` to config.fish. Makes Ctrl-T file picker show highlighted previews.

## Vim

- [ ] **`re=1` forces the old regex engine** — `.vimrc:13` sets `set re=1` (backtracking engine). This was a workaround for Ruby syntax slowness circa 2014 but causes hangs with complex patterns in newer Vim. Remove it or set `re=0` (auto-select).

## Install Script

- [ ] **`packages/apt.txt` on Ubuntu 24.04** — `eza` is in the apt list but is not in noble's default repos (it landed in later Ubuntu/Debian releases). Confirm the `packages.yml` CI job still passes; if not, drop `eza` from apt.txt or add a fallback install note. (`curlie` and `bandwhich` were already removed from the list.)

- [ ] **apt branch fails silently mid-list** — The apt path pipes the whole list into one `xargs sudo apt-get install -y`, so one bad name aborts the rest with no report. Give it the FreeBSD treatment: check each package with `apt-cache show` first, install the resolvable ones, and report the missing by name.

## Brewfile / Package Gaps

- [ ] **`git-absorb`, `hyperfine`, `age` missing from Brewfile** — All three were marked done in earlier reviews but are not in the Brewfile. Add `brew "git-absorb"`, `brew "hyperfine"`, `brew "age"`.

- [ ] **`lazygit` + `git-delta` on all platforms** — Neither is in the Brewfile nor `packages/pacman.txt`. Add both; consider making `git-delta` the `core.pager` for side-by-side diffs.

## Git

- [ ] **`gitconfig` lacks `includeIf` for machine-specific identity** — `.gitconfig` has your personal email hardcoded. On work machines or shared servers this is awkward. Add an `[includeIf "gitdir:~/work/"]` block pointing to a `~/.gitconfig-work` (not committed) with a different `user.email`. The install script could template it.

## Neovim

- [ ] **Give nvim a real config — it's currently stock** — `packages/pacman.txt` installs neovim but there is no `~/.config/nvim`, and `EDITOR=vim` means it never gets used. Two levels, pick one:
  - **Bridge (10 min):** a minimal `~/.config/nvim/init.lua` that applies the same settings as `.vimrc` (2-space indent, search settings, leader `,`, `;`→`:`, splits, cursor restore) plus `vim.loader` — nvim instantly behaves like your vim.
  - **Full (an evening):** a small `lazy.nvim` setup — treesitter, native LSP (nvim-lspconfig + Mason for ruby-lsp/pyright/gopls...), telescope, nvim-cmp, conform.nvim — keeping leader `,` so muscle memory holds. Keep `.vimrc` for quick `vim` edits; both stay maintained.
- [ ] **Split EDITOR policy** — `EDITOR=vim` globally but `BUNDLER_EDITOR=code`; consider `EDITOR=nvim` once the config exists (git, fish, tmux all follow `$EDITOR`).

## CI / Repo Hygiene

- [ ] **Pin GitHub Actions to commit SHAs** — Workflows reference actions by tag (`actions/checkout@v5`). Tags are mutable; pin to full SHAs (Dependabot can keep them updated) so a compromised action repo can't run code in CI with your secrets.

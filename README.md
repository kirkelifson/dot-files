## dot-files

Personal dotfiles for Fish shell + Ghostty terminal, managed via symlinks. Supports macOS, Debian/Ubuntu, Arch/Omarchy, and a smaller FreeBSD setup.

### Quick Start

```bash
git clone https://github.com/kirkelifson/dot-files.git
cd dot-files
./install
```

The install script is idempotent — safe to run multiple times. It will:

- Install system packages using Homebrew, apt, pacman, or FreeBSD pkg
- Symlink dotfiles and configs to your home directory
- Install GohuFont Nerd Font (required for Ghostty config)
- Install and set Fish as default shell
- Install language runtimes via mise (Ruby, Node, Python, Go, Elixir, Rust; automatic runtime installation is skipped on FreeBSD)
- Install vim packages

`DOTFILES_CI=1 ./install` skips the slow, network-heavy steps (system package installation, `mise install`) — useful for a quick local relink. CI runs skip them automatically, since `install` also honors the standard `$CI` variable.

### What's Included

| File/Dir | Purpose |
|---|---|
| `.config/fish/` | Fish shell config, prompt, abbreviations, aliases |
| `.config/fish/functions/fish_prompt.fish` | Prompt: hostname, last 2 dirs, git branch + status |
| `.config/fish/functions/fish_postexec.fish` | Post-exec hook: restores failed commands |
| `.config/ghostty/` | Ghostty terminal config (theme, font, OSC 52, keybindings) |
| `.tmux.conf` | tmux config (C-a prefix, vi copy mode, sessionizer) |
| `.vimrc` | Vim config (Sierra theme, lightline, gitgutter) |
| `.gitconfig` | Git aliases and settings |
| `bin/` | Utility scripts (tmux-sessionizer, password, etc.) |
| `Brewfile` | Homebrew packages (macOS) |
| `packages-apt.txt` | apt packages (Debian/Ubuntu) |
| `packages-pacman.txt` | pacman packages (Arch/Omarchy) |
| `packages-freebsd.txt` | Smaller FreeBSD pkg set |
| `.config/mise/config.toml` | mise language versions |

### FreeBSD

On a fresh FreeBSD machine, first run `pkg install bash sudo git curl` as root.
Give your normal account sudo access, clone this repo as that account, then run
`bash ./install`. Avoid running the whole installer as root unless you want root's
home configured. `/usr/local/bin` and `/usr/local/sbin` are added to PATH.

The smaller `packages-freebsd.txt` set keeps Fish, Vim, Git, tmux, sessionizer,
search tools, clipboard helpers, fonts, and mise. The installer queries the active
pkg repository, reports unavailable packages by name, and skips them. Missing
core commands (fish, git, vim, tmux, fzf, fd, mise, curl) stop installation. Package availability
varies by FreeBSD release, architecture, and quarterly/latest repository.

| Area | FreeBSD support in this repo |
|---|---|
| mise | Installed via the [FreeBSD port](https://cgit.freebsd.org/ports/tree/sysutils/mise/); activated in Fish. Automatic installation of the shared Ruby/Node/Python/Go/Elixir/Rust/usage pins is skipped. Install and validate each project's tools with `mise use tool@version`; backend/binary support varies. |
| Development extras | GHC, cabal, Haskell LSP, Lua, uv, gopls, golangci-lint, delve, pnpm, CMake, Ninja, and GDB are omitted from this smaller package set. This does not mean they are unavailable in FreeBSD Ports; add them per project. |
| Databases and media | PostgreSQL, Valkey/Redis, libvips, ImageMagick, Graphviz, FFmpeg, and additional runtime build libraries are omitted; install per project. |
| Containers and desktop | Podman and the Omarchy/Hyprland desktop setup are outside this FreeBSD bootstrap. Homebrew casks and VS Code extensions are macOS-only installer features. Ghostty is not installed; its shared config is linked for an independently installed terminal. |
| Clipboard | `wl-clipboard` for a local Wayland session, `xclip` for X11. Over SSH these need access to a display; the package set does not configure clipboard forwarding. |
| Agent layout | `tmux-agents` requires separately installed AI CLIs and GNU `watch`; FreeBSD base `watch` is a different utility. Use `tmux-sessionizer` for the supported core session workflow. |
| Platform utilities | `apt-gpg` and `update-server` remain Debian/Ubuntu-only; `osx-restart-*` remain macOS-only. |

### Machine-Specific Config

**Fish:** Create `~/.config/fish/local.fish` for settings that shouldn't be committed (API keys, work-specific aliases, etc.). It's gitignored and sourced automatically by `config.fish` if it exists.

**Secret environment variables:** Create `~/.fish_secrets` with `set -gx` entries for API keys, tokens, etc. Sourced on every shell start (including non-interactive).

### tmux Sessionizer

Fuzzy-find project directories and create/switch tmux sessions:

```bash
tmux-sessionizer          # or prefix+f inside tmux
```

Edit `search_dirs` in `bin/tmux-sessionizer` to configure which directories to search. The defaults (`~/code`, `~/projects`, `~/work`, `~/src`, `~/dot-files`) are skipped silently if they don't exist — add your actual project dirs.

---

### Known Traps & Gotchas

**`cp` and `mv` are aliased** to verbose/recursive variants (`cp -Rv`, `mv -v`). If you expect silent copies or moves, you'll get output. These aliases only apply to interactive shells.

**`pull.ff = only` in `.gitconfig`** means `git pull` will refuse to create a merge commit if the branch has diverged. You'll get an error and need to rebase manually.

**`fish_postexec` removes failed commands from history** and restores them to the command line so you can fix and re-run. This means typos and broken commands won't pollute your history, but it can feel surprising the first time a failed command "comes back."

**`node = "lts"` or `"latest"` in `.config/mise/config.toml`** resolves dynamically at install time. If you reinstall later, you may get a different version than what's currently active. Pin to a specific version (like the other tools already are) if reproducibility matters.

**mise can detect idiomatic version files** (`.nvmrc`, `.ruby-version`, `Gemfile`, `go.mod`, etc.) inside a project directory and prefers them over `~/.config/mise/config.toml`. Enable the relevant tools with `mise settings set idiomatic_version_file_enable_tools ruby,node,python,go`, or use an explicit project `mise.toml`.

**mise manages runtime selection.** Repo defaults are linked at
`~/.config/mise/conf.d/dot-files.toml`, preserving an existing `config.toml` such
as Omarchy's. `mise use` writes project settings; `mise use -g` may edit the
linked repo fragment when it declares that tool. These repo changes are allowed;
review them before committing. No rbenv, RVM, or asdf initialization is used. The legacy virtualenvwrapper
loader has been removed; use project virtual environments with mise/uv instead.

**Backups are retained.** Replaced configs use the usual backup name, then `.1`,
`.2`, and so on when that name already exists. Omarchy tmux backups follow the
same rule (`tmux.conf.omarchy-default`, `.omarchy-default.1`, ...).

**GohuFont Nerd Font is required** for the Ghostty config. The install script downloads it automatically, but if you configure Ghostty before running `./install`, it will fall back through the font stack (`SF Mono` → `DejaVu Sans Mono` → `monospace`). Nerd Font glyphs (used by some prompts/tools) won't render without it.

**Ghostty config location differs by platform:**
- macOS: `~/Library/Application Support/com.mitchellh.ghostty/config` (symlinked by install)
- Linux: `~/.config/ghostty/config` (symlinked by install, except on Omarchy, where Omarchy's own themed config is left in place)

The repo stores the config at `.config/ghostty/config` — don't edit the symlink target directly on macOS.

**`ulimit -n 4096`** is raised in interactive shells to avoid "too many open files" errors in Rails/dev. It does not affect non-interactive shells or scripts.

**mise is skipped when devenv is active.** If `$DEVENV_PROFILE` or `$DEVENV_ROOT` is set, `mise activate` is not loaded. This prevents conflicts when using Nix/devenv for per-project tooling.

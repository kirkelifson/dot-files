## dot-files

Personal dotfiles for Fish shell + Ghostty terminal, managed via symlinks. Cross-platform (macOS + Linux).

### Quick Start

```bash
git clone https://github.com/kirkelifson/dot-files.git
cd dot-files
./install
```

The install script is idempotent — safe to run multiple times. It will:

- Install system packages (Brewfile on macOS, packages-apt.txt on Linux)
- Symlink dotfiles and configs to your home directory
- Install GohuFont Nerd Font (required for Ghostty config)
- Install and set Fish as default shell
- Install language runtimes via asdf (Ruby, Node, Python, Go, Elixir, Rust)
- Install vim packages

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
| `packages-apt.txt` | apt packages (Linux) |
| `.tool-versions` | asdf language versions |

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

**`nodejs lts` in `.tool-versions`** is a special token that resolves to the current LTS version at install time. If you reinstall later, you may get a different Node version than what's currently active. Pin to a specific version if reproducibility matters.

**GohuFont Nerd Font is required** for the Ghostty config. The install script downloads it automatically, but if you configure Ghostty before running `./install`, it will fall back through the font stack (`SF Mono` → `DejaVu Sans Mono` → `monospace`). Nerd Font glyphs (used by some prompts/tools) won't render without it.

**Ghostty config location differs by platform:**
- macOS: `~/Library/Application Support/com.mitchellh.ghostty/config` (symlinked by install)
- Linux: `~/.config/ghostty/config` (symlinked by install)

The repo stores the config at `.config/ghostty/config` — don't edit the symlink target directly on macOS.

**`ulimit -n 4096`** is raised in interactive shells to avoid "too many open files" errors in Rails/dev. It does not affect non-interactive shells or scripts.

**asdf shims are skipped when devenv is active.** If `$DEVENV_PROFILE` or `$DEVENV_ROOT` is set, asdf is not loaded. This prevents conflicts when using Nix/devenv for per-project tooling.

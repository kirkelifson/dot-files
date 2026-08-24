# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Repository Overview

This is a personal dotfiles repository for managing shell configuration, vim settings, tmux configuration, git aliases, and custom utility scripts across machines.

**Current setup**: Fish shell + Ghostty terminal (with legacy zsh config still present for reference)

## Installation

The install script is idempotent and can be run repeatedly to update configurations and packages.

```bash
git clone https://github.com/kirkelifson/dot-files.git
cd dot-files
./install
```

The install script:
- **Safety check**: Warns if the repo has uncommitted changes before proceeding
- Installs system packages (Brewfile on macOS, packages-apt.txt on Linux)
- Creates soft-links to all dotfiles (`.vimrc`, `.tmux.conf`, `.gitconfig`, etc.) in the home directory
- Links the `bin/` directory to `~/bin` for custom utilities
- Links `.config/fish/` and `.config/ghostty/` configurations
- Installs/updates vim packages in `~/.vim/pack/bundle/start/`
- Creates a symlink to Sublime Text's `subl` command if the app is installed (macOS only)
- **Installs and configures fish shell**:
  - Installs fish if not present (via brew or apt)
  - Adds fish to `/etc/shells` if not already present (requires sudo)
  - Changes default shell to fish if not already set
- **Installs language runtimes via mise** from `.config/mise/config.toml` (Ruby, Node, Python, Go, Elixir, Rust)

**Idempotent behavior**: The script can be run multiple times safely:
- Symlinks are recreated with `-f` flag (overwrite existing)
- Vim packages are updated via `git pull` if already present
- Fish shell setup is skipped if fish is already the default shell
- System packages only install what's missing
- mise versions are skipped if already installed
- All checks prevent duplicate installations

## Key Configuration Files

### Shell Configuration (.config/fish/)

**Primary shell**: Fish shell is configured in `.config/fish/config.fish`

The fish configuration is split into two sections:

**Always loaded** (top of file — runs for all shells including non-interactive like `fish -c "..."`):
- Environment variables (EDITOR, VISUAL, BUNDLER_EDITOR, PS_FORMAT, locales)
- PATH management via `fish_add_path` (which auto-deduplicates)
- mise activation (when devenv is not active)

**Interactive only** (inside `if status is-interactive` block):
- Abbreviations for git (`gst`, `gd`, `gco`, `gpu`, `gpl`, `ga`, `gci`, etc.) and Rails (`rc`, `rs`, `rr`, `rdb`, `bi`)
- Aliases (platform-specific for Darwin vs Linux)
- Tool integrations: fzf (`fzf --fish`), direnv, zoxide
- `fetch-all`, `pull-all`: batch git operations using `find` across repos in current directory
- Conditional loading of `~/.config/fish/local.fish` (for machine-specific settings)

**Where to add new config**: Environment variables and PATH entries go in the top section. Aliases, abbreviations, keybindings, and shell integrations go inside the `if status is-interactive` block. Fish's `config.fish` runs for ALL shell instances (unlike bash/zsh), so the interactive guard prevents unnecessary work in non-interactive contexts.

**Prompt** (`.config/fish/functions/fish_prompt.fish`):
- Shows hostname in cyan
- Shows last 2 directories in gray
- Shows git branch with status indicators:
  - `*`: unstaged changes
  - `+`: staged changes
- Branch name displayed in yellow

**Important**:
- `fish_add_path` automatically deduplicates, so no tmux guards are needed for PATH
- All PATH entries are set unconditionally — tmux panes get their own fresh fish shell and need correct PATH

### Terminal Configuration (.config/ghostty/)

Ghostty is configured with:
- Custom dark color palette complementing the `1c1c1c` background
- SF Mono font at size 14
- Background opacity (0.833) with blur
- OSC 52 clipboard passthrough (allows tmux/vim to copy to system clipboard, even over SSH)
- Dark native title bar (`window-theme = ghostty`)
- Mouse hiding while typing, copy-on-select
- Option-as-Alt for meta key support

### Legacy Shell Configuration (.zshrc, .zshenv)

Legacy zsh configuration is still present for reference but not actively used. It follows similar patterns to the fish config with TMUX detection and environment variable management.

### Git Configuration (.gitconfig)

Notable git aliases:
- `cane`: commit --amend --no-edit (quick amend without changing message)
- `lg`: pretty graph log with colors
- `recent`: shows branches sorted by most recent commit
- `nuke`: deletes both local and remote branch
- `set-upstream`: sets upstream to origin/current-branch

Configuration highlights:
- Default branch: `master`
- Auto-prune on fetch enabled
- Rerere (reuse recorded resolution) enabled
- Histogram diff algorithm
- Verbose commits by default

### Vim Configuration (.vimrc)

Vim is configured with:
- Leader key: `,`
- Installed packages (in `~/.vim/pack/bundle/start/`):
  - Sierra (color scheme)
  - lightline.vim (status line)
  - supertab (completion)
  - vim-gitgutter (git diff in gutter)
- Undo/backup files stored in `~/.vim/tmp` and `~/.vim/undo`
- Language-specific indentation: 2 spaces (default), 4 spaces (Python, Java, C, C++)
- Splits open below and to the right (splitbelow, splitright)
- Custom keybindings:
  - `;` remapped to `:`
  - `<C-p>`: fuzzy file search (CtrlP)
  - `<leader>ev`: edit vimrc in vertical split
  - `<leader><space>`: clear search highlights
  - `<C-h/j/k/l>`: navigate between splits

### Tmux Configuration (.tmux.conf)

- Prefix key: `C-a` (instead of default `C-b`)
- Mouse support enabled
- Window/pane numbering starts at 1
- Splits preserve current directory: `|` (horizontal), `_` (vertical)
- Pane navigation: `h/j/k/l` (vim-style)
- Pane resizing: `H/J/K/L` (repeatable)
- Vi copy mode with platform-aware clipboard yank (`pbcopy`/`xclip`)
- True color support (tmux-256color with Ghostty RGB)
- Focus events enabled (for vim autoread)
- Sessionizer: `prefix + f` to fuzzy-find and switch projects
- Status bar: session name + user@host (left), time/date (right), cyan accent color
- Default shell/command: `$SHELL` (works with whatever shell is configured)

### Package Management

**macOS (Brewfile)**: Curated Homebrew packages organized by category — core CLI tools, shell/terminal, git, editors, Ruby/Rails deps, languages, infrastructure, networking, media, AI tools, casks, and VS Code extensions. Install with `brew bundle`.

**Linux (packages-apt.txt)**: Essential Debian/Ubuntu packages including build dependencies needed for mise to compile languages. Install with `xargs -a packages-apt.txt sudo apt-get install -y`.

**Language versions (.config/mise/config.toml)**: Global mise defaults for Ruby, Node, Python, Go, Elixir, and Rust. The install script installs mise (if missing) and runs `mise install` to install these versions. mise also auto-detects idiomatic per-project version files (`.nvmrc`, `.ruby-version`, `go.mod`, etc.), which take precedence over the global config.

## Custom Utilities (bin/)

The `bin/` directory contains various utility scripts:
- `tmux-sessionizer`: Fuzzy-find project directories and create/attach tmux sessions
- `password`: Generate secure passwords
- `oldest-line`: Find oldest line in a file
- `git-top-contributors`: Show top contributors to a git repository
- `grep-rails`: Grep through Rails code
- `load-virtualenv`, `load-ocaml`: Environment loaders
- `osx-restart-*`: Scripts to restart macOS system components (Dock, Finder, menubar)
- `plan`, `weekly-plan`: Planning utilities
- `ssh-hosts`: List SSH hosts from known_hosts

## Platform-Specific Behavior

The configuration detects the OS via `uname -s` and adjusts:

**Darwin (macOS)**:
- Custom `ps` alias with specific format
- `brew-*` aliases for Homebrew service management
- `md5sum` aliased to `md5 -q`
- Different `ls` flags

**Linux**:
- `sudo` prepended to `apt`, `aptitude`, `ifconfig`
- `open` aliased to `xdg-open`

## Development Workflow

Common abbreviations and aliases for development:
- `gst`, `gd`, `gco`, `gpu`, `gpl`, `ga`, `gci`: git shortcuts (abbreviations, expand inline)
- `be`: bundle exec (Ruby/Rails)
- `rc`, `rs`, `rr`, `rdb`: Rails console/server/routes/db (abbreviations)
- `dev`: bin/dev (Rails 7+ foreman launcher)
- `goodcop`: rubocop with parallel execution and simple format
- `coverage-web`: serves Ruby coverage reports on port 3005
- `fetch-all`, `pull-all`: batch git operations on repos in current directory
- `ts` / `tmux-sessionizer`: fuzzy-find projects and create/switch tmux sessions

## Testing and Building

There's no application build, but CI (`.github/workflows/`) verifies the shell scripts, fish config, and the installer itself:

- `lint.yml` — shellcheck on all bash scripts (discovered by shebang, not a hardcoded list), `fish -n` syntax-checks every `.config/fish/**/*.fish`, `ruby -c` on the Brewfile (it's a Ruby DSL), actionlint on the workflows, gitleaks over the repo.
- `test-install.yml` — runs `./install` for real on Linux (root inside an `ubuntu:24.04` container, so `chsh` doesn't hit a PAM password prompt) and macOS (`macos-latest`), asserts the resulting symlinks resolve into the repo, re-runs `install` to confirm idempotency (no `*-backup` files on the second pass), and sanity-checks `.vimrc`/`.tmux.conf`/`.gitconfig`/fish by actually loading them headless. `install` auto-detects CI via the standard `$CI` variable (which GitHub Actions sets), so the run stays fast and doesn't touch the Brewfile/apt-get bulk installs or compile language runtimes — no extra env vars needed in the workflow.
- `packages.yml` — confirms every name in `Brewfile`/`packages-apt.txt` still resolves (`brew info`, `apt-cache show`) without installing anything; runs on push and weekly, since upstream removals (e.g. a formula dropped from homebrew-core) aren't triggered by a commit here.

`install` is organized as a linear sequence of named stage functions (`install_system_packages`, `link_dotfiles`, `setup_fish_shell`, etc.) called in order at the bottom of the file — skim that final block to see the whole flow. `DOTFILES_CI=1 ./install` forces the same CI-skip behavior locally (e.g. for a fast relink).

## Machine-Specific Configuration

For machine-specific settings that shouldn't be committed:
- **Fish**: Create `~/.config/fish/local.fish` - gitignored and sourced by config.fish if it exists
- **Zsh** (legacy): Create `~/.zshlocal` - sourced by .zshrc if it exists
- **tmux-sessionizer**: Edit `search_dirs` in `bin/tmux-sessionizer` to add your project directories

## PATH Management

PATH is managed to avoid duplicates:
- `fish_add_path` automatically deduplicates when adding paths — no tmux guards needed
- All PATH entries are set unconditionally in the top (non-interactive) section of `config.fish`
- **mise** is only activated when devenv is NOT active (checked via `$DEVENV_PROFILE` or `$DEVENV_ROOT` variables)
  - When devenv is active, it manages tool versions and mise should not interfere

# Keyboard shortcuts — arch-desktop

A cheat sheet of every keyboard shortcut configured on this machine
(arch-desktop, sway). Saved for reference when re-learning the setup on a new
box or building a YubiKey-style cheat sheet for another host.

Derived from the configs that own these bindings, in this order of authority:
- Desktop: `arch/sway/config` (installed to `~/.config/sway/config`)
- Terminal multiplexer: `.tmux.conf`
- Shell: `.config/fish/config.fish`
- Editor: `.config/nvim/init.lua` (this file is the live config; `.vimrc`
  mirrors the core on other machines)
- fzf: defaults from `fzf --fish`, sourced in the fish interactive block

A searchable in-session copy of the sway half lives at `$mod+slash`
(`bin/sway-keys`). If you edit the configs, re-sync this file — nothing in CI
checks it.

Mod key throughout: `$mod = Mod4` (Super / Windows key).

## Desktop — sway

`$mod` = Super. All from `arch/sway/config`.

### Apps & launcher

| Keys | Action |
|---|---|
| `$mod+Return` | foot terminal (from foot server: instant) |
| `$mod+i` | Firefox (`$mod+b` is taken by i3-standard `splith`) |
| `$mod+d` | launcher — fzf app/file/command picker (floating foot) |
| `$mod+p` | clipboard picker (cliphist → wofi → paste) |
| `$mod+slash` | searchable keybinding cheat sheet (`bin/sway-keys`) |
| `$mod+Shift+r` | reload sway config in place |

### Workspaces (dwm tags → 1..9)

| Keys | Action |
|---|---|
| `$mod+1..9` | switch to workspace N |
| `$mod+Shift+1..9` | move focused window to workspace N |

Workspace 9 hosts Steam Big Picture (games); `$mod+1..8` always shows the
desktop back.

### Focus & movement (vim muscle memory)

| Keys | Action |
|---|---|
| `$mod+j` / `$mod+k` | focus down / up |
| `$mod+Left` / `$mod+Right` | focus left / right |
| `$mod+Shift+j` / `$mod+Shift+k` | move window down / up |
| `$mod+Shift+Left` / `$mod+Shift+Right` | move window left / right |
| `$mod+Tab` | toggle focus tiling ↔ floating layer |

### Layout & resize

| Keys | Action |
|---|---|
| `$mod+b` / `$mod+v` | split horizontally (right) / vertically (below) |
| `$mod+h` / `$mod+l` | quick-nudge resize: shrink / grow width 40 px |
| `$mod+e` | toggle split ↔ tabbed layout |
| `$mod+a` | toggle autotile (dwm-style dynamic splits) on/off |
| `$mod+t` | workspace layout: tabbed |
| `$mod+u` | workspace layout: stacking (`$mod+s` is screenshot) |
| `$mod+g` | workspace layout: back to plain tiling (splith) |
| `$mod+Shift+t` | retile now: terminals in a vertical stack, apps beside |
| `$mod+r` | enter resize mode (dimensions shown in waybar) |

Resize mode (`$mod+r`, exits with Return / Escape / `$mod+r`):

| Keys | Action |
|---|---|
| `h` / `l` | shrink / grow width 20 px |
| `j` / `k` | grow / shrink height 20 px |
| arrows | same, arrow keys |

### Scratchpad

| Keys | Action |
|---|---|
| `$mod+Shift+minus` | hide focused window to scratchpad |
| `$mod+minus` | show / cycle scratchpad windows |

### Windows & session

| Keys | Action |
|---|---|
| `$mod+space` | toggle floating |
| `$mod+f` | fullscreen toggle |
| `$mod+q` (or `$mod+Shift+c`) | close window |
| `$mod+Shift+q` | swaynag confirmation → exit sway |
| `$mod+Shift+l` | lock now (fish replaces lock view; real lock on first input) |
| Mod held + left-drag / right-drag | move / resize a floating window |

### Screenshots & media

| Keys | Action |
|---|---|
| `$mod+s` | screenshot: pick region (grim+slurp → file + clipboard) |
| `$mod+Shift+s` | screenshot: full screen |
| `$mod+Next` (PgDn) | playerctl play/pause |
| `$mod+Prior` (PgUp) | playerctl next track |
| `XF86AudioRaiseVolume` / `Lower` / `Mute` | volume +5% / −5% / toggle mute |
| `XF86MonBrightnessUp` / `Down` | brightness +5% / −5% |
| `$mod+n` | toggle night light (gammastep) — same toggle as the bar icon |
| `$mod+w` | pick a wallpaper interactively (`set-wallpaper`) |

## Terminal multiplexer — tmux

Prefix is `C-a` (from `.tmux.conf`). `C-a C-a` = last window; `C-a a` = send
the prefix through to a nested tmux (or a CLI like Claude Code).

| Keys | Action |
|---|---|
| `C-a r` | reload tmux config |
| `C-a \|` | split pane left/right |
| `C-a _` | split pane top/bottom |
| `C-a c` | new window (in current directory) |
| `C-a h j k l` | move focus left / down / up / right |
| `C-a H J K L` | resize pane 5 cells (repeatable) |
| `C-a f` | tmux-sessionizer — pick/attach a project session |
| `C-a A` | tmux-agents — multi-agent layout for current directory |
| `C-a e` | switch the agent CLI in the focused pane (menu: claude/opencode/gemini/grok/hermes) |
| `C-a G` / `M` / `D` | jump to git / monitor / debug window |
| `C-a W` | open a git worktree + its own agents session |
| `C-a T` / `V` | layout: tiled grid / main-vertical stack |
| copy mode: `v` `V` `C-v` `y` | start selection / select line / rectangle toggle / yank (system clipboard) |
| mouse drag (no Shift) | selects in-pane; release copies to system clipboard |

Notes: mouse is on; base-index 1 everywhere; Shift+Enter passes through to
Claude Code (allow-passthrough).

## Shell — fish

Only one custom binding; everything else is stock fish + integrations
(from `.config/fish/config.fish`):

| Keys | Action |
|---|---|
| `Ctrl+G` | cmdgen — turn English on the command line into a shell command (Hermes) |
| `Ctrl+T` | fzf: insert selected file path (fd-based) |
| `Ctrl+R` | fzf: history search |
| `Alt+C` | fzf: cd into a selected directory |

Scrollback/clipboards are terminal-level: foot handles scrollback with its
defaults (Shift+PgUp/PgDn), and selecting text in any terminal lands on the
system clipboard (copy-on-select listener ≠ nothing to press). Git and
command shorthand is abbreviations (`gst`, `gco`, `ts`, …), not keys — see
the config's "Abbreviations" section.

## Editor — Neovim

Leader is `,` (from `.config/nvim/init.lua`). Only mappings that differ from
default Vim/Neovim behavior are listed.

### Editing & navigation

| Keys | Action |
|---|---|
| `;` | acts like `:` (muscle memory) |
| `,space` | clear search highlights |
| `Ctrl+h/j/k/l` | move between splits |
| `]q` / `[q` | next / previous quickfix entry |
| `]d` / `[d` | next / previous diagnostic |
| `,dl` | diagnostics → location list |
| `C-/` | toggle bottom terminal split (insert mode too) |

### Git (gitsigns + fugitive)

| Keys | Action |
|---|---|
| `]h` / `[h` | next / previous hunk |
| `,hs` / `,hr` | stage / reset hunk |
| `,hp` / `,hb` | preview hunk / full blame line |
| `,tb` | toggle inline line blame |
| `,hd` | diff this file |
| `,gs` / `,gd` | fugitive `:Git` status / vertical diff |

### Finder (fzf-lua)

| Keys | Action |
|---|---|
| `,ff` / `,fg` / `,fb` / `,fh` | files / live grep / buffers / help tags |
| `,gf` / `,gt` / `,gc` / `,gb` | git files / status / commits / buffer commits |
| `,f` | format buffer or selection (conform; format-on-save is off) |

## Not configured (on purpose)

- foot terminal: no custom key bindings
- Firefox/swaylock/mako: stock keybindings
- Moonlight client (on the laptop, prometheus) — its shortcuts live there,
  not on this machine

#!/bin/bash
# Set the macOS launchd GUI environment to match the dot-files fish config.
#
# Why: apps launched from Finder/Dock inherit launchd's environment, which on
# macOS is nearly bare (/usr/bin:/bin:/usr/sbin:/sbin). Anything that spawns
# non-interactive shells from a GUI app — e.g. the Hermes desktop app's
# background shells — inherits that minimal env, because fish's config.fish
# only runs for fish shells. `launchctl setenv` fixes it at the source: every
# GUI-launched app (after a relaunch) gets this PATH.
#
# Kept in sync with .config/fish/config.fish PATH management (always-loaded
# section). Mirrors entries must stay in sync by hand — edit both or neither.
#
# Run by the LaunchAgent below (RunAtLoad = at every login) and by `install`.
# Idempotent: safe to run any time; takes effect for apps launched AFTER it.

set -euo pipefail

HOMEBREW_PREFIX="/opt/homebrew"

# Same order fish_add_path produces: front-of-PATH additions, most-recent
# first, with the system default kept at the tail.
GUI_PATH="$HOME/bin"
GUI_PATH="$GUI_PATH:$HOME/.local/bin"
GUI_PATH="$GUI_PATH:$HOME/.cargo/bin"
GUI_PATH="$GUI_PATH:$HOME/.bun/bin"
GUI_PATH="$GUI_PATH:$HOME/.docker/bin"
if [ -x "$HOMEBREW_PREFIX/bin/brew" ]; then
    GUI_PATH="$GUI_PATH:$HOMEBREW_PREFIX/bin"
    GUI_PATH="$GUI_PATH:$HOMEBREW_PREFIX/sbin"
    GUI_PATH="$GUI_PATH:$HOMEBREW_PREFIX/opt/openjdk/bin"
    GUI_PATH="$GUI_PATH:/Applications/Visual Studio Code.app/Contents/Resources/app/bin"
fi
GUI_PATH="$GUI_PATH:$HOME/.opencode/bin"
[ -d "$HOME/.lmstudio/bin" ] && GUI_PATH="$GUI_PATH:$HOME/.lmstudio/bin"
# mise shims (shims-first policy — see config.fish; never `mise activate` here)
if [ -d "$HOME/.local/share/mise/shims" ]; then
    GUI_PATH="$GUI_PATH:$HOME/.local/share/mise/shims"
fi
GUI_PATH="$GUI_PATH:/usr/local/bin:/System/Cryptexes/App/usr/bin:/usr/bin:/bin:/usr/sbin:/sbin"

launchctl setenv PATH "$GUI_PATH"
launchctl setenv EDITOR vim
launchctl setenv VISUAL vim
launchctl setenv BUNDLER_EDITOR code
launchctl setenv LANG en_US.UTF-8
launchctl setenv LC_ALL en_US.UTF-8
launchctl setenv LANGUAGE en_US.UTF-8
launchctl setenv FZF_DEFAULT_COMMAND 'fd --type f'

# Install the LaunchAgent so this runs at every login (RunAtLoad).
PLIST_LABEL="dev.marg.gui-env"
PLIST_DIR="$HOME/Library/LaunchAgents"
PLIST="$PLIST_DIR/$PLIST_LABEL.plist"
SELF="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/$(basename "${BASH_SOURCE[0]}")"

if [ "${1:-}" = "no-agent" ]; then
    exit 0   # just set the env, don't touch the LaunchAgent
fi

mkdir -p "$PLIST_DIR"
if [ ! -f "$PLIST" ] || ! grep -q "$SELF" "$PLIST"; then
    cat > "$PLIST" <<EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>Label</key>
    <string>$PLIST_LABEL</string>
    <key>ProgramArguments</key>
    <array>
        <string>/bin/bash</string>
        <string>$SELF</string>
        <string>no-agent</string>
    </array>
    <key>RunAtLoad</key>
    <true/>
</dict>
</plist>
EOF
    echo "installed $PLIST"
fi

# Load it for the current session (login already handles future sessions).
launchctl bootstrap "gui/$(id -u)" "$PLIST" 2>/dev/null || \
    launchctl kickstart -k "gui/$(id -u)/$PLIST_LABEL" 2>/dev/null || true

echo "launchd GUI environment set. Relaunch GUI apps (incl. Hermes Desktop) to inherit it."

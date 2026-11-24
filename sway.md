Here's a summary of the key shortcuts from your sway config (Mod = Windows key):

Launching things:
  Mod+Enter        Open a terminal (foot)
  Mod+i            Open a browser (firefox)
  Mod+d            App launcher (wofi)
  Mod+/            Keybinding helper (search all bindings, run exec ones)
  Mod+p            Clipboard history (cliphist via wofi)

Window management:
  Mod+q            Close focused window
  Mod+Shift+c      Close focused window (alias)
  Mod+f            Toggle fullscreen
  Mod+Space        Toggle floating
  Mod+j / Mod+k    Focus down / up
  Mod+Shift+j/k    Move window down / up
  Mod+h / Mod+l    Shrink / grow window width
  Mod+b            Split horizontal
  Mod+v            Split vertical
  Mod + left-drag  Move floating window
  Mod + right-drag Resize floating window

Layout templates (swap per-workspace):
  (autotile)       Default: dwm-style dynamic splits — wide container
                   splits horizontally, tall one vertically. On by default.
  Mod+a            Toggle autotile on/off
  Mod+t            Tabbed — full-height windows, switch like tabs
  Mod+u            Stacked — windows stacked vertically, title bars listed
  Mod+g            Back to default tiling (autotile resumes on next window)
  Mod+Shift+t      Retile now — stack all terminals on this workspace
                   vertically, other apps side by side (one-shot)
  Mod+e            Toggle split / tabbed (legacy)

Tiling tips:
  - Mod+Enter twice: autotile picks the split direction for you — you rarely
    need Mod+b / Mod+v by hand.
  - Nested containers: Mod+v then open a window to get a column of windows
    inside one half of a horizontal split. Repeat for complex layouts.
  - Mod+a off, then Mod+b/v give you fully manual control.

Workspaces:
  Mod+1..9         Switch to workspace 1-9
  Mod+Shift+1..9   Move window to workspace 1-9

Screenshots:
  Mod+s            Screenshot region (grim+slurp)
  Mod+Shift+s      Screenshot full screen

Media:
  Mod+PageDown     Play/pause
  Mod+PageUp       Next track
  Volume keys      Volume up/down/mute
  Brightness keys  Brightness up/down
  Mod+n            Night light on
  Mod+Shift+n      Night light off

Session:
  Mod+Shift+q      Exit sway (with confirmation)

#!/usr/bin/env python3
"""cd-iso.py — force-eject, re-insert the ISO, reset (boots the ISO)."""
import sys
sys.path.insert(0, ".")
from qmp import QMP

iso = sys.argv[1] if len(sys.argv) > 1 else \
    "/Users/kirk/dot-files/arch/iso/out/dot-files-2026.11.23-x86_64.iso"

q = QMP()
for dev in ("ide2-cd0",):
    print("force-eject ->", q.cmd("eject", device=dev, force=True))
    print("change ->", q.cmd("human-monitor-command",
                             **{"command-line": f"change ide2-cd0 \"{iso}\""}))
print("reset ->", q.cmd("system_reset"))

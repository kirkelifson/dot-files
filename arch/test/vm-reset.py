#!/usr/bin/env python3
"""vm-reset.py — reset/power-cycle helpers for the test VM.

Usage:
  vm-reset.py reset        # hard reset, keep cdrom (boots ISO again)
  vm-reset.py boot-disk    # eject cdrom + CLEAN powerdown + start from disk

boot-disk uses system_powerdown (clean guest shutdown → page cache flushed)
before restarting, because a hard reset discards btrfs writes newer than
the ~30s commit interval.
"""
import sys, time
sys.path.insert(0, ".")
from qmp import QMP

q = QMP()

def running():
    return q.cmd("query-status")["return"].get("running", False)

mode = sys.argv[1] if len(sys.argv) > 1 else "reset"
if mode in ("boot-disk", "clean"):
    bl = q.cmd("query-block")["return"]
    for b in bl:
        if b.get("device") == "ide2-cd0" and b.get("inserted", {}).get("file"):
            print("eject ->", q.cmd("eject", device="ide2-cd0", force=True))
if mode == "boot-disk":
    print("powerdown ->", q.cmd("system_powerdown"))
    for _ in range(30):
        time.sleep(2)
        if not running():
            print("guest powered off cleanly")
            break
    else:
        print("guest still running after 60s — hard reset (writes may be lost)")

print("reset ->", q.cmd("system_reset"))

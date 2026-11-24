#!/usr/bin/env python3
"""vt-switch.py — explicit down/up key sequence for ctrl+alt+fN (TCG-proof)."""
import sys, time
from qmp import QMP

vt = sys.argv[1] if len(sys.argv) > 1 else "f2"

def key(q, code, down):
    q.cmd("input-send-event", events=[{"type": "key", "data": {"down": down, "key": {"type": "qcode", "data": code}}}])

q = QMP()
time.sleep(0.5)
for c in ("ctrl", "alt"):
    key(q, c, True)
    time.sleep(0.1)
key(q, vt, True)
time.sleep(0.3)
for c in (vt, "alt", "ctrl"):
    key(q, c, False)
    time.sleep(0.1)
print(f"ctrl+alt+{vt} sent with hold")

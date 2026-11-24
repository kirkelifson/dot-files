#!/usr/bin/env python3
"""greeter-login.py — type the creds password into the focused SDDM field, Enter."""
import json, time
from qmp import QMP, KEYMAP

pw = json.load(open("/Users/kirk/dot-files/arch/archinstall/user_credentials.json"))["users"][0]["!password"]

q = QMP()
time.sleep(1)
for _ in range(20):
    q.cmd("send-key", keys=[{"type": "qcode", "data": "backspace"}])
    time.sleep(0.04)
time.sleep(0.5)
for ch in pw:
    q.cmd("send-key", keys=[{"type": "qcode", "data": KEYMAP[ch]}])
    time.sleep(0.05)
time.sleep(1.0)
q.cmd("send-key", keys=[{"type": "qcode", "data": "ret"}])
print("password typed, Enter sent")

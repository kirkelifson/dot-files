#!/usr/bin/env python3
"""ssh-root.py — ssh as xtc (password auth), run a command as root via sudo -S.
The command ships as base64 → /tmp/vm-cmd.sh (quote-proof), stdin stays free
for sudo's password prompt."""
import base64, json, sys
import pexpect

port = sys.argv[1]
cmd = " ".join(sys.argv[2:])
pw = json.load(open("/Users/kirk/dot-files/arch/archinstall/user_credentials.json"))["users"][0]["!password"]
b64 = base64.b64encode(cmd.encode()).decode()

child = pexpect.spawn(
    f"ssh -p {port} -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null "
    f"-o ConnectTimeout=30 -o NumberOfPasswordPrompts=1 xtc@127.0.0.1 "
    f"echo {b64} | base64 -d > /tmp/vm-cmd.sh && sudo -S bash /tmp/vm-cmd.sh",
    timeout=900, encoding="utf-8")
for _ in range(4):
    i = child.expect(["assword:", pexpect.EOF])
    if i == 1:
        break
    child.sendline(pw)
print(child.before)
sys.exit(child.exitstatus or 0)

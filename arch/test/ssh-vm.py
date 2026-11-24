#!/usr/bin/env python3
"""ssh-vm.py — resilient password-SSH into the test VM as root.
Reads the throwaway password from keys/rootpw; retries the connection.
Usage: ssh-vm.py <port> <command...>"""
import os, sys, time
import pexpect

DIR = os.path.dirname(os.path.abspath(__file__))
port = sys.argv[1]
cmd = " ".join(sys.argv[2:])
pw = open(f"{DIR}/keys/rootpw").read().strip()

for attempt in range(10):
    child = pexpect.spawn(
        f"ssh -p {port} -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null "
        f"-o ConnectTimeout=30 -o NumberOfPasswordPrompts=1 -o ServerAliveInterval=15 "
        f"root@127.0.0.1 {cmd!r}",
        timeout=1800, encoding="utf-8")
    while True:
        i = child.expect(["assword:", pexpect.EOF, "Connection refused",
                          "Connection reset", "timed out"])
        if i == 0:
            child.sendline(pw)
            continue
        break
    out = child.before
    status = child.exitstatus
    child.close()
    if "Permission denied" not in (out or "") and "reset" not in (out or ""):
        print(out)
        sys.exit(status or 0)
    print(f"[ssh-vm] attempt {attempt + 1} failed: {out[-200:]}", file=sys.stderr)
    time.sleep(15)
print("[ssh-vm] giving up", file=sys.stderr)
sys.exit(1)

#!/usr/bin/env python3
"""ssh-pass.py — ssh into the test VM as xtc using the password (pexpect).
Usage: ssh-pass.py <port> <command...>  — prints output, exits with ssh's code."""
import json, sys
import pexpect

port = sys.argv[1]
cmd = " ".join(sys.argv[2:])
pw = json.load(open("/Users/kirk/dot-files/arch/archinstall/user_credentials.json"))["users"][0]["!password"]

child = pexpect.spawn(
    f"ssh -p {port} -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null "
    f"-o ConnectTimeout=30 xtc@127.0.0.1 {cmd!r}",
    timeout=180, encoding="utf-8")
i = child.expect(["assword:", "Permission denied", pexpect.EOF])
if i == 0:
    child.sendline(pw)
    child.expect(pexpect.EOF)
print(child.before)
sys.exit(child.exitstatus or 0)

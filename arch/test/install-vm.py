#!/usr/bin/env python3
"""install-vm.py — run dot-files ./install in the VM as xtc over ssh -tt,
answering the safety-check prompt and chsh password prompt."""
import json, sys
import pexpect

pw = json.load(open("/Users/kirk/dot-files/arch/archinstall/user_credentials.json"))["users"][0]["!password"]

child = pexpect.spawn(
    "ssh -tt -p 2222 -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null "
    "-o ConnectTimeout=30 xtc@127.0.0.1 "
    "\"cd /home/xtc/dot-files && DOTFILES_CI=1 bash ./install\"",
    timeout=1800, encoding="utf-8", dimensions=(40, 160))

log = open("/Users/kirk/dot-files/arch/test/vm-share/install.log", "w")
while True:
    i = child.expect([
        "Continue anyway?",        # 0 safety check
        "assword:",                # 1 chsh PAM / sudo
        pexpect.EOF,               # 2
        pexpect.TIMEOUT,           # 3
    ], timeout=1800)
    log.write(child.before); log.flush()
    if i == 0:
        child.sendline("y")
    elif i == 1:
        child.sendline(pw)
    elif i == 3:
        # mise compiles runtimes (erlang/ruby from source) — silence is normal.
        # Keep the session alive; only EOF ends it.
        log.write("[install-vm] still running (no output for 30 min)\n")
        continue
    else:
        break
log.write(child.before or "")
log.write("\n[install-vm] ssh session ended, exitstatus=%s\n" % child.exitstatus)
log.close()
print("done, exitstatus:", child.exitstatus)

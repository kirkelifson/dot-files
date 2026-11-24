#!/usr/bin/env python3
"""qmp.py — drive a QEMU VM over its QMP unix socket.

Usage:
  qmp.py shot <output.png>        # screendump (PNG)
  qmp.py key <chars>              # type text (letters/digits/space/slash/dash/underscore/dot/comma/enter/tab)
  qmp.py keyraw <qcode>[,<qcode>] # raw qcodes, e.g. ret,ctrl+alt+f2
  qmp.py status                   # query-status
"""
import json, socket, sys, time

SOCK = "/tmp/arch-vm-qmp.sock"

class QMP:
    def __init__(self, path=SOCK):
        # QEMU's main loop can be briefly unresponsive under TCG load — retry.
        last = None
        for attempt in range(4):
            try:
                self.s = socket.socket(socket.AF_UNIX, socket.SOCK_STREAM)
                self.s.connect(path)
                self.f = self.s.makefile("rw")
                self._read_until_event("QMP")  # greeting
                self.cmd("qmp_capabilities")
                return
            except Exception as e:
                last = e
                try:
                    self.s.close()
                except Exception:
                    pass
                time.sleep(5 * (attempt + 1))
        raise RuntimeError(f"QMP connect failed after retries: {last}")

    def _read_until_event(self, name, timeout=30):
        self.s.settimeout(timeout)
        while True:
            line = self.f.readline()
            if not line:
                raise RuntimeError("QMP socket closed")
            msg = json.loads(line)
            if "event" in msg and msg["event"] == name:
                return msg
            if "QMP" in msg:  # greeting
                return msg
            if "return" in msg or "error" in msg:
                return msg

    def cmd(self, name, **args):
        # One retry with reconnect: the main loop can wedge briefly under TCG
        # (9p mounts etc.) and drop/reset the socket mid-command.
        for attempt in range(2):
            try:
                self.f.write(json.dumps({"execute": name, "arguments": args}) + "\n")
                self.f.flush()
                return self._read_until_event(None)
            except Exception:
                if attempt == 1:
                    raise
                time.sleep(5)
                self.s.close()
                self.__init__()

    def screendump(self, path):
        self.f.write(json.dumps({"execute": "screendump",
                                 "arguments": {"filename": path, "format": "png"}}) + "\n")
        self.f.flush()
        self.s.settimeout(30)
        deadline = time.time() + 30
        while time.time() < deadline:
            line = self.f.readline()
            if not line:
                raise RuntimeError("QMP socket closed")
            msg = json.loads(line)
            if "error" in msg:
                raise RuntimeError(msg)
            if "return" in msg:
                time.sleep(1.5)
                import os
                if os.path.exists(path):
                    return True
        return False

KEYMAP = {c: c for c in "abcdefghijklmnopqrstuvwxyz0123456789"}
KEYMAP.update({" ": "spc", "/": "slash", "-": "minus", "_": "underscore",
               ".": "dot", ",": "comma", "=": "equal", "\n": "ret",
               "\t": "tab", ":": "shift-semicolon"})
UPPERMAP = {c: c.lower() for c in "ABCDEFGHIJKLMNOPQRSTUVWXYZ"}

def main():
    action = sys.argv[1]
    q = QMP()
    if action == "shot":
        ok = q.screendump(sys.argv[2])
        print("shot:", sys.argv[2], "ok" if ok else "TIMEOUT")
    elif action == "key":
        text = sys.argv[2]
        for ch in text:
            if ch in UPPERMAP:
                # uppercase letter: hold shift + letter
                q.cmd("send-key", keys=[{"type": "qcode", "data": "shift"},
                                        {"type": "qcode", "data": UPPERMAP[ch]}])
            else:
                qc = KEYMAP.get(ch)
                if qc is None:
                    sys.exit(f"no keymap for {ch!r}")
                q.cmd("send-key", keys=[{"type": "qcode", "data": qc}])
            time.sleep(0.03)
        print(f"typed {len(text)} chars")
    elif action == "keysfile":
        # Batch-typing over ONE connection: lines are typed + Enter'd in order.
        # Survives QEMU main-loop wedges (e.g. guest mounting the 9p share),
        # because send-keys queue in the chardev while the loop is blocked.
        path = sys.argv[2]
        delay = float(sys.argv[3]) if len(sys.argv) > 3 else 2.0
        lines = [l.rstrip("\n") for l in open(path) if l.strip()]
        for i, line in enumerate(lines):
            for ch in line:
                if ch in UPPERMAP:
                    q.cmd("send-key", keys=[{"type": "qcode", "data": "shift"},
                                            {"type": "qcode", "data": UPPERMAP[ch]}])
                else:
                    qc = KEYMAP.get(ch)
                    if qc is None:
                        sys.exit(f"no keymap for {ch!r}")
                    q.cmd("send-key", keys=[{"type": "qcode", "data": qc}])
                time.sleep(0.03)
            q.cmd("send-key", keys=[{"type": "qcode", "data": "ret"}])
            if i < len(lines) - 1:
                time.sleep(delay)
            print(f"typed line {i + 1}/{len(lines)}: {line}")
    elif action == "keyraw":
        for combo in sys.argv[2].split(","):
            keys = [{"type": "qcode", "data": k} for k in combo.split("+")]
            q.cmd("send-key", keys=keys)
            time.sleep(0.03)
        print("sent raw keys")
    elif action == "status":
        print(json.dumps(q.cmd("query-status")))

if __name__ == "__main__":
    main()

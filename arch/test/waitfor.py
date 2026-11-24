#!/usr/bin/env python3
"""waitfor.py — poll VM screendump + tesseract until text appears.

Usage: waitfor.py <substring> [timeout_seconds] [poll_interval]
Exit 0 when found (prints the OCR line), 1 on timeout.
"""
import subprocess, sys, time, os

text = sys.argv[1]
timeout = int(sys.argv[2]) if len(sys.argv) > 2 else 600
interval = int(sys.argv[3]) if len(sys.argv) > 3 else 15
os.chdir(os.path.dirname(os.path.abspath(__file__)))
shot = "shots/wait-now.png"

deadline = time.time() + timeout
while time.time() < deadline:
    r = subprocess.run([sys.executable, "qmp.py", "shot", shot], capture_output=True, text=True)
    if "ok" not in (r.stdout + r.stderr):
        # VM may be wedged briefly (9p mounts wedge QEMU's main loop) — keep polling
        time.sleep(interval)
        continue
    ocr = subprocess.run(["tesseract", shot, "stdout", "--psm", "6"], capture_output=True, text=True).stdout
    low = ocr.lower()
    if text.lower() in low:
        for line in ocr.splitlines():
            if text.lower() in line.lower():
                print("FOUND:", line.strip())
                sys.exit(0)
        print("FOUND (somewhere on screen)")
        sys.exit(0)
    time.sleep(interval)
print(f"TIMEOUT waiting for {text!r} after {timeout}s")
sys.exit(1)

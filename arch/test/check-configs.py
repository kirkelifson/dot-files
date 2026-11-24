#!/usr/bin/env python3
"""check-configs.py — CI-safe sanity checks for the arch install kit.

Runs in CI (fast, read-only). Validates:
  - JSON validity of the archinstall configs
  - disk layout schema sanity for archinstall 4.x (config_type, ESP flags)
  - required config keys present (hostname, bootloader_config, locale_config)
  - no plaintext password fields committed
  - test harness files exist and carry the CI guard
"""
import json, subprocess, sys, os

repo = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
errors = []

def git_tracked(rel):
    """True if the path is tracked (or would be committed) by git."""
    r = subprocess.run(["git", "ls-files", "--", rel], cwd=repo,
                       capture_output=True, text=True)
    return bool(r.stdout.strip())

def check(cond, msg):
    print(("PASS: " if cond else "FAIL: ") + msg)
    if not cond:
        errors.append(msg)

cfg_path = f"{repo}/arch/iso/airootfs/root/archinstall-config/user_configuration.json"
cfg = json.load(open(cfg_path))
check(bool(cfg.get("hostname")), "config has hostname")
check(bool(cfg.get("bootloader_config", {}).get("bootloader")), "bootloader_config present")
check(cfg.get("locale_config", {}).get("kb_layout") == "us", "keyboard layout us")
check(bool(cfg.get("services")), "services enabled (sddm/NetworkManager)")

dc = cfg.get("disk_config", {})
check(dc.get("config_type") == "default_layout", "disk_config.config_type = default_layout")
mods = dc.get("device_modifications", [])
check(len(mods) == 1, "exactly one target device")
parts = mods[0].get("partitions", []) if mods else []
check(len(parts) == 2, "two partitions (ESP + root)")
if len(parts) == 2:
    esp, root = parts
    check(esp.get("fs_type") == "fat32", "ESP fs_type fat32")
    check(esp.get("mountpoint") == "/boot", "ESP mounted /boot")
    check("esp" in [f.lower() for f in esp.get("flags", [])],
          "ESP has the 'esp' flag (archinstall 4.x is_efi check — prevents 'Could not detect EFI system partition')")
    check("boot" in [f.lower() for f in esp.get("flags", [])], "ESP has boot flag")
    check(root.get("fs_type") == "btrfs", "root fs btrfs")
    check(root.get("mountpoint") == "/", "root mounted /")
    for p in (esp, root):
        check(p.get("status") == "create", "partition status create")
        check("obj_id" in p, "partition obj_id present")
        for key in ("start", "size"):
            check(key in p and "unit" in p[key] and "sector_size" in p[key],
                  f"{key} uses archinstall 4.x Size serialization")

# credentials must never be committed (they live locally, gitignored, for builds)
for p in ("arch/archinstall/user_credentials.json",
          "arch/iso/airootfs/root/archinstall-config/user_credentials.json"):
    check(not git_tracked(p), f"{p} not tracked by git")

# plaintext password markers must never appear in tracked files
scan = subprocess.run(["git", "ls-files", "arch/"], cwd=repo,
                      capture_output=True, text=True).stdout.split()
for rel in scan:
    path = os.path.join(repo, rel)
    if not os.path.isfile(path):
        continue
    content = open(path, errors="ignore").read()
    if rel.endswith("check-configs.py"):
        continue
    if rel.endswith(".example"):
        # template file: fine as long as it still holds the placeholder
        check('"CHANGE_ME"' in content, f"{rel} is the placeholder template")
        continue
    check("'!password'" not in content,
          f"{rel} has no plaintext '!password' field")

# test harness: every bash entry point carries the CI guard
for script in ("run-vm-test.sh", "fill-pkg-cache.sh", "setup-installed.sh"):
    path = f"{repo}/arch/test/{script}"
    check(os.path.exists(path), f"arch/test/{script} exists")
    if os.path.exists(path):
        content = open(path).read()
        check("CI:-}" in content or "CI" in content and "REFUSING" in content,
              f"arch/test/{script} has the never-run-in-CI guard")

# river session packages present (SDDM needs the session)
pkgs = cfg.get("packages", [])
check("sddm" in pkgs and "sway" in pkgs, "sddm + sway in install package list")
check("firefox" in pkgs, "firefox (default browser) in install package list")
check("chromium" in pkgs, "chromium in install package list")

# AUR packages list (installed by post-install via paru; CI can't check the AUR)
aur = f"{repo}/packages-aur.txt"
check(os.path.exists(aur), "packages-aur.txt exists")
if os.path.exists(aur):
    check("1password" in open(aur).read(),
          "packages-aur.txt includes 1password")

# sway config sanity: exists, autostarts the bar, pins VRR display mode
sway_cfg = f"{repo}/arch/sway/config"
check(os.path.exists(sway_cfg), "arch/sway/config exists")
if os.path.exists(sway_cfg):
    sc = open(sway_cfg).read()
    check("exec waybar" in sc, "sway config autostarts waybar")
    check("adaptive_sync on" in sc, "sway config enables VRR (adaptive_sync)")
    check("shot-region" in sc, "sway config binds screenshot scripts")

# autostart.sh size query must be disk-only (-d): without it, lsblk lists
# partitions too and int() chokes on multi-line output (real bug, fixed 2026-11)
autostart = f"{repo}/arch/iso/airootfs/root/autostart.sh"
check('"-d"' in open(autostart).read(), "autostart.sh lsblk size query is disk-only (-d)")
at = open(autostart).read()
check("total_bytes // (1024 * 1024)" in at,
      "autostart.sh computes root size from the ACTUAL disk (no 1TB assumption)")
check('mod["device"] = target' in at, "autostart.sh patches the target device into the config")

# The baked device is a placeholder: autostart always overwrites it from the
# user-typed target. It must never name a real disk, or an unpatched run
# could aim at the wrong drive (e.g. the Windows NVMe).
cfg = json.load(open(f"{repo}/arch/archinstall/user_configuration.json"))
dev = cfg["disk_config"]["device_modifications"][0]["device"]
check(dev.startswith("/dev/REPLACED"),
      f"baked device is the autostart placeholder (got '{dev}')")
check(not os.path.exists(f"{repo}/arch/iso/airootfs/root/archinstall-config/user_disk_layout.json"),
      "no stale v3 user_disk_layout.json in the ISO tree")

print()
if errors:
    print(f"{len(errors)} check(s) FAILED"); sys.exit(1)
print("all arch-kit config checks passed")

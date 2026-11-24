# arch/test/ — local VM verification of the arch install kit

End-to-end test: build ISO → install into a QEMU VM (driving the unattended
archinstall over QMP) → run post-install.sh → assert the outcomes.

**Never run in CI.** These stages boot emulated machines, open sockets and
download gigabytes. Every script checks `$CI` and refuses; CI (see
`.github/workflows/arch-kit.yml`) only runs the superficial checks:
`check-configs.py` (schema sanity), bash syntax, package availability, and a
CVE report against the security-tracker feed.

## One-time setup

- `brew install qemu tesseract` (macOS)
- Docker Desktop running (for `build-iso.sh` and `fill-pkg-cache.sh`)

## Workflow

```bash
cd ~/dot-files
./arch/build-iso.sh                    # ISO in arch/iso/out/ (pkg cache persists)
arch/test/fill-pkg-cache.sh            # optional: snapshot packages for the VM phase
arch/test/run-vm-test.sh install       # ~25-35 min: full unattended install in VM
arch/test/run-vm-test.sh prep-ssh      # prep installed system for ssh validation
arch/test/run-vm-test.sh post-install  # run post-install.sh over ssh
arch/test/run-vm-test.sh verify        # assert zram/river/ssh/dot-files/bootctl
```

Artifacts (disk image, keys, screenshots, package caches) are gitignored —
they are disposable. The throwaway SSH key and NOPASSWD sudo exist only
inside the VM.

## What "pass" means

- `install`: log ends with `Installation completed without any errors`
- after reboot: SDDM greeter lists the **River** session; login works
- `post-install`: multilib enabled, gaming packages in, zram up, river config
  at `~/.config/river`, sshd hardened on :8631, dot-files cloned + `./install` ran
- no test-only packages in the installed system (`pacman -Q` diff vs the
  package lists — the harness only adds sshd/sudoers/9p glue *inside the VM*)

See the `arch-vm-install-test` skill for the pitfalls list (archinstall 4.x
schema, QMP keyboard limits, river's blank-session behavior).

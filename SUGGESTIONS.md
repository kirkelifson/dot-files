# Suggestions

Open improvements for the dot-files repo. Items are removed once verified
done on the machine.

## SSH / Remote Machines

- [ ] **SSH config management** — Add a base `~/.ssh/config` template to the repo with common settings: keepalive intervals, connection multiplexing (`ControlMaster`), agent forwarding defaults. The install script could link or merge it.

## Git

- [ ] **`gitconfig` lacks `includeIf` for machine-specific identity** — `.gitconfig` has your personal email hardcoded. On work machines or shared servers this is awkward. Add an `[includeIf "gitdir:~/work/"]` block pointing to a `~/.gitconfig-work` (not committed) with a different `user.email`. The install script could template it.

## CI / Repo Hygiene

- [ ] **Pin GitHub Actions to commit SHAs** — Workflows reference actions by tag (`actions/checkout@v5`). Tags are mutable; pin to full SHAs (Dependabot can keep them updated) so a compromised action repo can't run code in CI with your secrets.

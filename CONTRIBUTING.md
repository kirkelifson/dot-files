# Contributing

## Commit guide

Every commit (human or agent) follows this format:

```text
<type>: <summary in imperative mood, ≤72 chars, no trailing period>

Optional body: blank line after the subject, wrapped at 72 columns.
The body explains WHY — context, rationale, trade-offs — not a restatement
of the diff. Reference files, tickets or issues where useful.
```

**Types:** `feat`, `fix`, `chore`, `docs`, `refactor`, `test`, `perf`, `security`.

**Rules:**

1. **One logical change per commit.** Unrelated concerns get separate commits
   (e.g. a bug fix never rides along with a gem bump). When one file spans two
   concerns, split it at the hunk level (`git apply --cached` with a filtered
   patch).
2. **Verify before committing, not in the message.** Run the relevant tests and
   lint first (see AGENTS.md → Testing). No editorial prefixes in subjects —
   no `[verified]`, `[WIP]`, `[DO NOT MERGE]` — the history should read as
   plain changelog entries.
3. **Subject says what the commit does**, from a reader's perspective:
   `fix: authenticate users before admin-only redirects`, not
   `update controllers`.
4. **Never rewrite pushed history**, never force-push shared branches, and
   never commit secrets, credentials or generated artifacts (`Gemfile.lock`
   version bumps are fine; `.env`/keys never).
5. **Chunked feature work:** group commits by concern (fix → hardening →
   cleanup → docs → deps), so any commit can be reverted alone.

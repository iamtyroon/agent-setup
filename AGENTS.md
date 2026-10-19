# agent-setup

Portable AI-agent setup for Claude Code, Codex, OpenCode, and Antigravity.

## Always-on response defaults

Apply these defaults without requiring a skill command, unless the user asks
for another style:

- Caveman: lead with result or next action; use terse, direct, technically exact prose.
- ADHD-friendly: number bounded steps, restate current state, suppress tangents, show wins, and end with one next action when work remains.

Always-on skills — load these at the start of any coding task, without being asked:

| Skill | Covers |
|---|---|
| `karpathy-guidelines` | whether to change: surface assumptions, simplicity, surgical edits, verifiable goals |
| `ponytail` | how little to change: smallest diff that fully solves the task |

They do not conflict: `karpathy-guidelines` decides scope, `ponytail` decides size.
When they disagree, take the smaller diff.

`karpathy-guidelines` restates the same four principles that also appear as prose in
`claude/CLAUDE.md` and `codex/AGENTS.md`. Apply them once — do not restate them back
to the user or add a fifth near-identical rule.

Relevant skills should autoload from their descriptions. Keep intrusive or
state-changing workflows explicit-only: `grill-me`, `user-context`, `share`, and
`yeet`. The `ponytail-audit`, `ponytail-debt`, `ponytail-gain`, `ponytail-help`, and
`ponytail-review` skills are one-shot reports, not edits — leave them explicit-only
unless the user names the specific one.

## Codex and OpenCode support

- Keep `.codex/config.toml` portable: no machine paths, credentials, tokens, or session data.
- Keep Codex roles in `.codex/agents/` and vendored skills under `codex/skills/`.
- Keep `opencode.json` portable: no machine paths, credentials, tokens, or session data.
- Keep OpenCode project agents in `.opencode/agents/`; `scripts/sync-opencode.mjs` converts Codex TOML roles for user-wide OpenCode use.
- Installer changes must remain idempotent and preserve existing user config.
- `scripts/sync-codex-config.mjs` adds missing Codex sections without replacing existing sections.
- `scripts/sync-opencode.mjs` copies valid Codex skills into OpenCode's flat skill directory and preserves existing OpenCode agents.

## Verification

- Parse `install.ps1` and run `bash -n install.sh`.
- Run `node scripts/sync-codex-config.mjs --check` against a temporary config when changing sync behavior.
- Run `node scripts/sync-opencode.mjs --check` against a temporary target when changing OpenCode sync behavior.
- Review `git diff` before commit.

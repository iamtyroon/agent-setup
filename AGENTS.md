# agent-setup

Portable AI-agent setup for Claude Code, Codex, OpenCode, and Antigravity.

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

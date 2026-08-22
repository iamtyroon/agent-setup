# Codex global baseline

This file is installed as global Codex guidance only when no user
`$CODEX_HOME/AGENTS.md` exists. Existing user guidance is preserved.

- Read the active project `AGENTS.md` before changing files.
- Use `.agents/skills/` for Codex skills; this setup copies vendored skills there.
- Keep networked tools read-only by default. Ask before publishing, pushing,
  merging, changing third-party resources, or modifying credentials.
- Never commit secrets, auth files, MCP tokens, private session logs, or machine
  paths.
- Validate trust-boundary inputs, review diffs, and run the smallest relevant
  verification after changes.

Project-local Codex roles and portable MCP defaults live in `.codex/`.

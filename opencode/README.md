# OpenCode support

OpenCode support has three layers:

- `opencode.json` — project-local portable MCP and skill-permission baseline.
- `.opencode/agents/` — explorer, reviewer, and documentation-researcher subagents.
- `.opencode/plugins/rtk.ts` — OpenCode-native shell-command rewrite plugin.
- `scripts/sync-opencode.mjs` — copies repository/Codex-cache skills and converts Codex TOML roles for user-wide OpenCode use.

The project MCP baseline includes GitHub, Context7, Exa, Memory, Playwright,
Sequential Thinking, and Godot. `tokless` adds `codegraph` and `context-mode`
with local machine paths after installation.

Run from the repository root:

```text
opencode
```

The installer detects OpenCode through its command or config directory. It
preserves existing OpenCode config and agent files, refreshes skills managed by
this repository, and leaves auth, sessions, projects, plugin caches, and MCP
caches in OpenCode's user-local data directory.

Codex remote plugins are not copied as OpenCode plugins because the runtimes use
different plugin formats. Their vendored skill payloads and portable MCP entries
are supported; OpenCode-native plugins remain user-installed.

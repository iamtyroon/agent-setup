# Codex support

Portable Codex support has three layers:

- `.codex/config.toml` — project-local sandbox, web, multi-agent, and MCP baseline.
- `.codex/agents/` — explorer, reviewer, and documentation-researcher role layers.
- `codex/skills/` and `codex/references/` — vendored skills and supporting references.

OpenCode consumes the same vendored skills through `opencode.json` and
`scripts/sync-opencode.mjs`. The sync flattens nested Codex skill bundles into
OpenCode's user-wide skill directory and converts Codex TOML role layers into
OpenCode Markdown subagents. OpenCode project agents live in
`.opencode/agents/`.

The installer copies skills and missing role files into `$CODEX_HOME`, then runs
`scripts/sync-codex-config.mjs`. Sync is add-only: existing config sections,
credentials, global `AGENTS.md`, and custom agent roles remain untouched.

`codex/AGENTS.md` is copied as global guidance only when no user global
`AGENTS.md` exists. The repo root `AGENTS.md` remains the project-specific guide.

## Vendored skills

These skill folders are vendored so a new computer gets the same Codex surface
without relying on a live marketplace install.

| Skill | Source | Codex behavior |
| --- | --- | --- |
| `impeccable` | [pbakaus/impeccable](https://github.com/pbakaus/impeccable) | Frontend design, responsive UX, accessibility, motion, and visual QA |
| `unslop` | [theclaymethod/unslop](https://github.com/theclaymethod/unslop) | Audit or rewrite AI-sounding prose; preserves facts and structure |
| `i-have-adhd` | [ayghri/i-have-adhd](https://github.com/ayghri/i-have-adhd) | Explicit action-first output mode via `$i-have-adhd` |
| `grill-me` + `grilling` | [mattpocock/skills](https://github.com/mattpocock/skills) | Explicit plan/design interview via `$grill-me`; `grill-me` routes to `grilling` |
| `roblox-brain` | [TabooHarmony/roblox-brain](https://github.com/TabooHarmony/roblox-brain) | 28 focused Roblox/Luau/Studio skills: architecture, networking, UI, data, performance, security, tooling, and publishing |
| `unity-agent-workflows` | [AUN-PN/unity-agent-workflows](https://github.com/AUN-PN/unity-agent-workflows) | Unity project discovery, runtime-owner proof, visible-output validation, UI/scene/asset gates, and cleanup |
| `malware-analysis-static` | [guelfoweb/malware-analysis-static](https://github.com/guelfoweb/malware-analysis-static) | Static malware analysis and reverse engineering with isolated-lab warnings, evidence preservation, staged analysis, and report structure |
| `game-studio` slice | [openai/plugins](https://github.com/openai/plugins/tree/main/plugins/game-studio) | Browser-game routing for R3F, vanilla Three/WebGL, 3D assets, game UI, architecture, and playtesting |
| `touchdesigner-mcp` | [NousResearch/hermes-agent](https://github.com/NousResearch/hermes-agent/tree/main/skills/creative/touchdesigner-mcp) | TouchDesigner operator workflows, audio-reactive GLSL, compositing, projection, particles, MIDI/OSC, Python, and twozero MCP guidance |

The `game-studio` slice includes `react-three-fiber-game`, `three-webgl-game`,
`web-3d-asset-pipeline`, `web-game-foundations`, `game-ui-frontend`,
`game-playtest`, `game-studio`, `phaser-2d-game`, and `sprite-pipeline`. Its
shared references are copied to the user-wide `.agents/references` directory so
relative playbooks resolve. Sprite-processing scripts are intentionally excluded.

The installer copies these folders into the detected user-wide Codex skills
directory. It does not remove other skills.

Snapshot refs: `impeccable@f88b2837a7d7`, `unslop@d81f5196167d`,
`i-have-adhd@e7555fcaf612`, `mattpocock/skills@9c9f36ccd399`,
`roblox-brain@856f0fa27717106c5cf1d305368dd4eb72ff76cb`,
`unity-agent-workflows@6ab1853f964b2396da4b8933a5cb8826111d693b`,
`malware-analysis-static@6eba45bb6cdcd9e3871236c1e956dbcf3624dfa7`,
`openai/plugins@11c74d6ba24d3a6d48f54a194cd00ef3beea18f9`,
`hermes-agent@5dd15872a6878a19b9b5478b6968b38f48dd311f`.

TouchDesigner installation is docs-only. The upstream setup script is not
vendored because it downloads `twozero.tox`, edits Hermes config, and enables a
localhost control server. Install or activate twozero MCP separately only when
you explicitly want live TD control.

Security research remains scope-aware. Use malware analysis and reverse engineering
on samples you own or are authorized to inspect, in an isolated lab. Use bug-bounty
work only inside the program's written scope. Offensive exploit, persistence,
credential, payload, and evasion work stays explicit/on-demand rather than being
made an always-on global behavior.

Ponytail comes from [tokless](https://github.com/HoangP8/tokless), which wires
its always-on Codex instructions. Keeping one source avoids duplicate global
instructions.

# agent-setup

My AI coding-agent toolkit. One script reproduces the full setup on any computer, for Claude Code, Codex, OpenCode, and Antigravity.

## What it installs

| Layer | Tool | What it does |
|---|---|---|
| [tokless](https://github.com/HoangP8/tokless) | caveman | Terse output - ~65% fewer tokens |
| | ponytail | Lazy-senior-dev minimalism, no over-engineering |
| | rtk | Compresses command output before it hits the LLM |
| | codegraph | Pre-indexed code knowledge graph (MCP) |
| | context-mode | Sandboxed tool output + session memory (MCP) |
| [ECC](https://github.com/affaan-m/ECC) | minimal + core profiles | Skills, rules, agents, commands (/plan, /code-review, /learn, ...) |
| [impeccable](https://github.com/pbakaus/impeccable) | design skill | 23 design commands + detector rules |
| Codex | `.codex/` + `codex/` | Portable config, multi-agent roles, MCP baseline, and vendored skills |
| OpenCode | `opencode.json` + `.opencode/` | Project MCP baseline, agents, rtk plugin, and Codex-skill sync |
| Personal | `claude/skills/` | 12 design skills (brandkit, gpt-taste, minimalist-ui, ...) |
| Personal | `claude/CLAUDE.md` | Global instructions for all projects |

## Install (new computer)

Prereqs: Node.js + npm. Agents you use (Claude Code, Codex, OpenCode) installed first.

**Windows (PowerShell):**
```powershell
git clone https://github.com/iamtyroon/agent-setup
cd agent-setup
.\install.ps1
```

**macOS / Linux:**
```bash
git clone https://github.com/iamtyroon/agent-setup
cd agent-setup
./install.sh
```

Then restart your agent sessions.

## Update on an existing computer

```
tokless update
ecc auto-update
git pull && ./install.sh   # or .\install.ps1
```

## Repo layout

```
install.ps1        Windows installer
install.sh         macOS/Linux installer
AGENTS.md          Repo instructions loaded by Codex
.codex/config.toml Project-local Codex baseline and portable MCP servers
.codex/agents/     Codex multi-agent role layers
codex/skills/      Vendored Codex skills copied to the global Codex skill path
codex/references/  Shared references for the vendored OpenAI game-studio slice
codex/AGENTS.md    Optional global Codex guidance
opencode.json      Project-local OpenCode MCP and skill-permission baseline
.opencode/agents/  OpenCode subagents mirroring the Codex baseline roles
.opencode/plugins/ OpenCode-native rtk command-rewrite plugin
scripts/           Cross-platform setup helpers
claude/CLAUDE.md   Global Claude instructions
claude/skills/     Personal skills (copied to ~/.claude/skills)
```

Codex and OpenCode config, agent roles, skill details, and source links live in
[`codex/README.md`](codex/README.md) and [`opencode/README.md`](opencode/README.md).

`ponytail` is already bundled and wired by `tokless`; it is intentionally not
vendored a second time here. The installer runs tokless wiring for Codex.

In Codex, `$i-have-adhd` and `$grill-me` are explicit opt-in skills. `ponytail`
stays active through the global tokless instructions. `unslop` and
`$impeccable` activate when the task matches their descriptions or when you
invoke them directly.

Safe to re-run: every step is idempotent.

The Codex config sync is add-only. It adds missing MCP, feature, and agent
sections to `$CODEX_HOME/config.toml`; it preserves existing sections and
credentials. Existing global `AGENTS.md` and agent role files are preserved.

## OpenCode support

Run OpenCode from this repository root. `opencode.json` provides the portable
GitHub, Context7, Exa, Memory, Playwright, Sequential Thinking, and Godot MCP
baseline. `tokless` continues to wire machine-local `codegraph` and
`context-mode` entries. `.opencode/plugins/rtk.ts` rewrites supported shell
commands through the installed `rtk` binary.

The installer runs `scripts/sync-opencode.mjs`. It flattens every valid
`codex/skills/**/SKILL.md` bundle, plus valid skills found in the local Codex
skill and plugin caches, into OpenCode's user-wide skill directory. It also
converts Codex TOML roles into OpenCode Markdown agents. Existing OpenCode
agents and configuration are preserved; managed skill files are refreshed.

OpenCode session history, project registry, credentials, plugin cache, and MCP
cache stay in user-local application data. They are intentionally not committed
to this repository.

Codex remote plugins do not have a universal OpenCode plugin format. Their
portable skill payloads and MCP baseline are synced here; OpenCode-native plugins
remain user-installed in OpenCode's global config.

## Notes / known quirks

- **tokless binary locked:** if tokless is already installed, its binary may be locked by a running agent process, so the installer skips the download. Upgrade with `tokless update` after closing agent sessions.
- **Step order matters:** ECC and impeccable installs can overwrite agent MCP config, so tokless wiring runs last. If `tokless doctor` ever reports missing tools after another install, re-run `tokless --agents claude,opencode,codex,antigravity`.
- **`ecc doctor` warnings:** "drifted managed files" warnings are expected — tokless and impeccable touch ECC-managed configs. Not an error; the installer treats them as non-fatal.
- **Project-local artifacts:** impeccable installs into the current directory too; `.gitignore` keeps those (`.claude/`, `.codegraph/`, etc.) out of the repo.

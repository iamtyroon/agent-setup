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
claude/CLAUDE.md   Global Claude instructions
claude/skills/     Personal skills (copied to ~/.claude/skills)
```

Safe to re-run: every step is idempotent.

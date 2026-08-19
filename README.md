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
| Codex | `codex/skills/` | Impeccable, Unslop, I Have ADHD, Grill Me, Roblox, Unity, TouchDesigner, static malware analysis, and 3D web-game skills |
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
codex/skills/      Vendored Codex skills copied to the global Codex skill path
codex/references/  Shared references for the vendored OpenAI game-studio slice
claude/CLAUDE.md   Global Claude instructions
claude/skills/     Personal skills (copied to ~/.claude/skills)
```

Codex skill details and source links live in [`codex/README.md`](codex/README.md).

`ponytail` is already bundled and wired by `tokless`; it is intentionally not
vendored a second time here. The installer runs tokless wiring for Codex.

In Codex, `$i-have-adhd` and `$grill-me` are explicit opt-in skills. `ponytail`
stays active through the global tokless instructions. `unslop` and
`$impeccable` activate when the task matches their descriptions or when you
invoke them directly.

Safe to re-run: every step is idempotent.

## Notes / known quirks

- **tokless binary locked:** if tokless is already installed, its binary may be locked by a running agent process, so the installer skips the download. Upgrade with `tokless update` after closing agent sessions.
- **Step order matters:** ECC and impeccable installs can overwrite agent MCP config, so tokless wiring runs last. If `tokless doctor` ever reports missing tools after another install, re-run `tokless --agents claude,opencode,codex,antigravity`.
- **`ecc doctor` warnings:** "drifted managed files" warnings are expected — tokless and impeccable touch ECC-managed configs. Not an error; the installer treats them as non-fatal.
- **Project-local artifacts:** impeccable installs into the current directory too; `.gitignore` keeps those (`.claude/`, `.codegraph/`, etc.) out of the repo.

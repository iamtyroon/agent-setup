#!/usr/bin/env bash
# agent-setup installer (macOS / Linux)
set -euo pipefail
repo="$(cd "$(dirname "$0")" && pwd)"

echo "== 1/5 tokless =="
curl -fsSL https://raw.githubusercontent.com/HoangP8/tokless/main/scripts/install.sh | CI=1 bash
export PATH="$HOME/.local/bin:$PATH"
tokless --agents claude,opencode,codex,antigravity

echo "== 2/5 ECC =="
npm install -g ecc-universal
ecc install --target claude --profile minimal
ecc install --target claude --profile core
[ -d "$HOME/.codex" ]    && ecc install --target codex --profile core
[ -d "$HOME/.opencode" ] && ecc install --target opencode --profile opencode

echo "== 3/5 impeccable =="
npx -y impeccable install

echo "== 4/5 personal skills + CLAUDE.md =="
mkdir -p "$HOME/.claude/skills"
cp -R "$repo/claude/skills/." "$HOME/.claude/skills/"
cp "$repo/claude/CLAUDE.md" "$HOME/.claude/CLAUDE.md"

echo "== 5/5 verify =="
tokless doctor
ecc doctor

echo "Done. Restart agent sessions (Claude Code, Codex, OpenCode)."

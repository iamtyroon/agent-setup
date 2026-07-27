#!/usr/bin/env bash
# agent-setup installer (macOS / Linux)
set -euo pipefail
repo="$(cd "$(dirname "$0")" && pwd)"

echo "== 1/5 tokless =="
export PATH="$HOME/.local/bin:$PATH"
if command -v tokless >/dev/null; then
  echo "tokless present, skipping download (run 'tokless update' to upgrade)"
else
  curl -fsSL https://raw.githubusercontent.com/HoangP8/tokless/main/scripts/install.sh | CI=1 bash
fi

echo "== 2/5 ECC =="
npm install -g ecc-universal
ecc install --target claude --profile minimal
ecc install --target claude --profile core
[ -d "$HOME/.codex" ]    && ecc install --target codex --profile core
[ -d "$HOME/.opencode" ] && ecc install --target opencode --profile opencode

echo "== 3/5 impeccable =="
npx -y impeccable install

# tokless wiring last: ECC/impeccable installs can overwrite agent MCP config
tokless --agents claude,opencode,codex,antigravity

echo "== 4/5 personal skills + CLAUDE.md =="
mkdir -p "$HOME/.claude/skills"
cp -R "$repo/claude/skills/." "$HOME/.claude/skills/"
cp "$repo/claude/CLAUDE.md" "$HOME/.claude/CLAUDE.md"

echo "== 5/5 verify =="
tokless doctor
# warnings about drifted managed files are expected (tokless/impeccable touch shared configs)
ecc doctor || true

echo "Done. Restart agent sessions (Claude Code, Codex, OpenCode)."

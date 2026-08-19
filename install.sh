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

echo "== 4/6 Codex skills =="
codex_skill_source="$repo/codex/skills"
codex_reference_source="$repo/codex/references"
codex_home="${CODEX_HOME:-}"
if [ -z "$codex_home" ] && [ -d "$HOME/.codex" ]; then
  codex_home="$HOME/.codex"
fi
if [ -z "$codex_home" ] && command -v codex >/dev/null 2>&1; then
  codex_home="$HOME/.codex"
fi
if [ -n "$codex_home" ] && [ -d "$codex_skill_source" ]; then
  codex_skill_destination="$codex_home/.agents/skills"
  mkdir -p "$codex_skill_destination"
  for skill_dir in "$codex_skill_source"/*/; do
    [ -d "$skill_dir" ] || continue
    skill_name="$(basename "$skill_dir")"
    mkdir -p "$codex_skill_destination/$skill_name"
    cp -R "$skill_dir/." "$codex_skill_destination/$skill_name/"
  done
  if [ -d "$codex_reference_source" ]; then
    codex_reference_destination="$codex_home/.agents/references"
    mkdir -p "$codex_reference_destination"
    cp -R "$codex_reference_source/." "$codex_reference_destination/"
  fi
else
  echo "Codex not found, skipping global Codex skills"
fi

echo "== 5/6 personal skills + CLAUDE.md =="
mkdir -p "$HOME/.claude/skills"
cp -R "$repo/claude/skills/." "$HOME/.claude/skills/"
cp "$repo/claude/CLAUDE.md" "$HOME/.claude/CLAUDE.md"

echo "== 6/6 verify =="
tokless doctor
# warnings about drifted managed files are expected (tokless/impeccable touch shared configs)
ecc doctor || true

echo "Done. Restart agent sessions (Claude Code, Codex, OpenCode)."

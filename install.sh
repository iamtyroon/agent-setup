#!/usr/bin/env bash
# agent-setup installer (macOS / Linux)
set -euo pipefail
repo="$(cd "$(dirname "$0")" && pwd)"
codex_home="${CODEX_HOME:-$HOME/.codex}"
codex_available=0
if command -v codex >/dev/null 2>&1 || [ -d "$codex_home" ] || [ -n "${CODEX_HOME:-}" ]; then
  codex_available=1
fi
opencode_config_home="${OPENCODE_CONFIG_DIR:-$HOME/.config/opencode}"
opencode_available=0
if command -v opencode >/dev/null 2>&1 || [ -d "$opencode_config_home" ] || [ -d "$HOME/.opencode" ] || [ -n "${OPENCODE_CONFIG_DIR:-}" ]; then
  opencode_available=1
fi

echo "== 1/7 tokless =="
export PATH="$HOME/.local/bin:$PATH"
if command -v tokless >/dev/null; then
  echo "tokless present, skipping download (run 'tokless update' to upgrade)"
else
  curl -fsSL https://raw.githubusercontent.com/HoangP8/tokless/main/scripts/install.sh | CI=1 bash
fi

echo "== 2/7 ECC =="
npm install -g ecc-universal
ecc install --target claude --profile minimal
ecc install --target claude --profile core
[ "$codex_available" -eq 1 ] && ecc install --target codex --profile core
[ "$opencode_available" -eq 1 ] && ecc install --target opencode --profile opencode

echo "== 3/7 impeccable =="
npx -y impeccable install

# tokless wiring last: ECC/impeccable installs can overwrite agent MCP config
tokless --agents claude,opencode,codex,antigravity

echo "== 4/7 Codex skills =="
codex_skill_source="$repo/codex/skills"
codex_reference_source="$repo/codex/references"
if [ "$codex_available" -eq 1 ] && [ -d "$codex_skill_source" ]; then
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

  codex_config_source="$repo/.codex/config.toml"
  codex_sync_script="$repo/scripts/sync-codex-config.mjs"
  if [ -f "$codex_config_source" ] && [ -f "$codex_sync_script" ]; then
    node "$codex_sync_script" --source "$codex_config_source" --target "$codex_home/config.toml"
  fi

  codex_agent_source="$repo/.codex/agents"
  if [ -d "$codex_agent_source" ]; then
    codex_agent_destination="$codex_home/agents"
    mkdir -p "$codex_agent_destination"
    for agent_file in "$codex_agent_source"/*.toml; do
      [ -f "$agent_file" ] || continue
      agent_name="$(basename "$agent_file")"
      if [ ! -e "$codex_agent_destination/$agent_name" ]; then
        cp "$agent_file" "$codex_agent_destination/$agent_name"
      else
        echo "Preserving existing Codex agent role: $codex_agent_destination/$agent_name"
      fi
    done
  fi

  codex_global_instructions="$repo/codex/AGENTS.md"
  codex_global_destination="$codex_home/AGENTS.md"
  if [ -f "$codex_global_instructions" ] && [ ! -e "$codex_global_destination" ]; then
    cp "$codex_global_instructions" "$codex_global_destination"
  elif [ -e "$codex_global_destination" ]; then
    echo "Preserving existing Codex global AGENTS.md"
  fi
else
  echo "Codex not found, skipping global Codex skills"
fi

echo "== 5/7 OpenCode support =="
opencode_sync_script="$repo/scripts/sync-opencode.mjs"
opencode_skill_source="$repo/codex/skills"
opencode_agent_source="$repo/.opencode/agents"
if [ "$opencode_available" -eq 1 ] && [ -f "$opencode_sync_script" ] && [ -d "$opencode_skill_source" ]; then
  opencode_sync_args=(
    --target "$opencode_config_home"
    --skill-source "$opencode_skill_source"
    --agent-source "$opencode_agent_source"
    --replace-skills
  )
  if [ "$codex_available" -eq 1 ] && [ -d "$codex_home/.agents/skills" ]; then
    opencode_sync_args+=(--skill-source "$codex_home/.agents/skills")
  fi
  if [ "$codex_available" -eq 1 ] && [ -d "$codex_home/plugins/cache" ]; then
    opencode_sync_args+=(--skill-source "$codex_home/plugins/cache")
  fi
  if [ "$codex_available" -eq 1 ] && [ -d "$codex_home/agents" ]; then
    opencode_sync_args+=(--agent-source "$codex_home/agents")
  fi
  node "$opencode_sync_script" "${opencode_sync_args[@]}"
else
  echo "OpenCode not found, skipping OpenCode skill sync"
fi

echo "== 6/7 personal skills + CLAUDE.md =="
mkdir -p "$HOME/.claude/skills"
cp -R "$repo/claude/skills/." "$HOME/.claude/skills/"
cp "$repo/claude/CLAUDE.md" "$HOME/.claude/CLAUDE.md"

echo "== 7/7 verify =="
tokless doctor
# warnings about drifted managed files are expected (tokless/impeccable touch shared configs)
ecc doctor || true

echo "Done. Restart agent sessions (Claude Code, Codex, OpenCode)."

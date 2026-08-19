# agent-setup installer (Windows PowerShell 5.1+)
# Reproduces full AI-agent toolkit: tokless (caveman, ponytail, rtk, codegraph, context-mode),
# ECC, impeccable, plus personal skills and CLAUDE.md.
$ErrorActionPreference = "Stop"
$repo = $PSScriptRoot

Write-Host "== 1/5 tokless =="
$env:Path = "$env:LOCALAPPDATA\Programs\tokless;$env:Path"
if (Get-Command tokless -ErrorAction SilentlyContinue) {
    # already installed; binary may be locked by a running agent process
    Write-Host "tokless present, skipping download (run 'tokless update' to upgrade)"
} else {
    $env:CI = "1"
    irm https://raw.githubusercontent.com/HoangP8/tokless/main/scripts/install.ps1 | iex
}

Write-Host "== 2/5 ECC =="
npm install -g ecc-universal
ecc install --target claude --profile minimal
ecc install --target claude --profile core
if (Test-Path "$env:USERPROFILE\.codex")    { ecc install --target codex --profile core }
if (Test-Path "$env:USERPROFILE\.opencode") { ecc install --target opencode --profile opencode }

Write-Host "== 3/5 impeccable =="
npx -y impeccable install

# tokless wiring last: ECC/impeccable installs can overwrite agent MCP config
tokless --agents claude,opencode,codex,antigravity

Write-Host "== 4/6 Codex skills =="
$codexSkillSource = Join-Path $repo "codex\skills"
$codexReferenceSource = Join-Path $repo "codex\references"
$codexHome = $env:CODEX_HOME
if (-not $codexHome -and (Test-Path "$env:USERPROFILE\.codex")) {
    $codexHome = "$env:USERPROFILE\.codex"
}
if (-not $codexHome -and (Get-Command codex -ErrorAction SilentlyContinue)) {
    $codexHome = "$env:USERPROFILE\.codex"
}
if ($codexHome -and (Test-Path $codexSkillSource)) {
    $codexSkillDestination = Join-Path $codexHome ".agents\skills"
    New-Item -ItemType Directory -Force $codexSkillDestination | Out-Null
    Get-ChildItem -LiteralPath $codexSkillSource -Directory | ForEach-Object {
        $skillDestination = Join-Path $codexSkillDestination $_.Name
        New-Item -ItemType Directory -Force $skillDestination | Out-Null
        Get-ChildItem -LiteralPath $_.FullName -Force | Copy-Item -Recurse -Force -Destination $skillDestination
    }
    if (Test-Path $codexReferenceSource) {
        $codexReferenceDestination = Join-Path $codexHome ".agents\references"
        New-Item -ItemType Directory -Force $codexReferenceDestination | Out-Null
        Copy-Item -Recurse -Force "$codexReferenceSource\*" "$codexReferenceDestination\"
    }
} else {
    Write-Host "Codex not found, skipping global Codex skills"
}

Write-Host "== 5/6 personal skills + CLAUDE.md =="
New-Item -ItemType Directory -Force "$env:USERPROFILE\.claude\skills" | Out-Null
Copy-Item -Recurse -Force "$repo\claude\skills\*" "$env:USERPROFILE\.claude\skills\"
Copy-Item -Force "$repo\claude\CLAUDE.md" "$env:USERPROFILE\.claude\CLAUDE.md"

Write-Host "== 6/6 verify =="
tokless doctor
ecc doctor  # warnings about drifted managed files are expected (tokless/impeccable touch shared configs)

Write-Host "Done. Restart agent sessions (Claude Code, Codex, OpenCode)."
exit 0

# agent-setup installer (Windows PowerShell 5.1+)
# Reproduces full AI-agent toolkit: tokless (caveman, ponytail, rtk, codegraph, context-mode),
# ECC, impeccable, Codex, OpenCode, plus personal skills and CLAUDE.md.
$ErrorActionPreference = "Stop"
$repo = $PSScriptRoot
$codexHome = $env:CODEX_HOME
if (-not $codexHome) {
    $codexHome = Join-Path $env:USERPROFILE ".codex"
}
$codexAvailable = [bool](Get-Command codex -ErrorAction SilentlyContinue) -or
    (Test-Path -LiteralPath $codexHome) -or
    [bool]$env:CODEX_HOME
$opencodeConfigHome = $env:OPENCODE_CONFIG_DIR
if (-not $opencodeConfigHome) {
    $opencodeConfigHome = Join-Path $env:USERPROFILE ".config\opencode"
}
$opencodeAvailable = [bool](Get-Command opencode -ErrorAction SilentlyContinue) -or
    (Test-Path -LiteralPath $opencodeConfigHome) -or
    (Test-Path -LiteralPath (Join-Path $env:USERPROFILE ".opencode")) -or
    [bool]$env:OPENCODE_CONFIG_DIR

Write-Host "== 1/7 tokless =="
$env:Path = "$env:LOCALAPPDATA\Programs\tokless;$env:Path"
if (Get-Command tokless -ErrorAction SilentlyContinue) {
    # already installed; binary may be locked by a running agent process
    Write-Host "tokless present, skipping download (run 'tokless update' to upgrade)"
} else {
    $env:CI = "1"
    irm https://raw.githubusercontent.com/HoangP8/tokless/main/scripts/install.ps1 | iex
}

Write-Host "== 2/7 ECC =="
npm install -g ecc-universal
ecc install --target claude --profile minimal
ecc install --target claude --profile core
if ($codexAvailable) { ecc install --target codex --profile core }
if ($opencodeAvailable) { ecc install --target opencode --profile opencode }

Write-Host "== 3/7 impeccable =="
npx -y impeccable install

# tokless wiring last: ECC/impeccable installs can overwrite agent MCP config
tokless --agents claude,opencode,codex,antigravity

Write-Host "== 4/7 Codex skills =="
$codexSkillSource = Join-Path $repo "codex\skills"
$codexReferenceSource = Join-Path $repo "codex\references"
if ($codexAvailable -and (Test-Path $codexSkillSource)) {
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

    $codexConfigSource = Join-Path $repo ".codex\config.toml"
    $codexSyncScript = Join-Path $repo "scripts\sync-codex-config.mjs"
    if ((Test-Path $codexConfigSource) -and (Test-Path $codexSyncScript)) {
        & node $codexSyncScript --source $codexConfigSource --target (Join-Path $codexHome "config.toml")
        if ($LASTEXITCODE -ne 0) { throw "Codex config sync failed" }
    }

    $codexAgentSource = Join-Path $repo ".codex\agents"
    if (Test-Path $codexAgentSource) {
        $codexAgentDestination = Join-Path $codexHome "agents"
        New-Item -ItemType Directory -Force $codexAgentDestination | Out-Null
        Get-ChildItem -LiteralPath $codexAgentSource -File -Filter "*.toml" | ForEach-Object {
            $agentDestination = Join-Path $codexAgentDestination $_.Name
            if (-not (Test-Path -LiteralPath $agentDestination)) {
                Copy-Item -LiteralPath $_.FullName -Destination $agentDestination
            } else {
                Write-Host "Preserving existing Codex agent role: $agentDestination"
            }
        }
    }

    $codexGlobalInstructions = Join-Path $repo "codex\AGENTS.md"
    $codexGlobalDestination = Join-Path $codexHome "AGENTS.md"
    if ((Test-Path $codexGlobalInstructions) -and -not (Test-Path -LiteralPath $codexGlobalDestination)) {
        Copy-Item -LiteralPath $codexGlobalInstructions -Destination $codexGlobalDestination
    } elseif (Test-Path -LiteralPath $codexGlobalDestination) {
        Write-Host "Preserving existing Codex global AGENTS.md"
    }
} else {
    Write-Host "Codex not found, skipping global Codex skills"
}

Write-Host "== 5/7 OpenCode support =="
$opencodeSyncScript = Join-Path $repo "scripts\sync-opencode.mjs"
$opencodeSkillSource = Join-Path $repo "codex\skills"
$opencodeAgentSource = Join-Path $repo ".opencode\agents"
if ($opencodeAvailable -and (Test-Path $opencodeSyncScript) -and (Test-Path $opencodeSkillSource)) {
    $opencodeSyncArgs = @(
        "--target", $opencodeConfigHome,
        "--skill-source", $opencodeSkillSource,
        "--agent-source", $opencodeAgentSource,
        "--replace-skills"
    )
    if ($codexAvailable -and (Test-Path (Join-Path $codexHome ".agents\skills"))) {
        $opencodeSyncArgs += @("--skill-source", (Join-Path $codexHome ".agents\skills"))
    }
    if ($codexAvailable -and (Test-Path (Join-Path $codexHome "plugins\cache"))) {
        $opencodeSyncArgs += @("--skill-source", (Join-Path $codexHome "plugins\cache"))
    }
    if ($codexAvailable -and (Test-Path (Join-Path $codexHome "agents"))) {
        $opencodeSyncArgs += @("--agent-source", (Join-Path $codexHome "agents"))
    }
    & node $opencodeSyncScript @opencodeSyncArgs
    if ($LASTEXITCODE -ne 0) { throw "OpenCode sync failed" }
} else {
    Write-Host "OpenCode not found, skipping OpenCode skill sync"
}

Write-Host "== 6/7 personal skills + CLAUDE.md =="
New-Item -ItemType Directory -Force "$env:USERPROFILE\.claude\skills" | Out-Null
Copy-Item -Recurse -Force "$repo\claude\skills\*" "$env:USERPROFILE\.claude\skills\"
Copy-Item -Force "$repo\claude\CLAUDE.md" "$env:USERPROFILE\.claude\CLAUDE.md"

Write-Host "== 7/7 verify =="
tokless doctor
ecc doctor  # warnings about drifted managed files are expected (tokless/impeccable touch shared configs)

Write-Host "Done. Restart agent sessions (Claude Code, Codex, OpenCode)."
exit 0

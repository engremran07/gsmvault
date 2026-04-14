# .claude/hooks/pre-push-governance.ps1
# PreToolUse hook — verifies governance file counts before git push.
# Exit 0 always (non-blocking warning).

$ErrorActionPreference = "SilentlyContinue"

if ($env:CLAUDE_TOOL_NAME -notmatch "git_push") { exit 0 }

$projectRoot = $PSScriptRoot | Split-Path | Split-Path

$rulesDir = Join-Path $projectRoot ".claude\rules"
$skillsDir = Join-Path $projectRoot ".github\skills"
$agentsDir = Join-Path $projectRoot ".github\agents"

$rulesCount = (Get-ChildItem -Path $rulesDir -Filter "*.md" -ErrorAction SilentlyContinue | Measure-Object).Count
$skillsCount = (Get-ChildItem -Path $skillsDir -Directory -ErrorAction SilentlyContinue | Measure-Object).Count
$agentsCount = (Get-ChildItem -Path $agentsDir -Filter "*.md" -ErrorAction SilentlyContinue | Measure-Object).Count

$warn = $false
if ($rulesCount -lt 50) {
    Write-Host "`n[pre-push-governance] WARNING: Only $rulesCount rules (expected 50+)" -ForegroundColor Yellow
    $warn = $true
}
if ($skillsCount -lt 20) {
    Write-Host "[pre-push-governance] WARNING: Only $skillsCount skills (expected 20+)" -ForegroundColor Yellow
    $warn = $true
}
if ($agentsCount -lt 40) {
    Write-Host "[pre-push-governance] WARNING: Only $agentsCount agents (expected 40+)" -ForegroundColor Yellow
    $warn = $true
}

if (-not $warn) {
    Write-Host "[pre-push-governance] Governance counts OK (rules=$rulesCount, skills=$skillsCount, agents=$agentsCount)" -ForegroundColor Green
}

exit 0

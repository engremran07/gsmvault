# .claude/hooks/dependency-check.ps1
# PostToolUse hook — runs pip check when requirements.txt is modified.
# Exit 0 always (non-blocking).

$ErrorActionPreference = "SilentlyContinue"

if (-not $env:CLAUDE_FILE_PATHS) { exit 0 }

$reqModified = $env:CLAUDE_FILE_PATHS -split ';' | Where-Object {
    $_ -match 'requirements\.txt$'
}

if (-not $reqModified) { exit 0 }

$projectRoot = $PSScriptRoot | Split-Path | Split-Path
$pip = Join-Path $projectRoot ".venv\Scripts\pip.exe"

Write-Host "`n[dependency-check] requirements.txt changed — running pip check..." -ForegroundColor Cyan
$output = & $pip check 2>&1
if ($LASTEXITCODE -ne 0) {
    Write-Host "[dependency-check] WARNING: pip check found issues:" -ForegroundColor Yellow
    Write-Host $output -ForegroundColor Yellow
} else {
    Write-Host "[dependency-check] All dependencies consistent." -ForegroundColor Green
}

exit 0

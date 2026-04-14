# .claude/hooks/print-style-check.ps1
# PostToolUse hook — verifies print stylesheet exists and hides nav/footer.
# Exit 0 always (non-blocking).

$ErrorActionPreference = "SilentlyContinue"

if (-not $env:CLAUDE_FILE_PATHS) { exit 0 }

$cssEdited = $env:CLAUDE_FILE_PATHS -split ';' | Where-Object { $_ -match '\.(css|scss)$' }
if (-not $cssEdited) { exit 0 }

$projectRoot = $PSScriptRoot | Split-Path | Split-Path
$printFile = Join-Path $projectRoot "static\css\src\_print.scss"

if (-not (Test-Path $printFile)) {
    Write-Host "`n[print-style] WARNING: Print stylesheet missing at static/css/src/_print.scss" -ForegroundColor Yellow
    exit 0
}

$content = Get-Content -Path $printFile -Raw
$hidesNav = $content -match '@media\s+print' -and $content -match 'display\s*:\s*none'
if (-not $hidesNav) {
    Write-Host "[print-style] WARNING: Print stylesheet may not hide nav/footer elements." -ForegroundColor Yellow
}

exit 0

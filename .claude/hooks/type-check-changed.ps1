# .claude/hooks/type-check-changed.ps1
# PostToolUse hook — runs ruff on edited .py files for type-related issues.
# Exit 0 always (non-blocking).

$ErrorActionPreference = "SilentlyContinue"

if (-not $env:CLAUDE_FILE_PATHS) { exit 0 }

$pyFiles = $env:CLAUDE_FILE_PATHS -split ';' | Where-Object { $_ -match '\.py$' -and (Test-Path $_) }
if (-not $pyFiles) { exit 0 }

$projectRoot = $PSScriptRoot | Split-Path | Split-Path
$python = Join-Path $projectRoot ".venv\Scripts\python.exe"

foreach ($f in $pyFiles) {
    $output = & $python -m ruff check $f --select=UP,B,N --quiet 2>&1
    if ($output) {
        Write-Host "`n[type-check-changed] Issues in $f`:" -ForegroundColor Yellow
        Write-Host $output -ForegroundColor Yellow
    }
}

exit 0

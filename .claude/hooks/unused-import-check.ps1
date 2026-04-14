# .claude/hooks/unused-import-check.ps1
# PostToolUse hook — runs ruff on edited files for F401 (unused imports).
# Exit 0 always (non-blocking).

$ErrorActionPreference = "SilentlyContinue"

if (-not $env:CLAUDE_FILE_PATHS) { exit 0 }

$pyFiles = $env:CLAUDE_FILE_PATHS -split ';' | Where-Object { $_ -match '\.py$' -and (Test-Path $_) }
if (-not $pyFiles) { exit 0 }

$projectRoot = $PSScriptRoot | Split-Path | Split-Path
$python = Join-Path $projectRoot ".venv\Scripts\python.exe"

foreach ($f in $pyFiles) {
    $output = & $python -m ruff check $f --select=F401 --quiet 2>&1
    if ($output) {
        Write-Host "`n[unused-import] WARNING: Unused imports in $f`:" -ForegroundColor Yellow
        Write-Host $output -ForegroundColor Yellow
    }
}

exit 0

# .claude/hooks/god-file-check.ps1
# PostToolUse hook — warns if any edited .py file exceeds 500 lines.
# Exit 0 always (non-blocking).

$ErrorActionPreference = "SilentlyContinue"

if (-not $env:CLAUDE_FILE_PATHS) { exit 0 }

$pyFiles = $env:CLAUDE_FILE_PATHS -split ';' | Where-Object { $_ -match '\.py$' -and (Test-Path $_) }

foreach ($f in $pyFiles) {
    $lineCount = (Get-Content -Path $f | Measure-Object -Line).Lines
    if ($lineCount -gt 500) {
        Write-Host "`n[god-file] WARNING: $f has $lineCount lines (threshold: 500)" -ForegroundColor Yellow
        Write-Host "  Consider splitting into smaller modules." -ForegroundColor Yellow
    }
}

exit 0

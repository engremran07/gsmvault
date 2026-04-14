# .claude/hooks/session-end-summary.ps1
# PreStop hook — prints summary of session activity.
# Exit 0 always (non-blocking).

$ErrorActionPreference = "SilentlyContinue"

$projectRoot = $PSScriptRoot | Split-Path | Split-Path

Write-Host "`n[session-end-summary] Session ending — workspace summary:" -ForegroundColor Cyan

Push-Location $projectRoot
$status = git status --short 2>$null
Pop-Location

if ($status) {
    $modCount = ($status | Measure-Object).Count
    Write-Host "  Modified/new files: $modCount" -ForegroundColor White
    $status | Select-Object -First 15 | ForEach-Object {
        Write-Host "    $_" -ForegroundColor Gray
    }
    if ($modCount -gt 15) {
        Write-Host "    ... and $($modCount - 15) more" -ForegroundColor Gray
    }
} else {
    Write-Host "  Working tree clean — no uncommitted changes." -ForegroundColor Green
}

exit 0

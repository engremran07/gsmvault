# .claude/hooks/regression-check.ps1
# PostToolUse hook — checks REGRESSION_REGISTRY.md for OPEN entries.
# Exit 0 always (non-blocking).

$ErrorActionPreference = "SilentlyContinue"

$projectRoot = $PSScriptRoot | Split-Path | Split-Path
$regFile = Join-Path $projectRoot "REGRESSION_REGISTRY.md"

if (-not (Test-Path $regFile)) { exit 0 }

$openEntries = Select-String -Path $regFile -Pattern '\|\s*OPEN\s*\|' -AllMatches
$count = ($openEntries | Measure-Object).Count

if ($count -gt 0) {
    Write-Host "`n[regression-check] WARNING: $count OPEN regression(s) in REGRESSION_REGISTRY.md" -ForegroundColor Yellow
    $openEntries | Select-Object -First 5 | ForEach-Object {
        Write-Host "  $($_.Line.Trim())" -ForegroundColor Yellow
    }
}

exit 0

# .claude/hooks/url-namespace-check.ps1
# PostToolUse hook — scans edited urls.py for missing app_name variable.
# Exit 0 always (non-blocking).

$ErrorActionPreference = "SilentlyContinue"

if (-not $env:CLAUDE_FILE_PATHS) { exit 0 }

$urlFiles = $env:CLAUDE_FILE_PATHS -split ';' | Where-Object {
    $_ -match 'apps[\\/][^\\/]+[\\/]urls\.py$' -and (Test-Path $_)
}

foreach ($f in $urlFiles) {
    $hasAppName = Select-String -Path $f -Pattern 'app_name\s*=' -Quiet
    if (-not $hasAppName) {
        Write-Host "`n[url-namespace] WARNING: $f missing 'app_name' variable." -ForegroundColor Yellow
        Write-Host "  Every app's urls.py should define app_name for URL namespacing." -ForegroundColor Yellow
    }
}

exit 0

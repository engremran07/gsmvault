# .claude/hooks/import-boundary.ps1
# PostToolUse hook — scans models.py/services*.py for forbidden cross-app imports.
# Exit 0 always (non-blocking).

$ErrorActionPreference = "SilentlyContinue"

if (-not $env:CLAUDE_FILE_PATHS) { exit 0 }

$targets = $env:CLAUDE_FILE_PATHS -split ';' | Where-Object {
    $_ -match 'apps[\\/][^\\/]+[\\/](models|services\w*)\.py$'
}

foreach ($f in $targets) {
    if (-not (Test-Path $f)) { continue }
    $appName = if ($f -match 'apps[\\/]([^\\/]+)[\\/]') { $Matches[1] } else { "" }
    if (-not $appName) { continue }

    $lines = Select-String -Path $f -Pattern 'from apps\.(\w+)' -AllMatches
    foreach ($line in $lines) {
        foreach ($m in $line.Matches) {
            $imported = $m.Groups[1].Value
            if ($imported -eq $appName) { continue }
            if ($imported -in @("core", "site_settings", "consent")) { continue }
            if ($imported -eq "users" -and $line.Line -match 'AUTH_USER_MODEL|User') { continue }
            Write-Host "`n[import-boundary] WARNING: $($f):$($line.LineNumber)" -ForegroundColor Yellow
            Write-Host "  apps.$appName imports from apps.$imported — possible boundary violation" -ForegroundColor Yellow
        }
    }
}

exit 0

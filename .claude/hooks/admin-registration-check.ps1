# .claude/hooks/admin-registration-check.ps1
# PostToolUse hook — checks if new models in models.py are registered in admin.py.
# Exit 0 always (non-blocking).

$ErrorActionPreference = "SilentlyContinue"

if (-not $env:CLAUDE_FILE_PATHS) { exit 0 }

$modelFiles = $env:CLAUDE_FILE_PATHS -split ';' | Where-Object {
    $_ -match 'apps[\\/][^\\/]+[\\/]models\.py$' -and (Test-Path $_)
}

foreach ($f in $modelFiles) {
    $appDir = Split-Path $f
    $adminFile = Join-Path $appDir "admin.py"
    if (-not (Test-Path $adminFile)) { continue }

    $modelContent = Get-Content -Path $f -Raw
    $adminContent = Get-Content -Path $adminFile -Raw

    $classes = [regex]::Matches($modelContent, 'class\s+(\w+)\s*\([^)]*models\.Model')
    foreach ($cls in $classes) {
        $name = $cls.Groups[1].Value
        if ($adminContent -notmatch $name) {
            Write-Host "[admin-registration] WARNING: Model '$name' not found in $adminFile" -ForegroundColor Yellow
        }
    }
}

exit 0

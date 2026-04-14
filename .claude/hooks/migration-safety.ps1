# .claude/hooks/migration-safety.ps1
# PostToolUse hook — warns when migration files are manually edited.
# Exit 0 always (non-blocking).

$ErrorActionPreference = "SilentlyContinue"

if (-not $env:CLAUDE_FILE_PATHS) { exit 0 }

$migrationFiles = $env:CLAUDE_FILE_PATHS -split ';' | Where-Object {
    $_ -match 'apps[\\/][^\\/]+[\\/]migrations[\\/]\d{4}_.*\.py$'
}

if ($migrationFiles) {
    Write-Host "`n[migration-safety] WARNING: Migration file(s) were manually edited:" -ForegroundColor Yellow
    foreach ($f in $migrationFiles) {
        Write-Host "  - $f" -ForegroundColor Yellow
    }
    Write-Host "  Manual migration edits are risky. Use 'manage.py makemigrations' instead." -ForegroundColor Yellow
}

exit 0

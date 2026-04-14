# .claude/hooks/performance-hook.ps1
# PostToolUse hook — scans edited .py files for queryset patterns missing optimization.
# Exit 0 always (non-blocking).

$ErrorActionPreference = "SilentlyContinue"

if (-not $env:CLAUDE_FILE_PATHS) { exit 0 }

$pyFiles = $env:CLAUDE_FILE_PATHS -split ';' | Where-Object { $_ -match '\.py$' -and (Test-Path $_) }

foreach ($f in $pyFiles) {
    $lines = Select-String -Path $f -Pattern '\.objects\.all\(\)' -AllMatches
    foreach ($line in $lines) {
        $ctx = $line.Line
        if ($ctx -notmatch 'select_related|prefetch_related|only\(|defer\(|values\(|[:]\d|pagina|first\(\)|count\(\)|exists\(\)|aggregate') {
            Write-Host "[performance] WARNING: $($f):$($line.LineNumber) — .objects.all() without optimization" -ForegroundColor Yellow
            Write-Host "  Consider select_related/prefetch_related, pagination, or .only()/.defer()." -ForegroundColor Yellow
        }
    }
}

exit 0

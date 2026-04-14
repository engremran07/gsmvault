# .claude/hooks/related-name-check.ps1
# PostToolUse hook — scans edited models.py for FK/M2M without related_name.
# Exit 0 always (non-blocking).

$ErrorActionPreference = "SilentlyContinue"

if (-not $env:CLAUDE_FILE_PATHS) { exit 0 }

$modelFiles = $env:CLAUDE_FILE_PATHS -split ';' | Where-Object {
    $_ -match 'models\.py$' -and (Test-Path $_)
}

foreach ($f in $modelFiles) {
    $lines = Select-String -Path $f -Pattern '(ForeignKey|ManyToManyField|OneToOneField)\(' -AllMatches
    foreach ($line in $lines) {
        if ($line.Line -notmatch 'related_name\s*=') {
            Write-Host "[related-name] WARNING: $($f):$($line.LineNumber) — FK/M2M missing related_name" -ForegroundColor Yellow
            $trimmed = $line.Line.Trim().Substring(0, [Math]::Min(80, $line.Line.Trim().Length))
            Write-Host "  $trimmed" -ForegroundColor Gray
        }
    }
}

exit 0

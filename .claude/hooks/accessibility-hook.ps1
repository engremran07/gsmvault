# .claude/hooks/accessibility-hook.ps1
# PostToolUse hook — scans edited templates for images missing alt attributes.
# Exit 0 always (non-blocking).

$ErrorActionPreference = "SilentlyContinue"

if (-not $env:CLAUDE_FILE_PATHS) { exit 0 }

$templates = $env:CLAUDE_FILE_PATHS -split ';' | Where-Object {
    $_ -match '\.html$' -and (Test-Path $_)
}

foreach ($f in $templates) {
    $lines = Select-String -Path $f -Pattern '<img\s' -AllMatches
    foreach ($line in $lines) {
        if ($line.Line -notmatch '\balt\s*=') {
            Write-Host "[accessibility] WARNING: $($f):$($line.LineNumber) — <img> missing alt attribute" -ForegroundColor Yellow
        }
    }
}

exit 0

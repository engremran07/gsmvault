# .claude/hooks/alpine-cloak-check.ps1
# PostToolUse hook — scans edited templates for x-show/x-if without x-cloak.
# Exit 0 always (non-blocking).

$ErrorActionPreference = "SilentlyContinue"

if (-not $env:CLAUDE_FILE_PATHS) { exit 0 }

$templates = $env:CLAUDE_FILE_PATHS -split ';' | Where-Object {
    $_ -match '\.html$' -and (Test-Path $_)
}

foreach ($f in $templates) {
    $lines = Select-String -Path $f -Pattern 'x-show\s*=|x-if\s*=' -AllMatches
    foreach ($line in $lines) {
        if ($line.Line -notmatch 'x-cloak') {
            Write-Host "[alpine-cloak] WARNING: $($f):$($line.LineNumber) — x-show/x-if without x-cloak (FOUC risk)" -ForegroundColor Yellow
        }
    }
}

exit 0

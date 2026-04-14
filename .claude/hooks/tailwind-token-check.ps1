# .claude/hooks/tailwind-token-check.ps1
# PostToolUse hook — scans templates for hardcoded text-white/text-black on accent backgrounds.
# Exit 0 always (non-blocking).

$ErrorActionPreference = "SilentlyContinue"

if (-not $env:CLAUDE_FILE_PATHS) { exit 0 }

$templates = $env:CLAUDE_FILE_PATHS -split ';' | Where-Object {
    $_ -match '\.html$' -and (Test-Path $_)
}

foreach ($f in $templates) {
    $lines = Select-String -Path $f -Pattern 'bg-accent.*text-(white|black)|bg-\[var\(--color-accent\)\].*text-(white|black)' -AllMatches
    foreach ($line in $lines) {
        Write-Host "[tailwind-token] WARNING: $($f):$($line.LineNumber) — hardcoded text color on accent bg" -ForegroundColor Yellow
        Write-Host "  Use 'text-[var(--color-accent-text)]' instead of text-white/text-black." -ForegroundColor Yellow
    }
}

exit 0

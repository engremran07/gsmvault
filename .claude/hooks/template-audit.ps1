# .claude/hooks/template-audit.ps1
# PostToolUse hook — scans edited HTML templates in fragments/ for {% extends %}.
# Exit 0 always (non-blocking).

$ErrorActionPreference = "SilentlyContinue"

if (-not $env:CLAUDE_FILE_PATHS) { exit 0 }

$fragments = $env:CLAUDE_FILE_PATHS -split ';' | Where-Object {
    $_ -match 'fragments[\\/].*\.html$'
}

foreach ($f in $fragments) {
    if (Test-Path $f) {
        $match = Select-String -Path $f -Pattern '\{%\s*extends\s' -Quiet
        if ($match) {
            Write-Host "`n[template-audit] WARNING: Fragment uses {%% extends %%}: $f" -ForegroundColor Yellow
            Write-Host "  HTMX fragments must be standalone — no {%% extends %%} allowed." -ForegroundColor Yellow
        }
    }
}

exit 0

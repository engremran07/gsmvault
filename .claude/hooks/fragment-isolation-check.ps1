# .claude/hooks/fragment-isolation-check.ps1
# PostToolUse hook — verifies fragment templates don't use {% block %} tags.
# Exit 0 always (non-blocking).

$ErrorActionPreference = "SilentlyContinue"

if (-not $env:CLAUDE_FILE_PATHS) { exit 0 }

$fragments = $env:CLAUDE_FILE_PATHS -split ';' | Where-Object {
    $_ -match 'fragments[\\/].*\.html$' -and (Test-Path $_)
}

foreach ($f in $fragments) {
    $hasBlock = Select-String -Path $f -Pattern '\{%\s*block\s' -Quiet
    if ($hasBlock) {
        Write-Host "`n[fragment-isolation] WARNING: Fragment $f uses {%% block %%} tags." -ForegroundColor Yellow
        Write-Host "  Fragments are standalone snippets — they should not define blocks." -ForegroundColor Yellow
    }
}

exit 0

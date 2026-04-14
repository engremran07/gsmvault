# .claude/hooks/template-extends-check.ps1
# PostToolUse hook — ensures non-fragment templates have {% extends %}.
# Exit 0 always (non-blocking).

$ErrorActionPreference = "SilentlyContinue"

if (-not $env:CLAUDE_FILE_PATHS) { exit 0 }

$templates = $env:CLAUDE_FILE_PATHS -split ';' | Where-Object {
    $_ -match '\.html$' -and $_ -notmatch 'fragments[\\/]' -and $_ -notmatch 'components[\\/]' -and (Test-Path $_)
}

foreach ($f in $templates) {
    # Skip partials (starting with _) and base templates
    $name = Split-Path $f -Leaf
    if ($name.StartsWith('_') -or $name -eq 'base.html') { continue }
    if ($f -match 'base[\\/]') { continue }

    $hasExtends = Select-String -Path $f -Pattern '\{%\s*extends\s' -Quiet
    if (-not $hasExtends) {
        Write-Host "[template-extends] WARNING: $f is a page template without {%% extends %%}" -ForegroundColor Yellow
    }
}

exit 0

# .claude/hooks/htmx-csrf-check.ps1
# PostToolUse hook — verifies base.html still has global hx-headers CSRF.
# Exit 0 always (non-blocking).

$ErrorActionPreference = "SilentlyContinue"

$projectRoot = $PSScriptRoot | Split-Path | Split-Path
$baseHtml = Join-Path $projectRoot "templates\base\base.html"

if (-not (Test-Path $baseHtml)) { exit 0 }

# Only run if base.html was edited or on relevant template edits
if ($env:CLAUDE_FILE_PATHS) {
    $relevant = $env:CLAUDE_FILE_PATHS -split ';' | Where-Object { $_ -match 'base[\\/]base\.html$' }
    if (-not $relevant) { exit 0 }
}

$hasHxHeaders = Select-String -Path $baseHtml -Pattern 'hx-headers.*csrf' -Quiet
if (-not $hasHxHeaders) {
    Write-Host "`n[htmx-csrf] WARNING: base.html missing global hx-headers CSRF token." -ForegroundColor Yellow
    Write-Host '  <body> should have: hx-headers=''{"X-CSRFToken": "{{ csrf_token }}"}''' -ForegroundColor Yellow
}

exit 0

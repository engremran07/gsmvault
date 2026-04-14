# .claude/hooks/csrf-audit-hook.ps1
# PostToolUse hook — scans edited HTML templates for <form> tags missing {% csrf_token %}.
# Exit 0 always (non-blocking).

$ErrorActionPreference = "SilentlyContinue"

if (-not $env:CLAUDE_FILE_PATHS) { exit 0 }

$templates = $env:CLAUDE_FILE_PATHS -split ';' | Where-Object {
    $_ -match '\.html$' -and (Test-Path $_)
}

foreach ($f in $templates) {
    $content = Get-Content -Path $f -Raw
    if (-not $content) { continue }

    $formMatches = [regex]::Matches($content, '(?si)<form[^>]*method\s*=\s*["\x27]post["\x27][^>]*>.*?</form>')
    foreach ($form in $formMatches) {
        if ($form.Value -notmatch '\{%\s*csrf_token\s*%\}') {
            Write-Host "`n[csrf-audit] WARNING: POST form in $f missing {%% csrf_token %%}" -ForegroundColor Yellow
        }
    }
}

exit 0

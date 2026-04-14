# .claude/hooks/xss-audit-hook.ps1
# PostToolUse hook — checks edited models/services for HTML handling without sanitization.
# Exit 0 always (non-blocking).

$ErrorActionPreference = "SilentlyContinue"

if (-not $env:CLAUDE_FILE_PATHS) { exit 0 }

$targets = $env:CLAUDE_FILE_PATHS -split ';' | Where-Object {
    $_ -match '(models|services\w*)\.py$' -and (Test-Path $_)
}

foreach ($f in $targets) {
    $hasHtml = Select-String -Path $f -Pattern 'html|markup|rich_text|content.*text|body.*field' -Quiet
    if (-not $hasHtml) { continue }

    $hasSanitize = Select-String -Path $f -Pattern 'sanitize_html|sanitize_ad_code|nh3|bleach' -Quiet
    if (-not $hasSanitize) {
        Write-Host "`n[xss-audit] WARNING: $f handles HTML but has no sanitization import." -ForegroundColor Yellow
        Write-Host "  Use apps.core.sanitizers.sanitize_html_content() for XSS prevention." -ForegroundColor Yellow
    }
}

exit 0

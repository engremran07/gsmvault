# .claude/hooks/secrets-scan-enhanced.ps1
# PostToolUse hook — enhanced scan of edited files for secret patterns.
# Exit 0 always (non-blocking warning).

$ErrorActionPreference = "SilentlyContinue"

if (-not $env:CLAUDE_FILE_PATHS) { exit 0 }

$files = $env:CLAUDE_FILE_PATHS -split ';' | Where-Object { Test-Path $_ }
if (-not $files) { exit 0 }

$patterns = @(
    'AKIA[0-9A-Z]{16}',
    'sk-[a-zA-Z0-9]{20,}',
    'ghp_[a-zA-Z0-9]{36}',
    'password\s*=\s*["\x27][^"\x27]{4,}',
    'api[_-]?key\s*=\s*["\x27][^"\x27]{8,}',
    'secret[_-]?key\s*=\s*["\x27][^"\x27]{8,}',
    'token\s*=\s*["\x27][a-zA-Z0-9\-_.]{20,}'
)

$combined = $patterns -join '|'

foreach ($f in $files) {
    if ($f -match '\.(pyc|png|jpg|gif|ico|woff|ttf)$') { continue }
    $hits = Select-String -Path $f -Pattern $combined -AllMatches
    foreach ($hit in $hits) {
        if ($hit.Line -match '^\s*#' -or $hit.Line -match 'example|placeholder|xxx|changeme') { continue }
        Write-Host "`n[secrets-scan-enhanced] WARNING: Possible secret in $($f):$($hit.LineNumber)" -ForegroundColor Yellow
        Write-Host "  $($hit.Line.Trim().Substring(0, [Math]::Min(80, $hit.Line.Trim().Length)))..." -ForegroundColor Yellow
    }
}

exit 0

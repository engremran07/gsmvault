# .claude/hooks/dead-code-check.ps1
# PostToolUse hook — scans for common dead code patterns.
# Exit 0 always (non-blocking).

$ErrorActionPreference = "SilentlyContinue"

if (-not $env:CLAUDE_FILE_PATHS) { exit 0 }

$pyFiles = $env:CLAUDE_FILE_PATHS -split ';' | Where-Object { $_ -match '\.py$' -and (Test-Path $_) }

foreach ($f in $pyFiles) {
    # Check for large commented-out code blocks (3+ consecutive lines starting with #)
    $lines = Get-Content -Path $f
    $commentRun = 0
    for ($i = 0; $i -lt $lines.Count; $i++) {
        if ($lines[$i] -match '^\s*#\s*(def |class |import |from |if |for |return )') {
            $commentRun++
        } else {
            if ($commentRun -ge 3) {
                Write-Host "[dead-code] WARNING: $($f):$($i - $commentRun + 1) — $commentRun lines of commented-out code" -ForegroundColor Yellow
            }
            $commentRun = 0
        }
    }
    if ($commentRun -ge 3) {
        Write-Host "[dead-code] WARNING: $($f):$($lines.Count - $commentRun + 1) — $commentRun lines of commented-out code" -ForegroundColor Yellow
    }
}

exit 0

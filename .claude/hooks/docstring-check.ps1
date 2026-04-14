# .claude/hooks/docstring-check.ps1
# PostToolUse hook — scans edited service files for public functions missing docstrings.
# Exit 0 always (non-blocking).

$ErrorActionPreference = "SilentlyContinue"

if (-not $env:CLAUDE_FILE_PATHS) { exit 0 }

$serviceFiles = $env:CLAUDE_FILE_PATHS -split ';' | Where-Object {
    $_ -match 'services\w*\.py$' -and (Test-Path $_)
}

foreach ($f in $serviceFiles) {
    $lines = Get-Content -Path $f
    for ($i = 0; $i -lt $lines.Count; $i++) {
        if ($lines[$i] -match '^\s*def\s+([a-zA-Z][a-zA-Z0-9_]*)\s*\(' -and $lines[$i] -notmatch '^\s*def\s+_') {
            $funcName = $Matches[1]
            $nextLine = if ($i + 1 -lt $lines.Count) { $lines[$i + 1] } else { "" }
            $nextNext = if ($i + 2 -lt $lines.Count) { $lines[$i + 2] } else { "" }
            if ($nextLine -notmatch '"""' -and $nextNext -notmatch '"""') {
                Write-Host "[docstring-check] WARNING: $($f):$($i+1) — '$funcName()' missing docstring" -ForegroundColor Yellow
            }
        }
    }
}

exit 0

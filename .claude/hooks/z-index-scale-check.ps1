# .claude/hooks/z-index-scale-check.ps1
# PostToolUse hook — scans CSS/SCSS for arbitrary z-index values not following scale.
# Exit 0 always (non-blocking).

$ErrorActionPreference = "SilentlyContinue"

if (-not $env:CLAUDE_FILE_PATHS) { exit 0 }

$cssFiles = $env:CLAUDE_FILE_PATHS -split ';' | Where-Object {
    $_ -match '\.(css|scss)$' -and (Test-Path $_)
}

$validZIndex = @('0', '1', '10', '20', '30', '40', '50', '100', '999', '9999', 'auto', '-1')

foreach ($f in $cssFiles) {
    $lines = Select-String -Path $f -Pattern 'z-index\s*:\s*(\S+)' -AllMatches
    foreach ($line in $lines) {
        foreach ($m in $line.Matches) {
            $val = $m.Groups[1].Value.TrimEnd(';')
            if ($val -notin $validZIndex) {
                Write-Host "[z-index-scale] WARNING: $($f):$($line.LineNumber) — non-standard z-index: $val" -ForegroundColor Yellow
            }
        }
    }
}

exit 0

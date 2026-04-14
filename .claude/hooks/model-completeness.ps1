# .claude/hooks/model-completeness.ps1
# PostToolUse hook — scans edited models.py for classes missing Meta, __str__, or key Meta fields.
# Exit 0 always (non-blocking).

$ErrorActionPreference = "SilentlyContinue"

if (-not $env:CLAUDE_FILE_PATHS) { exit 0 }

$modelFiles = $env:CLAUDE_FILE_PATHS -split ';' | Where-Object {
    $_ -match 'models\.py$' -and (Test-Path $_)
}

foreach ($f in $modelFiles) {
    $content = Get-Content -Path $f -Raw
    if (-not $content) { continue }

    $classes = [regex]::Matches($content, 'class\s+(\w+)\s*\([^)]*models\.Model[^)]*\)')
    foreach ($cls in $classes) {
        $name = $cls.Groups[1].Value
        $afterClass = $content.Substring($cls.Index)
        $nextClass = [regex]::Match($afterClass.Substring(10), 'class\s+\w+\s*\(')
        $block = if ($nextClass.Success) { $afterClass.Substring(0, $nextClass.Index + 10) } else { $afterClass }

        if ($block -notmatch 'class\s+Meta\s*:') {
            Write-Host "[model-completeness] WARNING: $name in $f missing 'class Meta'" -ForegroundColor Yellow
        }
        if ($block -notmatch 'def\s+__str__\s*\(') {
            Write-Host "[model-completeness] WARNING: $name in $f missing '__str__'" -ForegroundColor Yellow
        }
    }
}

exit 0

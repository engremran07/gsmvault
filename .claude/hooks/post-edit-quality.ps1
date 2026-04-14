# .claude/hooks/post-edit-quality.ps1
# PostToolUse hook — runs ruff lint + format on every edited file immediately.
# Non-blocking: always exits 0. Per-file enforcement keeps feedback fast.
#
# Claude Code passes edited file paths via CLAUDE_FILE_PATHS env var (space-separated).

$ErrorActionPreference = "SilentlyContinue"

$python = Join-Path $PSScriptRoot "..\..\\.venv\Scripts\python.exe"
if (-not (Test-Path $python)) {
    $python = "python"
}

$filePaths = $env:CLAUDE_FILE_PATHS
if ([string]::IsNullOrWhiteSpace($filePaths)) {
    exit 0
}

# Only process Python files
$pyFiles = $filePaths -split " " | Where-Object { $_ -match "\.py$" -and (Test-Path $_) }
if ($pyFiles.Count -eq 0) {
    exit 0
}

foreach ($file in $pyFiles) {
    # Skip migrations — never auto-edit them
    if ($file -match "migrations[/\\]") {
        continue
    }
    & $python -m ruff check $file --fix --quiet 2>$null
    & $python -m ruff format $file --quiet 2>$null
}

exit 0

# .claude/hooks/pre-commit-quality.ps1
# PreToolUse hook — runs ruff check + ruff format + manage.py check before git commit.
# Exit 1 to block commit if any quality check fails.

$ErrorActionPreference = "SilentlyContinue"

if ($env:CLAUDE_TOOL_NAME -notmatch "git_commit|git_add_or_commit") { exit 0 }
if ($env:CLAUDE_TOOL_INPUT -notmatch '"commit"') { exit 0 }

$projectRoot = $PSScriptRoot | Split-Path | Split-Path
$python = Join-Path $projectRoot ".venv\Scripts\python.exe"

Write-Host "`n[pre-commit-quality] Running quality gate..." -ForegroundColor Cyan

$failed = $false

& $python -m ruff check $projectRoot --quiet 2>$null
if ($LASTEXITCODE -ne 0) {
    Write-Host "[FAIL] ruff check found issues" -ForegroundColor Red
    $failed = $true
}

& $python -m ruff format --check $projectRoot --quiet 2>$null
if ($LASTEXITCODE -ne 0) {
    Write-Host "[FAIL] ruff format found unformatted files" -ForegroundColor Red
    $failed = $true
}

& $python (Join-Path $projectRoot "manage.py") check --settings=app.settings_dev 2>$null
if ($LASTEXITCODE -ne 0) {
    Write-Host "[FAIL] manage.py check failed" -ForegroundColor Red
    $failed = $true
}

if ($failed) {
    Write-Host "[pre-commit-quality] BLOCKED — fix issues before committing." -ForegroundColor Red
    exit 1
}

Write-Host "[pre-commit-quality] All checks passed." -ForegroundColor Green
exit 0

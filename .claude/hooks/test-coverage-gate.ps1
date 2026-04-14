# .claude/hooks/test-coverage-gate.ps1
# PreToolUse hook — checks if test coverage is acceptable before git commit.
# Exit 0 always (non-blocking warning).

$ErrorActionPreference = "SilentlyContinue"

if ($env:CLAUDE_TOOL_NAME -notmatch "git_commit|git_add_or_commit") { exit 0 }
if ($env:CLAUDE_TOOL_INPUT -notmatch '"commit"') { exit 0 }

$projectRoot = $PSScriptRoot | Split-Path | Split-Path
$python = Join-Path $projectRoot ".venv\Scripts\python.exe"

$hasPytestCov = & $python -m pip show pytest-cov 2>$null
if (-not $hasPytestCov) {
    Write-Host "`n[test-coverage-gate] WARNING: pytest-cov not installed — coverage unknown." -ForegroundColor Yellow
    exit 0
}

$coverageFile = Join-Path $projectRoot ".coverage"
if (-not (Test-Path $coverageFile)) {
    Write-Host "`n[test-coverage-gate] WARNING: No .coverage file found — run pytest --cov first." -ForegroundColor Yellow
}

exit 0

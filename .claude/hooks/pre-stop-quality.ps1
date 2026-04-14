# .claude/hooks/pre-stop-quality.ps1
# TaskCompleted hook — full quality gate before Claude stops work.
# Exit 2 to signal Claude to keep working and fix issues.
# Exit 0 when all checks pass.

$ErrorActionPreference = "Continue"

$projectRoot = $PSScriptRoot | Split-Path | Split-Path
$python = Join-Path $projectRoot ".venv\Scripts\python.exe"
if (-not (Test-Path $python)) {
    $python = "python"
}

Push-Location $projectRoot

Write-Host ""
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "  Quality Gate — Pre-Stop Check" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan

$failed = $false

# Step 1: ruff lint
Write-Host "`n[1/3] Ruff lint..." -ForegroundColor Yellow
& $python -m ruff check . --fix --quiet
if ($LASTEXITCODE -ne 0) {
    Write-Host "  FAIL: Ruff lint found issues." -ForegroundColor Red
    $failed = $true
} else {
    Write-Host "  PASS" -ForegroundColor Green
}

# Step 2: ruff format check
Write-Host "[2/3] Ruff format..." -ForegroundColor Yellow
& $python -m ruff format . --quiet
if ($LASTEXITCODE -ne 0) {
    Write-Host "  FAIL: Ruff format found issues." -ForegroundColor Red
    $failed = $true
} else {
    Write-Host "  PASS" -ForegroundColor Green
}

# Step 3: Django system check
Write-Host "[3/3] Django system check..." -ForegroundColor Yellow
& $python manage.py check --settings=app.settings_dev 2>&1 | Out-String -OutVariable djangoOutput | Out-Null
Write-Host $djangoOutput
if ($LASTEXITCODE -ne 0) {
    Write-Host "  FAIL: Django check found issues." -ForegroundColor Red
    $failed = $true
} else {
    Write-Host "  PASS" -ForegroundColor Green
}

Pop-Location

if ($failed) {
    Write-Host ""
    Write-Host "Quality gate FAILED. Fix all issues before completing the task." -ForegroundColor Red
    Write-Host "Re-run: ruff check . --fix ; ruff format . ; manage.py check --settings=app.settings_dev" -ForegroundColor Yellow
    exit 2
}

Write-Host ""
Write-Host "Quality gate PASSED." -ForegroundColor Green
exit 0

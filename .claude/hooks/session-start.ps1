# .claude/hooks/session-start.ps1
# UserPromptSubmit hook — injects project context at session start.
# Prints diagnostic info so Claude knows the environment on first prompt.

$ErrorActionPreference = "SilentlyContinue"

$projectRoot = $PSScriptRoot | Split-Path | Split-Path
$python = Join-Path $projectRoot ".venv\Scripts\python.exe"

# Count agents and skills available
$agentCount = (Get-ChildItem -Path (Join-Path $projectRoot ".github\agents") -Filter "*.agent.md" -ErrorAction SilentlyContinue).Count
$claudeAgentCount = (Get-ChildItem -Path (Join-Path $projectRoot ".claude\agents") -Filter "*.md" -ErrorAction SilentlyContinue).Count
$skillCount = (Get-ChildItem -Path (Join-Path $projectRoot ".github\skills") -Directory -ErrorAction SilentlyContinue).Count

# Set env vars for this session
$env:PROJECT_ROOT = $projectRoot
$env:DJANGO_SETTINGS_MODULE = "app.settings_dev"
$env:PYTHONDONTWRITEBYTECODE = "1"

Write-Host ""
Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor Cyan
Write-Host "  GSMFWs — Django 5.2 Firmware Distribution Platform" -ForegroundColor Cyan
Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor Cyan
Write-Host "  Project root : $projectRoot" -ForegroundColor Gray
Write-Host "  Python       : $python ($(& $python --version 2>&1))" -ForegroundColor Gray
Write-Host "  Django       : dev settings (app.settings_dev)" -ForegroundColor Gray
Write-Host "  VS Code agents : $agentCount  |  Claude agents: $claudeAgentCount  |  Skills: $skillCount" -ForegroundColor Gray
Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor Cyan
Write-Host ""
Write-Host "Quality gate: ruff check . --fix ; ruff format . ; manage.py check --settings=app.settings_dev" -ForegroundColor DarkGray
Write-Host "Spawn agents: /agents | New app: /new-app <name> | Full audit: /audit | PR prep: /pr" -ForegroundColor DarkGray
Write-Host ""

exit 0

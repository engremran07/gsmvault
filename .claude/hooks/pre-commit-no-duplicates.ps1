# .claude/hooks/pre-commit-no-duplicates.ps1
# PreCommit hook — blocks commits that introduce versioned/duplicate files.
# Scans staged files for forbidden naming patterns.

$ErrorActionPreference = "SilentlyContinue"

$root = $PSScriptRoot | Split-Path | Split-Path

# Patterns that indicate versioned or duplicate files
$forbiddenPatterns = @(
    "_v\d+\.(py|html|js|css|scss|md)$",
    "_new\.(py|html|js|css|scss|md)$",
    "_old\.(py|html|js|css|scss|md)$",
    "_backup\.(py|html|js|css|scss|md)$",
    "_copy\.(py|html|js|css|scss|md)$",
    "_updated\.(py|html|js|css|scss|md)$",
    "_refactored\.(py|html|js|css|scss|md)$",
    "_improved\.(py|html|js|css|scss|md)$",
    "_clean\.(py|html|js|css|scss|md)$",
    "_original\.(py|html|js|css|scss|md)$"
)

# Exemptions (settings splits, migrations, changelogs)
$exemptions = @(
    "settings_dev\.py$",
    "settings_production\.py$",
    "migrations[/\\]",
    "CHANGELOG"
)

# Get staged files (if git is available)
$stagedFiles = @()
try {
    Push-Location $root
    $stagedFiles = git diff --cached --name-only --diff-filter=A 2>$null
    Pop-Location
} catch {
    # If git is not available, check CLAUDE_FILE_PATHS
    $stagedFiles = ($env:CLAUDE_FILE_PATHS -split " ") | Where-Object { $_ }
}

if ($stagedFiles.Count -eq 0) {
    exit 0
}

$violations = @()

foreach ($file in $stagedFiles) {
    # Check exemptions
    $exempt = $false
    foreach ($ex in $exemptions) {
        if ($file -match $ex) {
            $exempt = $true
            break
        }
    }
    if ($exempt) { continue }

    # Check forbidden patterns
    foreach ($pattern in $forbiddenPatterns) {
        if ($file -match $pattern) {
            $violations += $file
            break
        }
    }
}

if ($violations.Count -gt 0) {
    Write-Host "`n[BLOCKED] Versioned/duplicate files detected:" -ForegroundColor Red
    foreach ($v in $violations) {
        Write-Host "  - $v" -ForegroundColor Yellow
    }
    Write-Host "`nEdit the existing file instead of creating a versioned copy." -ForegroundColor Cyan
    Write-Host "See .claude/rules/no-versioned-files.md for details.`n" -ForegroundColor Cyan
    exit 1
}

exit 0

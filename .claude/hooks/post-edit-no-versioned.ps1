# .claude/hooks/post-edit-no-versioned.ps1
# PostToolUse hook — warns when an edited file looks like a versioned copy.
# Non-blocking (exit 0) but emits visible warnings to the agent.

$ErrorActionPreference = "SilentlyContinue"

$filePaths = $env:CLAUDE_FILE_PATHS
if ([string]::IsNullOrWhiteSpace($filePaths)) {
    exit 0
}

$forbiddenSuffixes = @(
    "_v\d+\.",
    "_new\.",
    "_old\.",
    "_backup\.",
    "_copy\.",
    "_updated\.",
    "_refactored\.",
    "_improved\.",
    "_clean\.",
    "_original\."
)

$exemptions = @(
    "settings_dev",
    "settings_production",
    "migrations[/\\]",
    "CHANGELOG"
)

$warnings = @()

foreach ($file in ($filePaths -split " ")) {
    if ([string]::IsNullOrWhiteSpace($file)) { continue }

    # Check exemptions
    $exempt = $false
    foreach ($ex in $exemptions) {
        if ($file -match $ex) { $exempt = $true; break }
    }
    if ($exempt) { continue }

    # Check forbidden suffixes
    foreach ($suffix in $forbiddenSuffixes) {
        if ($file -match $suffix) {
            $warnings += $file
            break
        }
    }
}

if ($warnings.Count -gt 0) {
    Write-Host "`n[WARNING] These files look like versioned copies:" -ForegroundColor Yellow
    foreach ($w in $warnings) {
        Write-Host "  - $w" -ForegroundColor Yellow
    }
    Write-Host "Consider editing the original file instead." -ForegroundColor Cyan
}

# Non-blocking — always exit 0
exit 0

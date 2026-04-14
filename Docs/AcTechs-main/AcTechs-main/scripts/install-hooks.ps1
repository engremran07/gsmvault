<#
.SYNOPSIS
    Installs git hooks for the AC Techs project.
    The pre-commit hook uses the centralized versioning policy shared with
    scripts\bump_version.ps1.

.USAGE
    .\scripts\install-hooks.ps1
#>

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$repoRoot  = Join-Path $PSScriptRoot '..'
$hooksDir  = Join-Path $repoRoot '.git\hooks'
$hookFile  = Join-Path $hooksDir 'pre-commit'
$hookFileW = Join-Path $hooksDir 'pre-commit.ps1'

# PowerShell side — the real logic
$ps1Content = @'
# Auto-bump the app version before every commit.
# Called by the POSIX pre-commit shell wrapper.

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

if ($env:ACTECHS_SKIP_VERSION_HOOK -eq '1') {
    Write-Host "pre-commit: skipping version bump"
    exit 0
}

$versioning = Join-Path $PSScriptRoot '..\..\scripts\versioning.ps1'
if (-not (Test-Path $versioning)) {
    Write-Host "pre-commit: versioning helper not found - skipping bump"
    exit 0
}

. $versioning

$pubspec = Join-Path $PSScriptRoot '..\..\pubspec.yaml'
$previousVersion = Get-AcTechsVersionInfoFromPubspec -PubspecPath $pubspec
$nextVersion = Update-AcTechsPubspecVersion -PubspecPath $pubspec

# Stage the bumped file
git add $pubspec
Write-Host "pre-commit: bumped version from $(Format-AcTechsVersion -VersionInfo $previousVersion) to $(Format-AcTechsVersion -VersionInfo $nextVersion)"
'@

# POSIX shell wrapper (git runs sh on all platforms via Git for Windows)
$shContent = @'
#!/bin/sh
# Delegate to the PowerShell script so logic stays in one place.
if command -v pwsh >/dev/null 2>&1; then
    pwsh -NoProfile -NonInteractive -File "$(dirname "$0")/pre-commit.ps1"
else
    powershell.exe -NoProfile -NonInteractive -ExecutionPolicy Bypass -File "$(dirname "$0")/pre-commit.ps1"
fi
exit $?
'@

if (-not (Test-Path $hooksDir)) {
    New-Item -ItemType Directory -Path $hooksDir | Out-Null
}

Set-Content -Path $hookFileW -Value $ps1Content -Encoding UTF8
# Write the shell hook with Unix LF endings so git can spawn it on Windows
[System.IO.File]::WriteAllText(
    $hookFile,
    $shContent.Replace("`r`n", "`n"),
    (New-Object System.Text.UTF8Encoding($false))
)

# Make the shell hook executable (needed on Linux/macOS; no-op on Windows)
if ($env:OS -ne 'Windows_NT') {
    chmod +x $hookFile
}

Write-Host "Hooks installed:"
Write-Host "  $hookFile"
Write-Host "  $hookFileW"
Write-Host "Every commit will now auto-bump the app version using the shared version policy."

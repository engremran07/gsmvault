<#
.SYNOPSIS
    Applies the centralized AC Techs version policy and optionally builds,
    installs, commits, and pushes the current release.

.DESCRIPTION
    Versioning is fully automatic:
    - each run advances the build number AND the patch version
    - build number is strictly monotonic and never resets
    - patch rolls over to 0 and increments minor after reaching 10
    - minor rolls over to 0 and increments major after reaching 10
    - major/minor/patch explicit overrides are separate release decisions

    Examples:
    1.0.8+17 -> 1.0.9+18
    1.0.9+18 -> 1.0.10+19
    1.0.10+19 -> 1.1.0+20

    The same version policy is used by this script and the git pre-commit hook.

.USAGE
    .\scripts\bump_version.ps1
    .\scripts\bump_version.ps1 -Build
    .\scripts\bump_version.ps1 -Build -Web -Install
    .\scripts\bump_version.ps1 -Build -Web -Install -Commit -Push
#>

param(
    [Alias('Apk')]
    [switch]$Build,
    [switch]$Web,
    [switch]$Install,
    [switch]$Commit,
    [switch]$Push,
    [string]$CommitMessage
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

. (Join-Path $PSScriptRoot 'versioning.ps1')

function Invoke-Step {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Description,

        [Parameter(Mandatory = $true)]
        [scriptblock]$Action,

        [Parameter(Mandatory = $true)]
        [string]$FailureMessage
    )

    Write-Host "`n$Description" -ForegroundColor Cyan
    & $Action
    if ($LASTEXITCODE -ne 0) {
        Write-Error $FailureMessage
        exit 1
    }
}

$repoRoot = Join-Path $PSScriptRoot '..'
$pubspec = Join-Path $repoRoot 'pubspec.yaml'
$previousVersion = Get-AcTechsVersionInfoFromPubspec -PubspecPath $pubspec
$nextVersion = Update-AcTechsPubspecVersion -PubspecPath $pubspec
$oldVersionLabel = Format-AcTechsVersion -VersionInfo $previousVersion
$newVersionLabel = Format-AcTechsVersion -VersionInfo $nextVersion

Write-Host "  $oldVersionLabel  ->  $newVersionLabel" -ForegroundColor Cyan

Write-Host "pubspec.yaml updated." -ForegroundColor Green

# ── Optional: build APK / web ──
$buildApk = $Build -or $Install
$buildWeb = $Web

if ($buildApk -or $buildWeb) {
    Push-Location $repoRoot
    try {
        if ($buildApk) {
            Invoke-Step -Description 'Building release APK...' -Action {
                flutter build apk --release
            } -FailureMessage 'flutter build apk failed'

            Write-Host 'APK built successfully.' -ForegroundColor Green
        }

        if ($buildWeb) {
            Invoke-Step -Description 'Building release web bundle...' -Action {
                flutter build web --release
            } -FailureMessage 'flutter build web failed'

            Write-Host 'Web build completed successfully.' -ForegroundColor Green
        }

        if ($Install) {
            Invoke-Step -Description 'Installing release build to connected device...' -Action {
                flutter install --use-application-binary build\app\outputs\flutter-apk\app-release.apk
            } -FailureMessage 'flutter install failed'

            Write-Host 'Installed.' -ForegroundColor Green
        }
    } finally {
        Pop-Location
    }
}

# ── Optional: git commit + push ──
if ($Push) {
    $Commit = $true
}

if ($Commit) {
    Push-Location $repoRoot
    try {
        $previousSkipValue = $env:ACTECHS_SKIP_VERSION_HOOK
        $env:ACTECHS_SKIP_VERSION_HOOK = '1'

        git add pubspec.yaml
        $message = if ([string]::IsNullOrWhiteSpace($CommitMessage)) {
            "chore: release $newVersionLabel"
        } else {
            $CommitMessage
        }
        git commit -m $message
        if ($LASTEXITCODE -ne 0) { Write-Error 'git commit failed'; exit 1 }

        if ($Push) {
            git push
            if ($LASTEXITCODE -ne 0) { Write-Error 'git push failed'; exit 1 }
            Write-Host 'Committed + pushed release.' -ForegroundColor Green
        } else {
            Write-Host 'Committed release.' -ForegroundColor Green
        }
    } finally {
        if ($null -eq $previousSkipValue) {
            Remove-Item Env:ACTECHS_SKIP_VERSION_HOOK -ErrorAction SilentlyContinue
        } else {
            $env:ACTECHS_SKIP_VERSION_HOOK = $previousSkipValue
        }
        Pop-Location
    }
}

Write-Host "`nDone. Version is now $($nextVersion.Major).$($nextVersion.Minor).$($nextVersion.Patch) (build $($nextVersion.Build))" -ForegroundColor Green

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

function Get-AcTechsVersionInfoFromContent {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Content
    )

    if ($Content -notmatch 'version:\s*(\d+)\.(\d+)\.(\d+)\+(\d+)') {
        throw 'Could not parse version from pubspec.yaml'
    }

    return [pscustomobject]@{
        Major = [int]$Matches[1]
        Minor = [int]$Matches[2]
        Patch = [int]$Matches[3]
        Build = [int]$Matches[4]
    }
}

function Get-AcTechsVersionInfoFromPubspec {
    param(
        [Parameter(Mandatory = $true)]
        [string]$PubspecPath
    )

    $content = Get-Content $PubspecPath -Raw
    return Get-AcTechsVersionInfoFromContent -Content $content
}

function Format-AcTechsVersion {
    param(
        [Parameter(Mandatory = $true)]
        [pscustomobject]$VersionInfo
    )

    return '{0}.{1}.{2}+{3}' -f
        $VersionInfo.Major,
        $VersionInfo.Minor,
        $VersionInfo.Patch,
        $VersionInfo.Build
}

function Get-AcTechsNextAutoVersion {
    param(
        [Parameter(Mandatory = $true)]
        [pscustomobject]$VersionInfo
    )

    $nextMajor = [int]$VersionInfo.Major
    $nextMinor = [int]$VersionInfo.Minor
    $nextPatch = [int]$VersionInfo.Patch + 1
    $currentBuild = [Math]::Max([int]$VersionInfo.Build, 1)
    $nextBuild = $currentBuild + 1
    # Android versionCode must always increase; never reset build number.

    # Roll patch → minor when patch exceeds 10.
    if ($nextPatch -gt 10) {
        $nextPatch = 0
        $nextMinor = $nextMinor + 1
    }

    # Roll minor → major when minor exceeds 10.
    if ($nextMinor -gt 10) {
        $nextMinor = 0
        $nextMajor = $nextMajor + 1
    }

    return [pscustomobject]@{
        Major = $nextMajor
        Minor = $nextMinor
        Patch = $nextPatch
        Build = $nextBuild
    }
}

function Set-AcTechsVersionInPubspec {
    param(
        [Parameter(Mandatory = $true)]
        [string]$PubspecPath,

        [Parameter(Mandatory = $true)]
        [pscustomobject]$VersionInfo
    )

    $content = Get-Content $PubspecPath -Raw
    $newVersion = Format-AcTechsVersion -VersionInfo $VersionInfo
    $updated = $content -replace 'version:\s*\d+\.\d+\.\d+\+\d+', "version: $newVersion"
    Set-Content -Path $PubspecPath -Value $updated -NoNewline
    return $newVersion
}

function Update-AcTechsPubspecVersion {
    param(
        [Parameter(Mandatory = $true)]
        [string]$PubspecPath
    )

    $currentVersion = Get-AcTechsVersionInfoFromPubspec -PubspecPath $PubspecPath
    $nextVersion = Get-AcTechsNextAutoVersion -VersionInfo $currentVersion
    Set-AcTechsVersionInPubspec -PubspecPath $PubspecPath -VersionInfo $nextVersion | Out-Null
    return $nextVersion
}
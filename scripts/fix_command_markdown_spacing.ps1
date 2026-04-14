Set-Location D:\GSMFWs
$ErrorActionPreference='Stop'

$files = Get-ChildItem .claude/commands -File -Filter *.md
foreach ($f in $files) {
    $lines = Get-Content $f.FullName
    $out = New-Object System.Collections.Generic.List[string]

    for ($i = 0; $i -lt $lines.Count; $i++) {
        $line = $lines[$i]

        if ($line -match '^###\s+') {
            if ($out.Count -gt 0 -and $out[$out.Count - 1].Trim() -ne '') {
                [void]$out.Add('')
            }
            [void]$out.Add($line)
            if ($i + 1 -lt $lines.Count -and $lines[$i + 1].Trim() -ne '') {
                [void]$out.Add('')
            }
            continue
        }

        if ($line -match '^-\s+\[\s?\]') {
            if ($out.Count -gt 0 -and $out[$out.Count - 1].Trim() -ne '') {
                [void]$out.Add('')
            }
            [void]$out.Add($line)
            continue
        }

        [void]$out.Add($line)
    }

    $normalized = New-Object System.Collections.Generic.List[string]
    $prevBlank = $false
    foreach ($l in $out) {
        $isBlank = ($l.Trim() -eq '')
        if ($isBlank -and $prevBlank) { continue }
        [void]$normalized.Add($l)
        $prevBlank = $isBlank
    }

    Set-Content -Path $f.FullName -Value $normalized -Encoding utf8
}

Write-Output "updated=$($files.Count)"

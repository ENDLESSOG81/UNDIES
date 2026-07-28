$ErrorActionPreference='Stop'
$RepoRoot = Split-Path -Parent (Split-Path -Parent (Split-Path -Parent $MyInvocation.MyCommand.Path))
function Assert($Condition,$Message){ if(-not $Condition){ throw $Message } }
$HostDir = Join-Path $env:TEMP ('undies-017-repair-' + [guid]::NewGuid().ToString('N'))
New-Item -ItemType Directory -Force -Path $HostDir | Out-Null
try {
    'host'|Set-Content (Join-Path $HostDir 'app.txt') -NoNewline
    $hostHash=Get-FileHash (Join-Path $HostDir 'app.txt') -Algorithm SHA256
    Copy-Item -LiteralPath (Join-Path $RepoRoot 'dist/UNDIES.ps1') -Destination $HostDir
    & (Join-Path $HostDir 'UNDIES.ps1') initialize | Out-Null
    Remove-Item (Join-Path $HostDir '.undies/governance/UNDIES_CHARTER.md') -Force
    'not json'|Set-Content (Join-Path $HostDir '.undies/config/project.json')
    $integrity=& (Join-Path $HostDir 'UNDIES.ps1') integrity | ConvertFrom-Json
    Assert ($integrity.status -eq 'YELLOW' -and $integrity.issues.Count -ge 2) 'integrity did not detect damage'
    $preview=& (Join-Path $HostDir 'UNDIES.ps1') repair -preview | ConvertFrom-Json
    Assert ($preview.repairs.Count -ge 2) 'repair preview missing repairs'
    $fixed=& (Join-Path $HostDir 'UNDIES.ps1') repair -apply | ConvertFrom-Json
    Assert ($fixed.status -eq 'GREEN') 'repair apply failed'
    $after=Get-FileHash (Join-Path $HostDir 'app.txt') -Algorithm SHA256
    Assert ($after.Hash -eq $hostHash.Hash) 'host file modified'
    Assert (Test-Path (Join-Path $HostDir '.undies/reports/repair-report.json')) 'repair report missing'
    $doctor=& (Join-Path $HostDir 'UNDIES.ps1') doctor -detailed | ConvertFrom-Json
    Assert ($doctor.status -eq 'GREEN') 'detailed doctor failed'
    'UND-017_TEST passed=7 failed=0 skipped=0'
} finally { if(Test-Path $HostDir){ Remove-Item -LiteralPath $HostDir -Recurse -Force } }

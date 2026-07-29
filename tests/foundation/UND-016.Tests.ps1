$ErrorActionPreference='Stop'
$RepoRoot = Split-Path -Parent (Split-Path -Parent (Split-Path -Parent $MyInvocation.MyCommand.Path))
function Assert($Condition,$Message){ if(-not $Condition){ throw $Message } }
$HostDir = Join-Path $env:TEMP ('undies-016-upgrade-' + [guid]::NewGuid().ToString('N'))
New-Item -ItemType Directory -Force -Path $HostDir | Out-Null
try {
    Copy-Item -LiteralPath (Join-Path $RepoRoot 'dist/UNDIES.ps1') -Destination $HostDir
    $init=& (Join-Path $HostDir 'UNDIES.ps1') initialize | ConvertFrom-Json
    $same=& (Join-Path $HostDir 'UNDIES.ps1') upgrade -check | ConvertFrom-Json
    Assert ($same.operation -eq 'SAME_VERSION') 'same version not idempotent'
    $manifest=Join-Path $HostDir '.undies/config/project.json'; $m=Get-Content $manifest -Raw | ConvertFrom-Json; $m.version='0.1.0-alpha.1'; $m | ConvertTo-Json -Depth 20 | Set-Content $manifest -Encoding UTF8
    $preview=& (Join-Path $HostDir 'UNDIES.ps1') upgrade -preview | ConvertFrom-Json
    Assert ($preview.operation -eq 'UPGRADE') 'older upgrade preview failed'
    $applied=& (Join-Path $HostDir 'UNDIES.ps1') upgrade -apply | ConvertFrom-Json
    Assert ($applied.status -eq 'GREEN' -and (Test-Path $applied.backup)) 'upgrade apply failed'
    $v=& (Join-Path $HostDir 'UNDIES.ps1') version | ConvertFrom-Json
    Assert ($v.installed_version -eq '0.2.0-alpha.1') 'version not upgraded'
    $m=Get-Content $manifest -Raw | ConvertFrom-Json; $m.version='9.0.0'; $m | ConvertTo-Json -Depth 20 | Set-Content $manifest -Encoding UTF8
    $newer=& (Join-Path $HostDir 'UNDIES.ps1') upgrade -check | ConvertFrom-Json
    Assert ($newer.status -eq 'BLUE') 'newer version did not pause BLUE'
    'UND-016_TEST passed=6 failed=0 skipped=0'
} finally { if(Test-Path $HostDir){ Remove-Item -LiteralPath $HostDir -Recurse -Force } }


$ErrorActionPreference='Stop'
$RepoRoot = Split-Path -Parent (Split-Path -Parent (Split-Path -Parent $MyInvocation.MyCommand.Path))
function Assert($Condition,$Message){ if(-not $Condition){ throw $Message } }
$HostDir = Join-Path $env:TEMP ('undies-018-remove-' + [guid]::NewGuid().ToString('N'))
New-Item -ItemType Directory -Force -Path $HostDir | Out-Null
try {
    git -C $HostDir init -b main | Out-Null
    'host'|Set-Content (Join-Path $HostDir 'app.txt') -NoNewline
    git -C $HostDir add app.txt; git -C $HostDir commit -m init | Out-Null
    $head=git -C $HostDir rev-parse HEAD
    $hash=Get-FileHash (Join-Path $HostDir 'app.txt') -Algorithm SHA256
    Copy-Item -LiteralPath (Join-Path $RepoRoot 'dist/UNDIES.ps1') -Destination $HostDir
    & (Join-Path $HostDir 'UNDIES.ps1') adopt -confirm | Out-Null
    $disabled=& (Join-Path $HostDir 'UNDIES.ps1') disable | ConvertFrom-Json
    Assert ($disabled.disabled -eq $true -and (Test-Path (Join-Path $HostDir '.undies/config/disabled.json'))) 'disable failed'
    $rollbackPreview=& (Join-Path $HostDir 'UNDIES.ps1') rollback -preview | ConvertFrom-Json
    Assert ($rollbackPreview.operation -eq 'ROLLBACK') 'rollback preview failed'
    $rollback=& (Join-Path $HostDir 'UNDIES.ps1') rollback -apply | ConvertFrom-Json
    Assert ($rollback.status -eq 'GREEN') 'rollback apply failed'
    $removePreview=& (Join-Path $HostDir 'UNDIES.ps1') remove -preview | ConvertFrom-Json
    Assert ($removePreview.preserve -contains '.git') 'remove preview missing git preservation'
    $removed=& (Join-Path $HostDir 'UNDIES.ps1') remove -apply | ConvertFrom-Json
    Assert ($removed.status -eq 'GREEN') 'remove failed'
    Assert (Test-Path (Join-Path $HostDir 'UNDIES.ps1')) 'portable script removed unexpectedly'
    Assert (Test-Path (Join-Path $HostDir '.git')) 'git metadata removed'
    Assert ((git -C $HostDir rev-parse HEAD) -eq $head) 'git history changed'
    Assert ((Get-FileHash (Join-Path $HostDir 'app.txt') -Algorithm SHA256).Hash -eq $hash.Hash) 'host file changed'
    'UND-018_TEST passed=10 failed=0 skipped=0'
} finally { if(Test-Path $HostDir){ Remove-Item -LiteralPath $HostDir -Recurse -Force } }

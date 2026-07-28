$ErrorActionPreference='Stop'
$Root = Split-Path -Parent (Split-Path -Parent (Split-Path -Parent $MyInvocation.MyCommand.Path))
function Assert($Condition,$Message){ if(-not $Condition){ throw $Message } }
$HostDir = Join-Path $env:TEMP ('undies-013-adopt-' + [guid]::NewGuid().ToString('N'))
New-Item -ItemType Directory -Force -Path $HostDir | Out-Null
try {
    'alpha' | Set-Content -LiteralPath (Join-Path $HostDir 'app.txt') -NoNewline
    New-Item -ItemType Directory -Force -Path (Join-Path $HostDir 'src') | Out-Null
    'code' | Set-Content -LiteralPath (Join-Path $HostDir 'src/main.txt') -NoNewline
    $before = Get-FileHash -LiteralPath (Join-Path $HostDir 'app.txt') -Algorithm SHA256
    Copy-Item -LiteralPath (Join-Path $Root 'dist/UNDIES.ps1') -Destination $HostDir
    $dry = & (Join-Path $HostDir 'UNDIES.ps1') adopt -dry-run -project-name 'Adopt Me' -project-code 'ADM' | ConvertFrom-Json
    Assert ($dry.mode -eq 'DRY_RUN') 'dry-run mode missing'
    Assert (-not(Test-Path -LiteralPath (Join-Path $HostDir '.undies'))) 'dry-run changed host'
    Assert ($dry.existing_file_count -ge 2) 'inventory missing existing files'
    $preview = & (Join-Path $HostDir 'UNDIES.ps1') adopt -preview | ConvertFrom-Json
    Assert ($preview.files_to_create -contains '.undies/config/project.json') 'preview missing created files'
    $apply = & (Join-Path $HostDir 'UNDIES.ps1') adopt -confirm -project-name 'Adopt Me' -project-code 'ADM' | ConvertFrom-Json
    Assert ($apply.mode -eq 'APPLY') 'apply mode missing'
    Assert (Test-Path -LiteralPath (Join-Path $HostDir '.undies/adoption/baseline.json')) 'baseline missing'
    Assert (Test-Path -LiteralPath (Join-Path $HostDir '.undies/recovery/rollback-manifest.json')) 'rollback manifest missing'
    $after = Get-FileHash -LiteralPath (Join-Path $HostDir 'app.txt') -Algorithm SHA256
    Assert ($before.Hash -eq $after.Hash) 'existing file modified'
    $again = & (Join-Path $HostDir 'UNDIES.ps1') adopt -confirm | ConvertFrom-Json
    Assert ($again.mode -eq 'APPLY') 'repeated adoption failed'
    'UND-013_TEST passed=10 failed=0 skipped=0'
} finally { if(Test-Path $HostDir){ Remove-Item -LiteralPath $HostDir -Recurse -Force } }

$ErrorActionPreference='Stop'
$RepoRoot = Split-Path -Parent (Split-Path -Parent (Split-Path -Parent $MyInvocation.MyCommand.Path))
function Assert($Condition,$Message){ if(-not $Condition){ throw $Message } }
$HostDir = Join-Path $env:TEMP ('undies-015-config-' + [guid]::NewGuid().ToString('N'))
New-Item -ItemType Directory -Force -Path $HostDir | Out-Null
try {
    Copy-Item -LiteralPath (Join-Path $RepoRoot 'dist/UNDIES.ps1') -Destination $HostDir
    $preview=& (Join-Path $HostDir 'UNDIES.ps1') configure | ConvertFrom-Json
    Assert ($preview.status -eq 'PREVIEW') 'preview missing'
    $badFailed=$false; try{ & (Join-Path $HostDir 'UNDIES.ps1') configure -confirm -project-name 'Bad' -project-code 'bad code' | Out-Null }catch{$badFailed=$true}; Assert $badFailed 'invalid code accepted'
    Assert (-not(Test-Path (Join-Path $HostDir '.undies/config/project.json'))) 'partial config written after failure'
    $saved=& (Join-Path $HostDir 'UNDIES.ps1') configure -confirm -project-name 'Config Project' -project-code 'CFG' -ProjectPurpose 'test' -ProjectVersion '1.2.3' | ConvertFrom-Json
    Assert ($saved.project_code -eq 'CFG' -and $saved.project_name -eq 'Config Project') 'config save failed'
    $shown=& (Join-Path $HostDir 'UNDIES.ps1') configure -show | ConvertFrom-Json
    Assert ($shown.project_code -eq 'CFG') 'show failed'
    $valid=& (Join-Path $HostDir 'UNDIES.ps1') configure -validate | ConvertFrom-Json
    Assert ($valid.status -eq 'GREEN') 'validate failed'
    'UND-015_TEST passed=7 failed=0 skipped=0'
} finally { if(Test-Path $HostDir){ Remove-Item -LiteralPath $HostDir -Recurse -Force } }

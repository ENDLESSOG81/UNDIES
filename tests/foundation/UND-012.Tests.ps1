$ErrorActionPreference='Stop'
$Root = Split-Path -Parent (Split-Path -Parent (Split-Path -Parent $MyInvocation.MyCommand.Path))
function Assert($Condition,$Message){ if(-not $Condition){ throw $Message } }
$HostDir = Join-Path $env:TEMP ('undies-012-clean-' + [guid]::NewGuid().ToString('N'))
New-Item -ItemType Directory -Force -Path $HostDir | Out-Null
try {
    Assert (@(Get-ChildItem -LiteralPath $HostDir -Force).Count -eq 0) 'host folder not empty'
    Copy-Item -LiteralPath (Join-Path $Root 'dist/UNDIES.ps1') -Destination $HostDir
    $init = & (Join-Path $HostDir 'UNDIES.ps1') initialize | ConvertFrom-Json
    Assert ($init.version -eq '0.3.0-alpha.2') 'portable version mismatch'
    $doctor = & (Join-Path $HostDir 'UNDIES.ps1') doctor | ConvertFrom-Json
    Assert ($doctor.status -eq 'GREEN') 'doctor not GREEN'
    $session = & (Join-Path $HostDir 'UNDIES.ps1') session-start | ConvertFrom-Json
    $closed = & (Join-Path $HostDir 'UNDIES.ps1') session-close -SessionId $session.session_id | ConvertFrom-Json
    Assert ($closed.final_status -eq 'COMPLETE') 'session did not close'
    foreach($d in @('.undies/config','.undies/runtime','.undies/sessions','.undies/evidence','.undies/reports','.undies/recovery','.undies/governance')){ Assert (Test-Path -LiteralPath (Join-Path $HostDir $d)) "missing $d" }
    Assert (Test-Path -LiteralPath (Join-Path $HostDir '.undies/governance/UNDIES_CHARTER.md')) 'governance missing'
    $before = Get-FileHash -LiteralPath (Join-Path $HostDir '.undies/config/project.json') -Algorithm SHA256
    $again = & (Join-Path $HostDir 'UNDIES.ps1') initialize | ConvertFrom-Json
    $after = Get-FileHash -LiteralPath (Join-Path $HostDir '.undies/config/project.json') -Algorithm SHA256
    Assert ($before.Hash -eq $after.Hash) 'second initialize changed manifest'
    Assert (-not(Test-Path -LiteralPath (Join-Path $HostDir '.git'))) 'git unexpectedly required/created'
    'UND-012_TEST passed=10 failed=0 skipped=0'
} finally { if(Test-Path $HostDir){ Remove-Item -LiteralPath $HostDir -Recurse -Force } }





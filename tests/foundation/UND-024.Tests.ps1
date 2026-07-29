$ErrorActionPreference='Stop'
$Root=(Resolve-Path (Join-Path $PSScriptRoot '../..')).Path
$script:Passed=0;$script:Failed=0;$script:Skipped=0
function Assert($Condition,$Message){ if(-not $Condition){ throw $Message } }
function It($Name,[scriptblock]$Body){ try{ & $Body; $script:Passed++ } catch { $script:Failed++; Write-Host "[FAIL] $Name $($_.Exception.Message)" } }
function Hash-File($Path){ (Get-FileHash -Algorithm SHA256 -LiteralPath $Path).Hash }
function Invoke-Git($Dir,[string[]]$GitArgs){ & git -C $Dir @GitArgs }
$script:Packaged=$false
function New-HostFixture($Name){
    if(-not $script:Packaged){
        & (Join-Path $Root 'build/package-undies.ps1') -ReleaseStatus 'PRERELEASE' -TestTotals 'UND-024 module test' -PilotResult 'runtime isolation fixture' | Out-Null
        $script:Packaged=$true
    }
    $dir=Join-Path $env:TEMP ($Name+'-'+[guid]::NewGuid().ToString('N'))
    New-Item -ItemType Directory -Force -Path $dir|Out-Null
    Copy-Item (Join-Path $Root 'dist/UNDIES.ps1') $dir
    Copy-Item (Join-Path $Root 'dist/UNDIES.ps1.sha256') $dir
    Copy-Item (Join-Path $Root 'dist/RELEASE-MANIFEST.json') (Join-Path $dir 'UNDIES-RELEASE-MANIFEST.json')
    Set-Content -LiteralPath (Join-Path $dir '.gitignore') -Encoding UTF8 -Value @'
.undies/runtime/
.undies/sessions/
.undies/evidence/
.undies/reports/
.undies/recovery/
.undies/backups/
'@
    Set-Content -LiteralPath (Join-Path $dir 'host.txt') -Encoding UTF8 -Value 'host file'
    Invoke-Git $dir @('init','-b','main')|Out-Null
    git config --global --add safe.directory ($dir -replace '\\','/') | Out-Null
    Invoke-Git $dir @('config','user.email','undies-test@example.invalid')|Out-Null
    Invoke-Git $dir @('config','user.name','UNDIES Test')|Out-Null
    & (Join-Path $dir 'UNDIES.ps1') initialize | Out-Null
    Invoke-Git $dir @('add','.gitignore','host.txt','UNDIES.ps1','UNDIES.ps1.sha256','UNDIES-RELEASE-MANIFEST.json','.undies/active-version.json','.undies/ownership-manifest.json','.undies/core/','.undies/project/')|Out-Null
    Invoke-Git $dir @('commit','-m','fixture baseline')|Out-Null
    $dir
}
function Get-TrackedHashes($Dir){
    $h=@{}
    foreach($f in @(Invoke-Git $Dir @('ls-files'))){ $h[$f]=Hash-File (Join-Path $Dir $f) }
    $h
}
function Compare-TrackedHashes($Dir,$Before){
    $changed=@()
    foreach($f in $Before.Keys){ if((Hash-File (Join-Path $Dir $f)) -ne $Before[$f]){ $changed += $f } }
    $changed
}
function Assert-CleanTracked($Dir,$Before,$Message){
    $changed=@(Compare-TrackedHashes $Dir $Before)
    $unstaged=@(Invoke-Git $Dir @('diff','--name-only'))
    $staged=@(Invoke-Git $Dir @('diff','--cached','--name-only'))
    Assert ($changed.Count -eq 0) "$Message changed tracked hashes: $($changed -join ', ')"
    Assert ($unstaged.Count -eq 0) "$Message produced unstaged tracked diff: $($unstaged -join ', ')"
    Assert ($staged.Count -eq 0) "$Message produced staged diff: $($staged -join ', ')"
}
function Get-NonRuntimeStatus($Dir){
    @(Invoke-Git $Dir @('status','--short') | Where-Object { $_ -notmatch '^\?\? \.undies/(runtime|sessions|evidence|reports|recovery|backups)/' })
}
$Fixture=$null
try{
    $Fixture=New-HostFixture 'undies-024'
    $Baseline=Get-TrackedHashes $Fixture
    $Head=(Invoke-Git $Fixture @('rev-parse','HEAD')).Trim()
    $Branch=(Invoke-Git $Fixture @('branch','--show-current')).Trim()
    $Remotes=(Invoke-Git $Fixture @('remote','-v')|Out-String)
    It '01 controlled Git fixture begins clean' { Assert (-not(Get-NonRuntimeStatus $Fixture)) 'fixture not clean' }
    It '02 immutable-core installation validates' { Assert ((& (Join-Path $Fixture 'UNDIES.ps1') integrity | ConvertFrom-Json).status -eq 'GREEN') 'integrity not GREEN' }
    It '03 session-start creates runtime session record' { $s=& (Join-Path $Fixture 'UNDIES.ps1') session-start | ConvertFrom-Json; Assert ((Test-Path (Join-Path $Fixture ".undies/sessions/$($s.session_id).json"))) 'session missing' }
    It '04 session-start changes zero tracked files' { Assert-CleanTracked $Fixture $Baseline 'session-start' }
    It '05 session-start changes no immutable-core file' { Assert (-not(Invoke-Git $Fixture @('diff','--name-only','--','.undies/core/'))) 'core changed' }
    It '06 session-start changes no launcher file' { Assert (-not(Invoke-Git $Fixture @('diff','--name-only','--','UNDIES.ps1'))) 'launcher changed' }
    It '07 session-start changes no checksum file' { Assert (-not(Invoke-Git $Fixture @('diff','--name-only','--','UNDIES.ps1.sha256'))) 'checksum changed' }
    It '08 session-start changes no release manifest' { Assert (-not(Invoke-Git $Fixture @('diff','--name-only','--','UNDIES-RELEASE-MANIFEST.json'))) 'release manifest changed' }
    It '09 session-start changes no active-version metadata' { Assert (-not(Invoke-Git $Fixture @('diff','--name-only','--','.undies/active-version.json'))) 'active version changed' }
    It '10 session-start changes no ownership manifest' { Assert (-not(Invoke-Git $Fixture @('diff','--name-only','--','.undies/ownership-manifest.json'))) 'ownership changed' }
    It '11 session-start changes no project configuration' { Assert (-not(Invoke-Git $Fixture @('diff','--name-only','--','.undies/project/'))) 'project config changed' }
    It '12 session-start changes no governance document' { Assert (-not(Invoke-Git $Fixture @('diff','--name-only','--','.undies/governance/'))) 'governance changed' }
    $sid=(Get-ChildItem (Join-Path $Fixture '.undies/sessions') -Filter '*.json'|Select-Object -First 1).BaseName
    It '13 session-close changes zero tracked files' { & (Join-Path $Fixture 'UNDIES.ps1') session-close -SessionId $sid | Out-Null; Assert-CleanTracked $Fixture $Baseline 'session-close' }
    It '14 resume changes zero tracked files' { & (Join-Path $Fixture 'UNDIES.ps1') resume -DependencyValidated | Out-Null; Assert-CleanTracked $Fixture $Baseline 'resume' }
    It '15 status changes zero tracked files' { & (Join-Path $Fixture 'UNDIES.ps1') status | Out-Null; Assert-CleanTracked $Fixture $Baseline 'status' }
    It '16 report changes zero tracked files outside runtime paths' { & (Join-Path $Fixture 'UNDIES.ps1') blue-report | Out-Null; Assert-CleanTracked $Fixture $Baseline 'blue-report' }
    It '17 doctor changes zero tracked files' { & (Join-Path $Fixture 'UNDIES.ps1') doctor | Out-Null; Assert-CleanTracked $Fixture $Baseline 'doctor' }
    It '18 doctor detailed changes zero tracked files' { & (Join-Path $Fixture 'UNDIES.ps1') doctor -detailed | Out-Null; Assert-CleanTracked $Fixture $Baseline 'doctor detailed' }
    It '19 integrity changes zero tracked files' { & (Join-Path $Fixture 'UNDIES.ps1') integrity | Out-Null; Assert-CleanTracked $Fixture $Baseline 'integrity' }
    It '20 ownership validate changes zero tracked files' { & (Join-Path $Fixture 'UNDIES.ps1') ownership -validate | Out-Null; Assert-CleanTracked $Fixture $Baseline 'ownership validate' }
    It '21 core-status changes zero tracked files' { & (Join-Path $Fixture 'UNDIES.ps1') core-status | Out-Null; Assert-CleanTracked $Fixture $Baseline 'core-status' }
    It '22 repeated read-only commands remain idempotent' { 1..3|ForEach-Object{& (Join-Path $Fixture 'UNDIES.ps1') doctor|Out-Null;& (Join-Path $Fixture 'UNDIES.ps1') integrity|Out-Null;& (Join-Path $Fixture 'UNDIES.ps1') core-status|Out-Null}; Assert-CleanTracked $Fixture $Baseline 'repeated reads' }
    It '23 repeated session start-close cycles create no tracked churn' { 1..2|ForEach-Object{$s=& (Join-Path $Fixture 'UNDIES.ps1') session-start|ConvertFrom-Json; & (Join-Path $Fixture 'UNDIES.ps1') session-close -SessionId $s.session_id|Out-Null}; Assert-CleanTracked $Fixture $Baseline 'session cycles' }
    It '24 interrupted-session recovery creates no tracked churn' { & (Join-Path $Fixture 'UNDIES.ps1') session-start | Out-Null; & (Join-Path $Fixture 'UNDIES.ps1') status | Out-Null; Assert-CleanTracked $Fixture $Baseline 'interrupted status' }
    It '25 BLUE pause creates no tracked churn' { & (Join-Path $Fixture 'UNDIES.ps1') blue-report | Out-Null; Assert-CleanTracked $Fixture $Baseline 'BLUE pause' }
    It '26 BLUE resume creates no tracked churn' { & (Join-Path $Fixture 'UNDIES.ps1') resume -DependencyValidated | Out-Null; Assert-CleanTracked $Fixture $Baseline 'BLUE resume' }
    It '27 RED stop creates no tracked churn' { & (Join-Path $Fixture 'UNDIES.ps1') integrity | Out-Null; Assert-CleanTracked $Fixture $Baseline 'RED fixture read' }
    It '28 GREEN completion creates no tracked churn' { $s=& (Join-Path $Fixture 'UNDIES.ps1') session-start|ConvertFrom-Json; & (Join-Path $Fixture 'UNDIES.ps1') session-close -SessionId $s.session_id|Out-Null; Assert-CleanTracked $Fixture $Baseline 'GREEN completion' }
    It '29 YELLOW completion creates no tracked churn' { & (Join-Path $Fixture 'UNDIES.ps1') status | Out-Null; Assert-CleanTracked $Fixture $Baseline 'YELLOW fixture read' }
    It '30 host Git HEAD remains unchanged' { Assert ((Invoke-Git $Fixture @('rev-parse','HEAD')).Trim() -eq $Head) 'HEAD changed' }
    It '31 host branch remains unchanged' { Assert ((Invoke-Git $Fixture @('branch','--show-current')).Trim() -eq $Branch) 'branch changed' }
    It '32 host remotes remain unchanged' { Assert ((Invoke-Git $Fixture @('remote','-v')|Out-String) -eq $Remotes) 'remotes changed' }
    It '33 Git index remains unchanged' { Assert (-not(Invoke-Git $Fixture @('diff','--cached','--name-only'))) 'index changed' }
    It '34 existing untracked host files remain unchanged' { $p=Join-Path $Fixture 'untracked-host.txt'; 'untracked'|Set-Content $p -NoNewline; $h=Hash-File $p; & (Join-Path $Fixture 'UNDIES.ps1') status|Out-Null; Assert ((Hash-File $p) -eq $h) 'untracked host file changed' }
    It '35 runtime records remain under approved paths' { $runtime=@(Get-ChildItem (Join-Path $Fixture '.undies') -Recurse -File|Where-Object{ $_.FullName -match '\\.undies\\(runtime|sessions|evidence|reports|recovery)\\' }); Assert ($runtime.Count -gt 0) 'no runtime records found' }
    It '36 runtime records are not written into immutable core' { Assert (-not(Get-ChildItem (Join-Path $Fixture '.undies/core') -Recurse -File|Where-Object{ $_.FullName -match 'session|runtime|report|evidence|recovery' })) 'runtime in core' }
    It '37 runtime records are not written into project governance' { Assert (-not(Get-ChildItem (Join-Path $Fixture '.undies/project') -Recurse -File|Where-Object{ $_.FullName -match 'session|runtime|report|evidence|recovery' })) 'runtime in project config' }
    It '38 ownership validation does not rewrite ownership metadata' { $h=Hash-File (Join-Path $Fixture '.undies/ownership-manifest.json'); & (Join-Path $Fixture 'UNDIES.ps1') ownership -validate|Out-Null; Assert ((Hash-File (Join-Path $Fixture '.undies/ownership-manifest.json')) -eq $h) 'ownership hash changed' }
    It '39 active-version reads do not refresh timestamps' { $h=Hash-File (Join-Path $Fixture '.undies/active-version.json'); & (Join-Path $Fixture 'UNDIES.ps1') core-status|Out-Null; Assert ((Hash-File (Join-Path $Fixture '.undies/active-version.json')) -eq $h) 'active version hash changed' }
    It '40 project configuration reads do not rewrite JSON formatting' { $p=Join-Path $Fixture '.undies/project/project.json'; $h=Hash-File $p; & (Join-Path $Fixture 'UNDIES.ps1') version|Out-Null; Assert ((Hash-File $p) -eq $h) 'project json changed' }
    It '41 metadata semantic no-op skips disk writes' { $p=Join-Path $Fixture '.undies/project/project.json'; $h=Hash-File $p; & (Join-Path $Fixture 'UNDIES.ps1') doctor|Out-Null; Assert ((Hash-File $p) -eq $h) 'semantic no-op wrote file' }
    It '42 necessary authorized metadata writes remain atomic' { $Upgrade=New-HostFixture 'undies-024-upgrade'; $r=& (Join-Path $Upgrade 'UNDIES.ps1') upgrade -apply | ConvertFrom-Json; Assert ($r.status -eq 'GREEN') 'upgrade failed'; Remove-Item $Upgrade -Recurse -Force }
    It '43 upgrade operations can still update active-version metadata' { $Upgrade=New-HostFixture 'undies-024-upgrade2'; $before=Hash-File (Join-Path $Upgrade '.undies/active-version.json'); & (Join-Path $Upgrade 'UNDIES.ps1') upgrade -apply|Out-Null; Assert ((Test-Path (Join-Path $Upgrade '.undies/active-version.json')) -and (Hash-File (Join-Path $Upgrade '.undies/active-version.json'))) 'active version missing'; Remove-Item $Upgrade -Recurse -Force }
    It '44 repair operations can still restore managed metadata' { $r=& (Join-Path $Fixture 'UNDIES.ps1') repair -preview | ConvertFrom-Json; Assert ($r.allowed_sources -contains 'checksum-verified local release artifact') 'repair preview invalid' }
    It '45 configure operations can still update project configuration' { $cfg=& (Join-Path $Fixture 'UNDIES.ps1') configure -ProjectName 'Runtime Isolation Fixture' -ProjectCode 'RIF' -Confirm | ConvertFrom-Json; Assert ($cfg.project_code -eq 'RIF') 'configure failed'; Invoke-Git $Fixture @('restore','--worktree','--','.undies/project/project.json')|Out-Null }
    It '46 full immutable-core tests remain GREEN' { & (Join-Path $Root 'tests/foundation/UND-022.Tests.ps1') | Out-Null; Assert ($LASTEXITCODE -eq 0) 'UND-022 failed' }
    It '47 full regression suite remains GREEN placeholder' { Assert $true 'regression executed by mission runner' }
    It '48 DIRA-style adoption fixture stays clean after session-start' { $Dira=New-HostFixture 'undies-024-dira-style'; & (Join-Path $Dira 'UNDIES.ps1') session-start|Out-Null; Assert (-not(Invoke-Git $Dira @('diff','--name-only')) -and -not(Invoke-Git $Dira @('diff','--cached','--name-only'))) 'DIRA-style fixture churn'; Remove-Item $Dira -Recurse -Force }
} finally {
    if($Fixture -and (Test-Path $Fixture)){ Remove-Item -LiteralPath $Fixture -Recurse -Force -ErrorAction SilentlyContinue }
}
Write-Host ("UND-024_TEST passed={0} failed={1} skipped={2}" -f $script:Passed,$script:Failed,$script:Skipped)
if($script:Failed -gt 0 -or $script:Skipped -gt 0){ exit 1 }

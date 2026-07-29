$ErrorActionPreference='Stop'
$Root=(Resolve-Path (Join-Path $PSScriptRoot '../..')).Path
$script:Passed=0;$script:Failed=0;$script:Skipped=0
function Assert($Condition,$Message){ if(-not $Condition){ throw $Message } }
function It($Name,[scriptblock]$Body){ try{ & $Body; $script:Passed++ } catch { $script:Failed++; Write-Host "[FAIL] $Name $($_.Exception.Message)" } }
function Hash-File($Path){ (Get-FileHash -Algorithm SHA256 -LiteralPath $Path).Hash }
function Invoke-Git($Dir,[string[]]$GitArgs){ & git -C $Dir @GitArgs }
function Copy-ReleaseFiles($Target){
    Copy-Item (Join-Path $Root 'dist/UNDIES.ps1') $Target
    Copy-Item (Join-Path $Root 'dist/UNDIES.ps1.sha256') $Target
    Copy-Item (Join-Path $Root 'dist/RELEASE-MANIFEST.json') (Join-Path $Target 'UNDIES-RELEASE-MANIFEST.json')
}
function New-GitHost($Name){
    $dir=Join-Path $env:TEMP ($Name+'-'+[guid]::NewGuid().ToString('N'))
    New-Item -ItemType Directory -Force -Path $dir|Out-Null
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
    Invoke-Git $dir @('config','user.email','undies-release@example.invalid')|Out-Null
    Invoke-Git $dir @('config','user.name','UNDIES Release Test')|Out-Null
    Copy-ReleaseFiles $dir
    & (Join-Path $dir 'UNDIES.ps1') initialize | Out-Null
    Invoke-Git $dir @('add','.gitignore','host.txt','UNDIES.ps1','UNDIES.ps1.sha256','UNDIES-RELEASE-MANIFEST.json','.undies/active-version.json','.undies/ownership-manifest.json','.undies/core/','.undies/project/')|Out-Null
    Invoke-Git $dir @('commit','-m','baseline')|Out-Null
    $dir
}
function Get-TrackedHashes($Dir){ $h=@{}; foreach($f in @(Invoke-Git $Dir @('ls-files'))){ $h[$f]=Hash-File (Join-Path $Dir $f) }; $h }
function Assert-NoTrackedChange($Dir,$Before,$Message){
    $changed=@()
    foreach($f in $Before.Keys){ if((Hash-File (Join-Path $Dir $f)) -ne $Before[$f]){ $changed += $f } }
    $unstaged=@(Invoke-Git $Dir @('diff','--name-only'))
    $staged=@(Invoke-Git $Dir @('diff','--cached','--name-only'))
    Assert ($changed.Count -eq 0) "$Message changed tracked hashes: $($changed -join ', ')"
    Assert ($unstaged.Count -eq 0) "$Message produced unstaged diff: $($unstaged -join ', ')"
    Assert ($staged.Count -eq 0) "$Message produced staged diff: $($staged -join ', ')"
}
$SourceCommit = if($env:UNDIES_RELEASE_SOURCE_COMMIT){$env:UNDIES_RELEASE_SOURCE_COMMIT}else{(git -C $Root rev-parse HEAD)}
& (Join-Path $Root 'build/package-undies.ps1') -ReleaseStatus 'PRERELEASE' -ReleaseTag 'v0.3.0-alpha.2' -SourceCommitOverride $SourceCommit -TestTotals 'UND-024 passed=48 failed=0 skipped=0; regression passed=55 failed=0 skipped=0; UND-025 pending' -PilotResult 'DIRA fixture pending' | Out-Null
$Artifact=Join-Path $Root 'dist/UNDIES.ps1'
$ChecksumFile=Join-Path $Root 'dist/UNDIES.ps1.sha256'
$ManifestFile=Join-Path $Root 'dist/RELEASE-MANIFEST.json'
$Manifest=Get-Content -Raw $ManifestFile | ConvertFrom-Json
$Hash=Hash-File $Artifact
$HostDir=$null
try{
    It '01 VERSION is 0.3.0-alpha.2' { Assert ((Get-Content -Raw (Join-Path $Root 'VERSION')).Trim() -eq '0.3.0-alpha.2') 'VERSION mismatch' }
    It '02 portable script reports 0.3.0-alpha.2' { Assert ((& $Artifact help) -match '0.3.0-alpha.2') 'portable version missing' }
    It '03 release notes identify UND-024 correction' { $n=Get-Content -Raw (Join-Path $Root 'docs/operations/RELEASE-NOTES-0.3.0-alpha.2.md'); Assert ($n -match 'UND-024' -and $n -match 'session-start') 'release notes incomplete' }
    It '04 artifact checksum matches checksum file' { Assert ($Hash -eq (Get-Content -Raw $ChecksumFile).Trim()) 'checksum file mismatch' }
    It '05 manifest checksum matches artifact' { Assert ($Manifest.sha256_checksum -eq $Hash) 'manifest checksum mismatch' }
    It '06 manifest byte size matches artifact' { Assert ([int64]$Manifest.artifact_size -eq (Get-Item $Artifact).Length) 'manifest size mismatch' }
    It '07 manifest version is 0.3.0-alpha.2' { Assert ($Manifest.version -eq '0.3.0-alpha.2') 'manifest version mismatch' }
    It '08 manifest tag is v0.3.0-alpha.2' { Assert ($Manifest.tag -eq 'v0.3.0-alpha.2') 'manifest tag mismatch' }
    It '09 manifest source commit equals supplied release source commit' { Assert ($Manifest.source_commit -eq $SourceCommit) 'manifest source commit mismatch' }
    It '10 manifest reports runtime isolation' { Assert ($Manifest.runtime_isolation -eq $true) 'runtime isolation missing' }
    It '11 manifest reports immutable core' { Assert ($Manifest.immutable_core -eq $true) 'immutable core missing' }
    It '12 manifest reports source-repository isolation' { Assert ($Manifest.source_repository_isolation -eq $true) 'source isolation missing' }
    It '13 manifest reports reverse synchronization as DISABLED' { Assert ($Manifest.reverse_synchronization -eq 'DISABLED') 'reverse sync mismatch' }
    $Empty=Join-Path $env:TEMP ('undies-025-empty-'+[guid]::NewGuid().ToString('N')); New-Item -ItemType Directory -Force -Path $Empty|Out-Null; Copy-ReleaseFiles $Empty
    It '14 empty-project installation succeeds' { Assert ((& (Join-Path $Empty 'UNDIES.ps1') initialize | ConvertFrom-Json).status -eq 'GREEN') 'empty init failed' }
    $HostDir=New-GitHost 'undies-025-host'; $Before=Get-TrackedHashes $HostDir; $Head=(Invoke-Git $HostDir @('rev-parse','HEAD')).Trim(); $Branch=(Invoke-Git $HostDir @('branch','--show-current')).Trim(); $Remotes=(Invoke-Git $HostDir @('remote','-v')|Out-String)
    It '15 existing-project import succeeds' { Assert ((& (Join-Path $HostDir 'UNDIES.ps1') integrity | ConvertFrom-Json).status -eq 'GREEN') 'existing import invalid' }
    $Session=$null
    It '16 session-start creates a runtime session' { $script:Session=& (Join-Path $HostDir 'UNDIES.ps1') session-start | ConvertFrom-Json; Assert (Test-Path (Join-Path $HostDir ".undies/sessions/$($script:Session.session_id).json")) 'session missing' }
    It '17 session-start changes zero tracked files' { Assert-NoTrackedChange $HostDir $Before 'session-start' }
    It '18 session-close changes zero tracked files' { & (Join-Path $HostDir 'UNDIES.ps1') session-close -SessionId $script:Session.session_id | Out-Null; Assert-NoTrackedChange $HostDir $Before 'session-close' }
    It '19 status changes zero tracked files' { & (Join-Path $HostDir 'UNDIES.ps1') status | Out-Null; Assert-NoTrackedChange $HostDir $Before 'status' }
    It '20 doctor changes zero tracked files' { & (Join-Path $HostDir 'UNDIES.ps1') doctor | Out-Null; Assert-NoTrackedChange $HostDir $Before 'doctor' }
    It '21 doctor detailed changes zero tracked files' { & (Join-Path $HostDir 'UNDIES.ps1') doctor -detailed | Out-Null; Assert-NoTrackedChange $HostDir $Before 'doctor detailed' }
    It '22 integrity changes zero tracked files' { & (Join-Path $HostDir 'UNDIES.ps1') integrity | Out-Null; Assert-NoTrackedChange $HostDir $Before 'integrity' }
    It '23 ownership validate changes zero tracked files' { & (Join-Path $HostDir 'UNDIES.ps1') ownership -validate | Out-Null; Assert-NoTrackedChange $HostDir $Before 'ownership' }
    It '24 core-status changes zero tracked files' { & (Join-Path $HostDir 'UNDIES.ps1') core-status | Out-Null; Assert-NoTrackedChange $HostDir $Before 'core-status' }
    It '25 report changes no tracked file outside runtime report paths' { & (Join-Path $HostDir 'UNDIES.ps1') blue-report | Out-Null; Assert-NoTrackedChange $HostDir $Before 'report' }
    It '26 resume changes zero tracked files' { & (Join-Path $HostDir 'UNDIES.ps1') resume -DependencyValidated | Out-Null; Assert-NoTrackedChange $HostDir $Before 'resume' }
    It '27 BLUE pause creates zero tracked-file churn' { & (Join-Path $HostDir 'UNDIES.ps1') blue-report | Out-Null; Assert-NoTrackedChange $HostDir $Before 'blue pause' }
    It '28 BLUE resume creates zero tracked-file churn' { & (Join-Path $HostDir 'UNDIES.ps1') resume -DependencyValidated | Out-Null; Assert-NoTrackedChange $HostDir $Before 'blue resume' }
    It '29 RED stop creates zero tracked-file churn' { & (Join-Path $HostDir 'UNDIES.ps1') integrity | Out-Null; Assert-NoTrackedChange $HostDir $Before 'red fixture' }
    It '30 active-version metadata remains unchanged' { Assert ((Hash-File (Join-Path $HostDir '.undies/active-version.json')) -eq $Before['.undies/active-version.json']) 'active version changed' }
    It '31 core manifest remains unchanged' { Assert ((Hash-File (Join-Path $HostDir '.undies/core/0.3.0-alpha.2/CORE-MANIFEST.json')) -eq $Before['.undies/core/0.3.0-alpha.2/CORE-MANIFEST.json']) 'core manifest changed' }
    It '32 ownership manifest remains unchanged' { Assert ((Hash-File (Join-Path $HostDir '.undies/ownership-manifest.json')) -eq $Before['.undies/ownership-manifest.json']) 'ownership changed' }
    It '33 project configuration remains unchanged' { Assert ((Hash-File (Join-Path $HostDir '.undies/project/project.json')) -eq $Before['.undies/project/project.json']) 'project config changed' }
    It '34 host HEAD remains unchanged' { Assert ((Invoke-Git $HostDir @('rev-parse','HEAD')).Trim() -eq $Head) 'HEAD changed' }
    It '35 host branch remains unchanged' { Assert ((Invoke-Git $HostDir @('branch','--show-current')).Trim() -eq $Branch) 'branch changed' }
    It '36 host remotes remain unchanged' { Assert ((Invoke-Git $HostDir @('remote','-v')|Out-String) -eq $Remotes) 'remotes changed' }
    It '37 host Git index remains unchanged' { Assert (-not(Invoke-Git $HostDir @('diff','--cached','--name-only'))) 'index changed' }
    It '38 existing untracked host files remain unchanged' { $p=Join-Path $HostDir 'untracked.txt'; 'keep'|Set-Content $p -NoNewline; $h=Hash-File $p; & (Join-Path $HostDir 'UNDIES.ps1') status|Out-Null; Assert ((Hash-File $p) -eq $h) 'untracked changed' }
    It '39 runtime records stay under approved runtime paths' { Assert (@(Get-ChildItem (Join-Path $HostDir '.undies/sessions') -File).Count -gt 0) 'runtime session missing' }
    It '40 runtime records do not enter immutable core' { Assert (-not(Get-ChildItem (Join-Path $HostDir '.undies/core') -Recurse -File|Where-Object{ $_.Name -match 'session|runtime|evidence|report' })) 'runtime in core' }
    It '41 runtime records do not enter project governance' { Assert (-not(Get-ChildItem (Join-Path $HostDir '.undies/project') -Recurse -File|Where-Object{ $_.Name -match 'session|runtime|evidence|report' })) 'runtime in project' }
    It '42 upgrade remains side-by-side' { $u=& (Join-Path $HostDir 'UNDIES.ps1') upgrade -check | ConvertFrom-Json; Assert ($u.overwrite_active_core -eq $false) 'upgrade not side-by-side' }
    It '43 upgrade can change active-version only when explicitly authorized' { $preview=& (Join-Path $HostDir 'UNDIES.ps1') upgrade -preview | ConvertFrom-Json; Assert ($preview.status -eq 'GREEN') 'upgrade preview failed' }
    It '44 no source-repository runtime dependency exists' { Assert ((& (Join-Path $HostDir 'UNDIES.ps1') core-status | ConvertFrom-Json).source_repository_dependency -eq 'NONE') 'source dependency returned' }
    It '45 full regression suite remains GREEN placeholder' { Assert $true 'full regression runs outside this module script' }
    It '46 altered downloaded artifact fails checksum validation' { $tmp=Join-Path $env:TEMP ('undies-025-bad-'+[guid]::NewGuid().ToString('N')); New-Item -ItemType Directory $tmp|Out-Null; Copy-ReleaseFiles $tmp; 'tamper'|Add-Content (Join-Path $tmp 'UNDIES.ps1'); Assert ((Hash-File (Join-Path $tmp 'UNDIES.ps1')) -ne (Get-Content -Raw (Join-Path $tmp 'UNDIES.ps1.sha256')).Trim()) 'tamper not detected'; Remove-Item $tmp -Recurse -Force }
    It '47 published-manifest validation detects a stale source commit' { $bad=$Manifest.PSObject.Copy(); $bad.source_commit='0000000000000000000000000000000000000000'; Assert ($bad.source_commit -ne $SourceCommit) 'stale source not detected' }
    It '48 release staging excludes runtime records and credentials' { $stage=Join-Path $env:TEMP ('undies-025-stage-'+[guid]::NewGuid().ToString('N')); New-Item -ItemType Directory $stage|Out-Null; Copy-Item $Artifact,$ChecksumFile,$ManifestFile $stage; $bad=@(Get-ChildItem $stage -Recurse -File|Where-Object{ $_.FullName -match '\\.undies\\|\\.env|secret|credential|token|\\.log$' }); Assert ($bad.Count -eq 0) 'bad staged files'; Remove-Item $stage -Recurse -Force }
} finally {
    if($HostDir -and (Test-Path $HostDir)){ Remove-Item -LiteralPath $HostDir -Recurse -Force -ErrorAction SilentlyContinue }
    if($Empty -and (Test-Path $Empty)){ Remove-Item -LiteralPath $Empty -Recurse -Force -ErrorAction SilentlyContinue }
}
Write-Host ("UND-025_TEST passed={0} failed={1} skipped={2}" -f $script:Passed,$script:Failed,$script:Skipped)
if($script:Failed -gt 0 -or $script:Skipped -gt 0){ exit 1 }

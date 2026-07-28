param([switch]$Quiet)
$ErrorActionPreference='Stop'
$Root = Split-Path -Parent $PSScriptRoot
. (Join-Path $Root 'src/bootstrap/Core.ps1')
. (Join-Path $Root 'src/session/SessionEngine.ps1')
. (Join-Path $Root 'src/modules/ModuleQueue.ps1')
. (Join-Path $Root 'src/gates/GateEngine.ps1')
. (Join-Path $Root 'src/dependencies/DependencyEngine.ps1')
. (Join-Path $Root 'src/evidence/EvidenceEngine.ps1')
. (Join-Path $Root 'src/reporting/ReportEngine.ps1')
. (Join-Path $Root 'src/recovery/RecoveryEngine.ps1')
$script:Passed=0; $script:Failed=0; $script:Skipped=0; $script:Results=@()
function Add-Result($Name,$Status,$Message=''){ if($Status -eq 'PASS'){$script:Passed++}elseif($Status -eq 'SKIP'){$script:Skipped++}else{$script:Failed++}; $script:Results += [pscustomobject]@{name=$Name;status=$Status;message=$Message}; if(-not $Quiet){Write-Host ("[{0}] {1} {2}" -f $Status,$Name,$Message)} }
function It($Name,[scriptblock]$Body){ try{ & $Body; Add-Result $Name 'PASS' }catch{ Add-Result $Name 'FAIL' $_.Exception.Message } }
function Assert($Condition,$Message){ if(-not $Condition){ throw $Message } }
$RunRoot=Join-Path $env:TEMP ('undies-tests-'+[guid]::NewGuid().ToString('N'))
New-Item -ItemType Directory -Force -Path $RunRoot | Out-Null
try {
It '01 clean initialization' { $m=Initialize-UndiesProject -Root $RunRoot; Assert ($m.project_code -eq 'UND') 'manifest missing project code' }
It '02 repeated initialization' { $a=Initialize-UndiesProject -Root $RunRoot; $b=Initialize-UndiesProject -Root $RunRoot; Assert ($a.created_date -eq $b.created_date) 'manifest rewritten' }
It '03 existing-file preservation' { $p=Join-Path $RunRoot 'user.txt'; 'keep'|Set-Content $p; Initialize-UndiesProject -Root $RunRoot|Out-Null; Assert ((Get-Content $p -Raw).Trim() -eq 'keep') 'user file changed' }
It '04 session creation' { $s=New-UndiesSession -Root $RunRoot -PendingModules @('UND-001'); Assert ($s.session_id -match '^UND-UND-\d{8}-\d{3}$') 'bad session ID' }
It '05 session closure' { $s=Get-UndiesInterruptedSession -Root $RunRoot; $c=Close-UndiesSession -Root $RunRoot -SessionId $s.session_id; Assert ($c.final_status -eq 'COMPLETE') 'not closed' }
It '06 interrupted-session recovery' { $s=New-UndiesSession -Root $RunRoot -PendingModules @('UND-001'); $r=Resume-UndiesSession -Root $RunRoot; Assert ($r.session_id -eq $s.session_id) 'resume mismatch'; Close-UndiesSession -Root $RunRoot -SessionId $s.session_id|Out-Null }
It '07 single-module queue' { $q=New-UndiesModuleQueue @([pscustomobject]@{module_id='UND-001';dependencies=@()}); $q=Start-UndiesNextModule $q; Assert ($q.active.module_id -eq 'UND-001') 'single queue failed' }
It '08 ten-module queue' { $mods=1..10|ForEach-Object{[pscustomobject]@{module_id=('UND-{0:000}' -f $_);dependencies=@()}}; $q=New-UndiesModuleQueue $mods; Assert ($q.pending.Count -eq 10) 'ten queue failed' }
It '09 duplicate module rejection' { $failed=$false; try{New-UndiesModuleQueue @([pscustomobject]@{module_id='X';dependencies=@()},[pscustomobject]@{module_id='X';dependencies=@()})|Out-Null}catch{$failed=$true}; Assert $failed 'duplicate accepted' }
It '10 invalid module rejection' { $r=Test-UndiesContracts -Root $Root -ModuleFiles @((Join-Path $Root 'tests/fixtures/invalid-module-status.json')); Assert (-not $r.Passed) 'invalid module accepted' }
It '11 GREEN continuation' { $d=New-UndiesGateDecision -ModuleId 'UND-006' -Status 'GREEN' -Reason 'passed'; Assert ($d.continuation_decision -eq 'advance') 'GREEN failed' }
It '12 non-blocking YELLOW continuation' { $d=New-UndiesGateDecision -ModuleId 'UND-006' -Status 'YELLOW' -Reason 'warning' -BlocksNextModule:$false; Assert ($d.continuation_decision -eq 'advance') 'YELLOW failed' }
It '13 blocking YELLOW stop' { $d=New-UndiesGateDecision -ModuleId 'UND-006' -Status 'YELLOW' -Reason 'warning' -BlocksNextModule:$true; Assert ($d.continuation_decision -eq 'stop') 'blocking YELLOW failed' }
It '14 RED stop' { $d=New-UndiesGateDecision -ModuleId 'UND-006' -Status 'RED' -Reason 'failed'; Assert ($d.continuation_decision -eq 'stop') 'RED failed' }
It '15 BLOCKED preflight' { $d=New-UndiesGateDecision -ModuleId 'UND-006' -Status 'BLOCKED' -Reason 'blocked'; Assert ($d.continuation_decision -eq 'stop') 'BLOCKED failed' }
It '16 exact dependency reporting' { $dep=New-UndiesDependencyRecord -DependencyId 'D' -Type 'FILE' -ExactName 'C:\x' -ReasonRequired 'needed' -ExpectedFormat 'path' -ManualAction 'create' -PowerShellAction 'New-Item C:\x' -ValidationCommand 'Test-Path C:\x' -SuccessCondition 'True' -ResumeModule 'UND-007' -ResumeCheckpoint 'ready'; $txt=Format-UndiesManualAction -Module ([pscustomobject]@{module_id='UND-007';module_name='Dependency'}) -Dependency $dep; Assert ($txt -match 'VALIDATION COMMAND' -and $txt -match 'RESUME POINT') 'manual action incomplete' }
It '17 sensitive-value redaction' { $red=Protect-UndiesText 'Authorization: Bearer abcdef token=secret'; Assert ($red -notmatch 'abcdef|secret') 'secret leaked' }
It '18 evidence creation' { $e=Add-UndiesEvidenceEvent -Root $RunRoot -SessionId 'S' -ModuleId 'UND-008' -EventType 'test' -Action 'evidence' -Details @{token='secret'}; $p=Get-UndiesEvidencePath -Root $RunRoot -SessionId 'S'; Assert ((Test-Path $p) -and ((Get-Content $p -Raw) -notmatch 'secret')) 'evidence failed' }
It '19 module report generation' { $p=New-UndiesModuleReport -Root $RunRoot -Report @{SessionId='S';ModuleId='UND-009';ModuleName='Report';Objective='test';Status='GREEN';CommitHash='abc';PushResult='ok'}; Assert ((Get-Content $p -Raw) -match 'Commit hash: abc') 'module report failed' }
It '20 final session report generation' { $p=New-UndiesSessionReport -Root $RunRoot -SessionId 'S' -ModuleResults @([pscustomobject]@{module_id='UND-001';status='GREEN'}); Assert (Test-Path $p) 'session report failed' }
It '21 corrupt-state detection' { 'not json'|Set-Content (Join-Path $RunRoot '.undies/recovery/BAD.checkpoint.json'); $r=Test-UndiesRecoveryState -Root $RunRoot -SessionId 'BAD'; Assert ($r.status -eq 'RED') 'corrupt state accepted' }
It '22 workspace-boundary enforcement' { Assert (-not (Test-UndiesPathInsideRoot -Root $RunRoot -Path '..\outside.txt')) 'outside path allowed' }
It '23 OneDrive protection' { $blocked=$false; try{Assert-UndiesWorkspaceSafe -Root 'C:\Users\Example\OneDrive\UNDIES'|Out-Null}catch{$blocked=$true}; Assert $blocked 'OneDrive allowed' }
It '24 offline foundation operation' { $r=Test-UndiesContracts -Root $Root; Assert $r.Passed 'contracts failed' }
It '25 help command' { $out=& (Join-Path $Root 'UNDIES.ps1') help; Assert (($out -join ' ') -match 'UNDIES 0.1.0-alpha.1') 'help failed' }
It '26 doctor command' { $json=& (Join-Path $Root 'UNDIES.ps1') doctor | ConvertFrom-Json; Assert ($json.status -eq 'GREEN') 'doctor not GREEN' }
It '27 portable single-file initialization' { & (Join-Path $Root 'build/package-undies.ps1') | Out-Null; $Portable=Join-Path $env:TEMP ('undies-portable-'+[guid]::NewGuid().ToString('N')); New-Item -ItemType Directory -Force -Path $Portable|Out-Null; Copy-Item (Join-Path $Root 'dist/UNDIES.ps1') $Portable; $m=& (Join-Path $Portable 'UNDIES.ps1') initialize | ConvertFrom-Json; Assert ($m.version -eq '0.1.0-alpha.1' -and (Test-Path (Join-Path $Portable '.undies/config/project.json'))) 'portable init failed'; Remove-Item $Portable -Recurse -Force }
It '28 portable single-file session lifecycle' { $Portable=Join-Path $env:TEMP ('undies-portable-'+[guid]::NewGuid().ToString('N')); New-Item -ItemType Directory -Force -Path $Portable|Out-Null; Copy-Item (Join-Path $Root 'dist/UNDIES.ps1') $Portable; $s=& (Join-Path $Portable 'UNDIES.ps1') session-start | ConvertFrom-Json; $c=& (Join-Path $Portable 'UNDIES.ps1') session-close -SessionId $s.session_id | ConvertFrom-Json; Assert ($c.final_status -eq 'COMPLETE') 'portable session failed'; Remove-Item $Portable -Recurse -Force }
It '29 safe repeated portable initialization' { $Portable=Join-Path $env:TEMP ('undies-portable-'+[guid]::NewGuid().ToString('N')); New-Item -ItemType Directory -Force -Path $Portable|Out-Null; Copy-Item (Join-Path $Root 'dist/UNDIES.ps1') $Portable; $a=& (Join-Path $Portable 'UNDIES.ps1') initialize | ConvertFrom-Json; $b=& (Join-Path $Portable 'UNDIES.ps1') initialize | ConvertFrom-Json; Assert ($a.created_date -eq $b.created_date) 'portable init not idempotent'; Remove-Item $Portable -Recurse -Force }
It '30 Git metadata inspection without modification' { $Safe='D:/GITHUB/undies'; $before=git -c safe.directory=$Safe status --short; $null=git -c safe.directory=$Safe remote get-url origin; $null=git -c safe.directory=$Safe branch --show-current; $after=git -c safe.directory=$Safe status --short; Assert (($before -join "`n") -eq ($after -join "`n")) 'git inspection modified status' }
foreach($script in @('UND-004.Tests.ps1','UND-005.Tests.ps1','UND-006.Tests.ps1','UND-007.Tests.ps1','UND-008.Tests.ps1','UND-009.Tests.ps1')){ & (Join-Path $Root "tests/foundation/$script") | Out-Null }
} finally { if(Test-Path $RunRoot){ Remove-Item -LiteralPath $RunRoot -Recurse -Force -ErrorAction SilentlyContinue } }
$summary=[pscustomobject]@{passed=$script:Passed;failed=$script:Failed;skipped=$script:Skipped;results=$script:Results}
$reportPath=Join-Path $Root '.undies/reports/foundation-test-results.json'; New-Item -ItemType Directory -Force -Path (Split-Path -Parent $reportPath)|Out-Null; $summary|ConvertTo-Json -Depth 20|Set-Content $reportPath -Encoding UTF8
Write-Host ("TOTAL passed={0} failed={1} skipped={2}" -f $script:Passed,$script:Failed,$script:Skipped)
if($script:Failed -gt 0){ exit 1 }
exit 0

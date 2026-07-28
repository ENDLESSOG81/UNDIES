$ErrorActionPreference='Stop'
$Root = Join-Path (Get-Location).Path 'tests/fixtures/reporting-recovery'
if(Test-Path $Root){ Remove-Item -LiteralPath $Root -Recurse -Force }
New-Item -ItemType Directory -Force -Path $Root | Out-Null
. (Join-Path (Get-Location).Path 'src/bootstrap/Core.ps1')
. (Join-Path (Get-Location).Path 'src/reporting/ReportEngine.ps1')
. (Join-Path (Get-Location).Path 'src/recovery/RecoveryEngine.ps1')
function Assert($Condition,$Message){ if(-not $Condition){ throw $Message } }
$mr=New-UndiesModuleReport -Root $Root -Report @{SessionId='S9';ModuleId='UND-009';ModuleName='Reporting';Objective='test';Status='GREEN';CommitHash='abc123';PushResult='pushed'}
Assert (Test-Path $mr) 'module report missing'
$mrt=Get-Content $mr -Raw; Assert ($mrt -match 'Commit hash: abc123' -and $mrt -match 'Push result: pushed') 'module report missing git fields'
$sr=New-UndiesSessionReport -Root $Root -SessionId 'S9' -ModuleResults @([pscustomobject]@{module_id='UND-001';status='GREEN'},[pscustomobject]@{module_id='UND-002';status='RED'}) -FinalVerdict 'RED' -StartingCommit 'start' -EndingCommit 'end' -CommitHistory @('a','b') -PushResults @('ok')
Assert (Test-Path $sr) 'session report missing'
$srt=Get-Content $sr -Raw; Assert ($srt -match 'Starting commit: start' -and $srt -match 'Final verdict: RED') 'session report fields missing'
$q=[pscustomobject]@{completed=@('UND-001');pending=@('UND-002');stopped=@('UND-002')}
Save-UndiesRecoveryCheckpoint -Root $Root -SessionId 'S9' -ModuleId 'UND-002' -Checkpoint 'red-stop' -Queue $q | Out-Null
$state=Test-UndiesRecoveryState -Root $Root -SessionId 'S9'; Assert ($state.status -eq 'GREEN' -and $state.module_id -eq 'UND-002') 'recovery checkpoint failed'
'not json'|Set-Content -LiteralPath (Join-Path $Root '.undies/recovery/BAD.checkpoint.json')
$bad=Test-UndiesRecoveryState -Root $Root -SessionId 'BAD'; Assert ($bad.status -eq 'RED' -and $bad.repair_instruction) 'corrupt recovery not refused'
'UND-009_TEST passed=5 failed=0 skipped=0'




$ErrorActionPreference='Stop'
. (Join-Path (Get-Location).Path 'src/bootstrap/Core.ps1')
. (Join-Path (Get-Location).Path 'src/gates/GateEngine.ps1')
. (Join-Path (Get-Location).Path 'src/dependencies/DependencyEngine.ps1')
. (Join-Path (Get-Location).Path 'src/modules/ModuleQueue.ps1')
. (Join-Path (Get-Location).Path 'src/reporting/ReportEngine.ps1')
function Assert($Condition,$Message){ if(-not $Condition){ throw $Message } }
function Dep { New-UndiesDependencyRecord -DependencyId 'BLUE-TEST' -Type 'OPERATOR_INPUT' -ExactName 'Operator confirmation' -ReasonRequired 'Exact operator input required' -ExpectedFormat 'non-secret confirmation' -Sensitive:$false -SourceOrOwner 'Human operator' -ManualAction 'Provide confirmation' -PowerShellAction '$value = Read-Host "Confirmation"' -ValidationCommand 'Test-Path .' -SuccessCondition 'True' -FailureCondition 'Remain BLUE' -ResumeModule 'UND-011' -ResumeCheckpoint 'blue-checkpoint' }
$d=New-UndiesGateDecision -ModuleId 'UND-011' -Status 'BLUE' -Reason 'pause' -DependencyRecord (Dep); Assert ($d.status -eq 'BLUE') 'BLUE not canonical'
$d=New-UndiesGateDecision -ModuleId 'UND-011' -Status 'WAITING_FOR_EXTERNAL_DEPENDENCY' -Reason 'legacy' -DependencyRecord (Dep); Assert ($d.status -eq 'BLUE' -and $d.source_status -eq 'WAITING_FOR_EXTERNAL_DEPENDENCY') 'legacy alias failed'
$failed=$false; try{New-UndiesGateDecision -ModuleId 'UND-011' -Status 'BLUE' -Reason 'missing'|Out-Null}catch{$failed=$true}; Assert $failed 'BLUE missing dependency accepted'
$q=New-UndiesModuleQueue @([pscustomobject]@{module_id='UND-011';dependencies=@()},[pscustomobject]@{module_id='UND-012';dependencies=@()}); $q=Start-UndiesNextModule $q; $q=Complete-UndiesActiveModule $q 'BLUE' -DependencyRecord (Dep); Assert ($q.active.status -eq 'BLUE' -and $q.pending[0].module_id -eq 'UND-012') 'BLUE queue pause failed'
$failed=$false; try{Resume-UndiesModuleQueue $q -DependencyValidated:$false|Out-Null}catch{$failed=$true}; Assert $failed 'BLUE resume bypassed validation'
$q=Resume-UndiesModuleQueue $q -DependencyValidated:$true; Assert ($q.active.status -eq 'IN_PROGRESS') 'BLUE validated resume failed'
$txt=Format-UndiesManualAction -Module ([pscustomobject]@{module_id='UND-011';module_name='Blue'}) -Dependency (Dep); Assert ($txt -match 'BLUE GATE' -and $txt -match 'POWERSHELL ACTION' -and $txt -match 'VALIDATION COMMAND') 'manual action missing fields'
$Root=Join-Path $env:TEMP ('undies-011-'+[guid]::NewGuid().ToString('N')); New-Item -ItemType Directory -Force -Path $Root|Out-Null; $p=New-UndiesSessionReport -Root $Root -SessionId 'S' -ModuleResults @([pscustomobject]@{module_id='A';status='WAITING_FOR_EXTERNAL_DEPENDENCY'}); $r=Get-Content $p -Raw; Remove-Item $Root -Recurse -Force; Assert ($r -match 'BLUE=1') 'legacy report total failed'
'UND-011_TEST passed=8 failed=0 skipped=0'

$ErrorActionPreference='Stop'
. (Join-Path (Get-Location).Path 'src/bootstrap/Core.ps1')
. (Join-Path (Get-Location).Path 'src/modules/ModuleQueue.ps1')
function Assert($Condition,$Message){ if(-not $Condition){ throw $Message } }
$single=New-UndiesModuleQueue @([pscustomobject]@{module_id='UND-001';dependencies=@()})
$single=Start-UndiesNextModule $single; Assert ($single.active.module_id -eq 'UND-001') 'single active failed'
$mods=1..10|ForEach-Object{[pscustomobject]@{module_id=('UND-{0:000}' -f $_);dependencies=@()}}
$q=New-UndiesModuleQueue $mods; Assert ($q.pending.Count -eq 10) 'ten queue failed'
$dupFailed=$false; try{ New-UndiesModuleQueue @([pscustomobject]@{module_id='X';dependencies=@()},[pscustomobject]@{module_id='X';dependencies=@()})|Out-Null }catch{$dupFailed=$true}; Assert $dupFailed 'duplicate accepted'
$depFailed=$false; try{ New-UndiesModuleQueue @([pscustomobject]@{module_id='A';dependencies=@(@{module_id='B'})})|Out-Null }catch{$depFailed=$true}; Assert $depFailed 'missing dependency accepted'
$q=New-UndiesModuleQueue $mods; $q=Start-UndiesNextModule $q; $twoActiveFailed=$false; try{ Start-UndiesNextModule $q|Out-Null }catch{$twoActiveFailed=$true}; Assert $twoActiveFailed 'two active allowed'
$q=Complete-UndiesActiveModule $q 'RED'; Assert ($q.stopped.Count -eq 1 -and $q.failed_module -eq 'UND-001') 'RED did not stop'
$startFailed=$false; try{ Start-UndiesNextModule $q|Out-Null }catch{$startFailed=$true}; Assert $startFailed 'started after RED'
$q=Resume-UndiesModuleQueue $q; Assert ($q.pending[0].module_id -eq 'UND-001') 'resume did not start at stopped module'
'UND-005_TEST passed=8 failed=0 skipped=0'

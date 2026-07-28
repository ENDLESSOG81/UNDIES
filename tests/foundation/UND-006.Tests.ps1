$ErrorActionPreference='Stop'
. (Join-Path (Get-Location).Path 'src/bootstrap/Core.ps1')
. (Join-Path (Get-Location).Path 'src/gates/GateEngine.ps1')
function Assert($Condition,$Message){ if(-not $Condition){ throw $Message } }
$d=New-UndiesGateDecision -ModuleId 'UND-006' -Status 'GREEN' -Reason 'passed'; Assert ($d.continuation_decision -eq 'advance') 'GREEN did not advance'
$d=New-UndiesGateDecision -ModuleId 'UND-006' -Status 'YELLOW' -Reason 'warning safe' -BlocksNextModule:$false; Assert ($d.continuation_decision -eq 'advance') 'non-blocking YELLOW did not advance'
$d=New-UndiesGateDecision -ModuleId 'UND-006' -Status 'YELLOW' -Reason 'warning blocks' -BlocksNextModule:$true; Assert ($d.continuation_decision -eq 'stop') 'blocking YELLOW did not stop'
$d=New-UndiesGateDecision -ModuleId 'UND-006' -Status 'RED' -Reason 'failed'; Assert ($d.continuation_decision -eq 'stop') 'RED did not stop'
$d=New-UndiesGateDecision -ModuleId 'UND-006' -Status 'BLOCKED' -Reason 'missing foundational input'; Assert ($d.continuation_decision -eq 'stop') 'BLOCKED did not stop'
$unknownFailed=$false; try{ New-UndiesGateDecision -ModuleId 'UND-006' -Status 'NOPE' -Reason 'bad'|Out-Null }catch{$unknownFailed=$true}; Assert $unknownFailed 'unknown status accepted'
$yellowFailed=$false; try{ New-UndiesGateDecision -ModuleId 'UND-006' -Status 'YELLOW' -Reason 'no blocks flag'|Out-Null }catch{$yellowFailed=$true}; Assert $yellowFailed 'YELLOW without blocks flag accepted'
$waitFailed=$false; try{ New-UndiesGateDecision -ModuleId 'UND-006' -Status 'WAITING_FOR_EXTERNAL_DEPENDENCY' -Reason 'needs exact dependency'|Out-Null }catch{$waitFailed=$true}; Assert $waitFailed 'waiting without dependency accepted'
'UND-006_TEST passed=8 failed=0 skipped=0'

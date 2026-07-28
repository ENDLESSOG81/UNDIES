param()
$ErrorActionPreference='Stop'
$Root = Join-Path (Get-Location).Path 'tests/fixtures/session-engine'
if(Test-Path $Root){ Remove-Item -LiteralPath $Root -Recurse -Force }
New-Item -ItemType Directory -Force -Path $Root | Out-Null
. (Join-Path (Get-Location).Path 'src/bootstrap/Core.ps1')
. (Join-Path (Get-Location).Path 'src/session/SessionEngine.ps1')
function Assert($Condition,$Message){ if(-not $Condition){ throw $Message } }
$s=New-UndiesSession -Root $Root -PendingModules @('UND-004')
Assert ($s.session_id -match '^UND-UND-\d{8}-\d{3}$') 'bad session id'
Assert ($s.start_time_local -and $s.start_time_utc) 'timestamps missing'
$r=Read-UndiesSession -Root $Root -SessionId $s.session_id
Assert ($r.session_id -eq $s.session_id) 'read mismatch'
$r.current_module='UND-004'; $u=Update-UndiesSession -Root $Root -Session $r
Assert ($u.current_module -eq 'UND-004') 'update failed'
$resume=Resume-UndiesSession -Root $Root
Assert ($resume.session_id -eq $s.session_id) 'resume failed'
$c=Close-UndiesSession -Root $Root -SessionId $s.session_id
Assert ($c.final_status -eq 'COMPLETE') 'close failed'
$reopenFailed=$false; try { Close-UndiesSession -Root $Root -SessionId $s.session_id | Out-Null } catch { $reopenFailed=$true }
Assert $reopenFailed 'completed session reopened'
'not json' | Set-Content -LiteralPath (Join-Path $Root '.undies/sessions/corrupt.json')
$list=@(Get-UndiesSessions -Root $Root | Where-Object session_id -eq 'corrupt')
Assert ($list[0].final_status -eq 'CORRUPT') 'corrupt session not detected'
'UND-004_TEST passed=7 failed=0 skipped=0'

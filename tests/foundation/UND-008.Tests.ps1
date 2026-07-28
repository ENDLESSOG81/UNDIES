$ErrorActionPreference='Stop'
$Root = Join-Path (Get-Location).Path 'tests/fixtures/evidence-engine'
if(Test-Path $Root){ Remove-Item -LiteralPath $Root -Recurse -Force }
New-Item -ItemType Directory -Force -Path $Root | Out-Null
. (Join-Path (Get-Location).Path 'src/bootstrap/Core.ps1')
. (Join-Path (Get-Location).Path 'src/evidence/EvidenceEngine.ps1')
function Assert($Condition,$Message){ if(-not $Condition){ throw $Message } }
$e1=Add-UndiesEvidenceEvent -Root $Root -SessionId 'S1' -ModuleId 'UND-008' -EventType 'module_start' -Action 'start' -Details @{ token='secret'; note='ok' }
Start-Sleep -Milliseconds 20
$e2=Add-UndiesEvidenceEvent -Root $Root -SessionId 'S1' -ModuleId 'UND-008' -EventType 'module_completion' -Action 'complete' -Details @{ authorization='Bearer abcdef123456' }
$p=Get-UndiesEvidencePath -Root $Root -SessionId 'S1'
$lines=Get-Content -LiteralPath $p
Assert ($lines.Count -eq 2) 'append count mismatch'
$parsed=$lines|ForEach-Object{$_|ConvertFrom-Json}
Assert ($parsed[0].event_id -ne $parsed[1].event_id) 'event IDs not unique'
Assert ($parsed[0].timestamp_local -and $parsed[0].timestamp_utc) 'timestamps missing'
Assert ($parsed[0].session_id -eq 'S1' -and $parsed[0].module_id -eq 'UND-008') 'correlation missing'
Assert ((Get-Content $p -Raw) -notmatch 'secret|abcdef') 'sensitive value leaked'
$integrity=Test-UndiesEvidenceIntegrity -Path $p; Assert ($integrity.passed -and $integrity.events -eq 2) 'integrity failed'
'{bad json' | Set-Content -LiteralPath (Join-Path $Root '.undies/evidence/bad.jsonl')
$badFailed=$false; try{ Test-UndiesEvidenceIntegrity -Path (Join-Path $Root '.undies/evidence/bad.jsonl')|Out-Null }catch{$badFailed=$true}; Assert $badFailed 'malformed event accepted'
$inventory=@(Get-UndiesFileInventory -Root $Root); Assert ($inventory.Count -gt 0 -and $inventory[0].hash) 'file inventory missing hashes'
'UND-008_TEST passed=8 failed=0 skipped=0'

function Get-UndiesEvidencePath { param([string]$Root=(Get-Location).Path,[string]$SessionId='foundation') New-Item -ItemType Directory -Force -Path (Join-Path $Root '.undies/evidence') | Out-Null; return (Join-Path $Root ".undies/evidence/$SessionId.jsonl") }
function Add-UndiesEvidenceEvent {
    param([string]$Root=(Get-Location).Path,[string]$SessionId='foundation',[string]$ModuleId,[string]$EventType,[string]$Actor='UNDIES',[string]$Action,[string]$Result='RECORDED',$Details=@{},[array]$EvidenceReferences=@())
    $safeDetails = Protect-UndiesText ($Details | ConvertTo-Json -Depth 20)
    $event=[ordered]@{ event_id=[guid]::NewGuid().ToString(); session_id=$SessionId; module_id=$ModuleId; event_type=$EventType; timestamp_local=Get-UndiesCentralTime; timestamp_utc=Get-UndiesUtcTime; actor=$Actor; action=$Action; result=$Result; sanitized_details=$safeDetails; evidence_references=@($EvidenceReferences) }
    $line = $event | ConvertTo-Json -Depth 20 -Compress
    Add-Content -LiteralPath (Get-UndiesEvidencePath -Root $Root -SessionId $SessionId) -Value $line -Encoding UTF8
    return [pscustomobject]$event
}
function Test-UndiesEvidenceIntegrity { param([string]$Path) $n=0; foreach($line in Get-Content -LiteralPath $Path -ErrorAction Stop){ $n++; try{ $e=$line|ConvertFrom-Json -ErrorAction Stop; foreach($f in @('event_id','session_id','event_type','timestamp_local','timestamp_utc','actor','action','result')){ if(-not ($e.PSObject.Properties.Name -contains $f)){ throw "missing $f" } } } catch { throw "Malformed evidence line $n in ${Path}: $($_.Exception.Message)" } }; return [pscustomobject]@{ passed=$true; events=$n } }
function Get-UndiesFileInventory { param([string]$Root=(Get-Location).Path) Get-ChildItem -LiteralPath $Root -Recurse -File -Force | Where-Object { $_.FullName -notmatch '\\.git\\' } | ForEach-Object { [pscustomobject]@{ path=$_.FullName.Substring($Root.Length).TrimStart('\'); length=$_.Length; hash=(Get-FileHash -LiteralPath $_.FullName -Algorithm SHA256).Hash } } }



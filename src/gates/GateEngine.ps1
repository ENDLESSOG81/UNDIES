function New-UndiesGateDecision {
    param([string]$Root=(Get-Location).Path,[string]$SessionId,[string]$ModuleId,[Parameter(Mandatory=$true)][string]$Status,[string]$Reason,[array]$ValidationResults=@(),[array]$FailedChecks=@(),[array]$Warnings=@(),[Nullable[bool]]$BlocksNextModule=$null,[array]$EvidenceReferences=@(),[string]$ResumeRequirement=$null,$DependencyRecord=$null)
    if ((Get-UndiesStatusValues) -notcontains $Status) { throw "Unknown status fails closed: $Status" }
    if ([string]::IsNullOrWhiteSpace($Reason)) { throw 'Gate decision requires a human-readable reason.' }
    if ($Status -eq 'YELLOW' -and $null -eq $BlocksNextModule) { throw 'YELLOW requires blocks_next_module true or false.' }
    if ($Status -eq 'WAITING_FOR_EXTERNAL_DEPENDENCY') {
        if (-not $DependencyRecord) { throw 'WAITING_FOR_EXTERNAL_DEPENDENCY requires a complete dependency record.' }
        foreach($f in @('dependency_id','dependency_type','exact_name','reason_required','expected_value_or_format','sensitive','manual_action','powershell_action','validation_command','success_condition','resume_module','resume_checkpoint')){ if(-not ($DependencyRecord.PSObject.Properties.Name -contains $f)){ throw "Incomplete dependency record missing $f" } }
    }
    $blocks = if ($BlocksNextModule -eq $null) { $false } else { [bool]$BlocksNextModule }
    $blocking = $false; $continue = $false
    switch ($Status) { 'GREEN' { $continue=$true } 'YELLOW' { $blocking=$blocks; $continue=(-not $blocks) } 'RED' { $blocking=$true } 'BLOCKED' { $blocking=$true } 'WAITING_FOR_EXTERNAL_DEPENDENCY' { $blocking=$true } default { $blocking=$true } }
    $decision = [ordered]@{ id=[guid]::NewGuid().ToString(); status=$Status; decision_timestamp_local=Get-UndiesCentralTime; decision_timestamp_utc=Get-UndiesUtcTime; module_id=$ModuleId; validation_results=@($ValidationResults); failed_checks=@($FailedChecks); warnings=@($Warnings); blocking_effect=$blocking; continuation_decision=if($continue){'advance'}else{'stop'}; blocks_next_module=$blocks; decision_reason=$Reason; evidence_references=@($EvidenceReferences); resume_requirement=$ResumeRequirement; dependency_record=$DependencyRecord }
    if ($SessionId) { $s=Read-UndiesSession -Root $Root -SessionId $SessionId; $arr=@($s.gate_decisions); $arr += $decision; $s.gate_decisions=$arr; if($blocking){$s.final_status='STOPPED';$s.status='STOPPED';$s.failed_module=$ModuleId}; Update-UndiesSession -Root $Root -Session $s | Out-Null }
    return [pscustomobject]$decision
}

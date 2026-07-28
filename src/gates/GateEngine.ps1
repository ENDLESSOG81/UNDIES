function Test-UndiesBlueDependencyRecord {
    param($DependencyRecord)
    if(-not $DependencyRecord){ throw 'BLUE requires a complete dependency record.' }
    foreach($f in @('dependency_id','dependency_type','exact_name','reason_required','expected_value_or_format','sensitive','source_or_owner','manual_action','powershell_action','validation_command','success_condition','failure_condition','resume_module','resume_checkpoint')){
        if(-not ($DependencyRecord.PSObject.Properties.Name -contains $f)){ throw "BLUE dependency record missing $f" }
        if($f -ne 'sensitive' -and ($null -eq $DependencyRecord.$f -or [string]::IsNullOrWhiteSpace([string]$DependencyRecord.$f))){ throw "BLUE dependency record has blank $f" }
    }
}
function New-UndiesGateDecision {
    param([string]$Root=(Get-Location).Path,[string]$SessionId,[string]$ModuleId,[Parameter(Mandatory=$true)][string]$Status,[string]$Reason,[array]$ValidationResults=@(),[array]$FailedChecks=@(),[array]$Warnings=@(),[Nullable[bool]]$BlocksNextModule=$null,[array]$EvidenceReferences=@(),[string]$ResumeRequirement=$null,$DependencyRecord=$null)
    if(-not(Test-UndiesKnownStatus $Status)){ throw "Unknown status fails closed: $Status" }
    $sourceStatus=$Status; $canonicalStatus=ConvertTo-UndiesCanonicalStatus $Status
    if([string]::IsNullOrWhiteSpace($Reason)){ throw 'Gate decision requires a human-readable reason.' }
    if($canonicalStatus -eq 'YELLOW' -and $null -eq $BlocksNextModule){ throw 'YELLOW requires blocks_next_module true or false.' }
    if($canonicalStatus -eq 'BLUE'){ Test-UndiesBlueDependencyRecord -DependencyRecord $DependencyRecord; $BlocksNextModule=$true; $ResumeRequirement=$DependencyRecord.resume_checkpoint }
    $blocks = if($BlocksNextModule -eq $null){$false}else{[bool]$BlocksNextModule}
    $blocking=$false; $continue='stop'
    switch($canonicalStatus){
        'GREEN' { $continue='advance' }
        'YELLOW' { $blocking=$blocks; $continue=if($blocks){'stop'}else{'advance'} }
        'BLUE' { $blocking=$true; $continue='PAUSE' }
        'RED' { $blocking=$true; $continue='stop' }
        'BLOCKED' { $blocking=$true; $continue='stop' }
        default { $blocking=$true; $continue='stop' }
    }
    $decision=[ordered]@{ id=[guid]::NewGuid().ToString(); status=$canonicalStatus; canonical_status=$canonicalStatus; source_status=$sourceStatus; module_id=$ModuleId; decision_timestamp_local=Get-UndiesCentralTime; decision_timestamp_utc=Get-UndiesUtcTime; validation_results=@($ValidationResults); failed_checks=@($FailedChecks); warnings=@($Warnings); blocking_effect=$blocking; blocks_next_module=$blocks; continuation_decision=$continue; decision_reason=$Reason; evidence_references=@($EvidenceReferences); resume_requirement=$ResumeRequirement; dependency_record=$DependencyRecord }
    if($canonicalStatus -eq 'BLUE'){
        $decision.dependency_id=$DependencyRecord.dependency_id; $decision.dependency_type=$DependencyRecord.dependency_type; $decision.required_item=$DependencyRecord.exact_name; $decision.reason=$DependencyRecord.reason_required; $decision.expected_format=$DependencyRecord.expected_value_or_format; $decision.is_sensitive=[bool]$DependencyRecord.sensitive; $decision.source_or_owner=$DependencyRecord.source_or_owner; $decision.manual_action=$DependencyRecord.manual_action; $decision.powershell_action=$DependencyRecord.powershell_action; $decision.validation_command=$DependencyRecord.validation_command; $decision.success_condition=$DependencyRecord.success_condition; $decision.failure_condition=$DependencyRecord.failure_condition; $decision.resume_module=$DependencyRecord.resume_module; $decision.resume_checkpoint=$DependencyRecord.resume_checkpoint
    }
    if($SessionId){ $s=Read-UndiesSession -Root $Root -SessionId $SessionId; $arr=@($s.gate_decisions); $arr += $decision; $s.gate_decisions=$arr; if($canonicalStatus -eq 'BLUE'){ $s.status='BLUE'; $s.final_status='BLUE'; $s.current_module=$ModuleId; $s.resume_point=$DependencyRecord.resume_checkpoint; $s.blue_dependency=$DependencyRecord } elseif($blocking){$s.final_status='STOPPED';$s.status='STOPPED';$s.failed_module=$ModuleId}; Update-UndiesSession -Root $Root -Session $s|Out-Null }
    return [pscustomobject]$decision
}

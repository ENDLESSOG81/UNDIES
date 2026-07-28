function Get-UndiesDependencyTypes { return @('FILE','DIRECTORY','URL','REPOSITORY_URL','API_TOKEN','PROJECT_URL','ENVIRONMENT_VARIABLE','APPLICATION','ACCOUNT_AUTHORIZATION','NETWORK_ACCESS','HUMAN_APPROVAL','SERVICE_CONFIGURATION') }
function New-UndiesDependencyRecord {
    param([string]$DependencyId,[string]$Type,[string]$ExactName,[string]$ReasonRequired,[string]$ExpectedFormat,[bool]$Sensitive=$false,[string]$SourceOrOwner='Human operator',[string]$ManualAction,[string]$PowerShellAction,[string]$ValidationCommand,[string]$SuccessCondition,[string]$FailureCondition='Validation fails',[string]$ResumeModule,[string]$ResumeCheckpoint)
    if((Get-UndiesDependencyTypes) -notcontains $Type){throw "Unsupported dependency type: $Type"}
    foreach($pair in @{DependencyId=$DependencyId;ExactName=$ExactName;ReasonRequired=$ReasonRequired;ExpectedFormat=$ExpectedFormat;ManualAction=$ManualAction;PowerShellAction=$PowerShellAction;ValidationCommand=$ValidationCommand;SuccessCondition=$SuccessCondition;ResumeModule=$ResumeModule;ResumeCheckpoint=$ResumeCheckpoint}.GetEnumerator()){ if([string]::IsNullOrWhiteSpace([string]$pair.Value)){ throw "Dependency field required: $($pair.Key)" } }
    return [pscustomobject]@{ dependency_id=$DependencyId; dependency_type=$Type; exact_name=$ExactName; reason_required=$ReasonRequired; expected_value_or_format=$ExpectedFormat; sensitive=$Sensitive; source_or_owner=$SourceOrOwner; manual_action=$ManualAction; powershell_action=$PowerShellAction; validation_command=$ValidationCommand; success_condition=$SuccessCondition; failure_condition=$FailureCondition; resume_module=$ResumeModule; resume_checkpoint=$ResumeCheckpoint }
}
function Format-UndiesManualAction {
    param($Module,$Dependency)
    $notice = if($Dependency.sensitive){'Sensitive value: never paste into logs, evidence, reports, examples, or command history. Use an interactive prompt such as Read-Host -AsSecureString or configure it only in the approved local secret location.'}else{'No sensitive value expected.'}
    @("========================================================","MANUAL ACTION REQUIRED","========================================================","MODULE:",("$($Module.module_id) $($Module.module_name)"),"REASON:",$Dependency.reason_required,"REQUIRED ITEM:",$Dependency.exact_name,"EXPECTED FORMAT:",$Dependency.expected_value_or_format,"POWERSHELL ACTION:",$Dependency.powershell_action,"VALIDATION COMMAND:",$Dependency.validation_command,"SUCCESS CONDITION:",$Dependency.success_condition,"RESUME POINT:",("$($Dependency.resume_module) / $($Dependency.resume_checkpoint)"),"SECURITY NOTICE:",$notice,"========================================================") -join [Environment]::NewLine
}
function Test-UndiesDependency {
    param($Dependency)
    switch($Dependency.dependency_type){
        'FILE' { return Test-Path -LiteralPath $Dependency.exact_name -PathType Leaf }
        'DIRECTORY' { return Test-Path -LiteralPath $Dependency.exact_name -PathType Container }
        'ENVIRONMENT_VARIABLE' { return -not [string]::IsNullOrWhiteSpace([Environment]::GetEnvironmentVariable($Dependency.exact_name)) }
        'APPLICATION' { return $null -ne (Get-Command $Dependency.exact_name -ErrorAction SilentlyContinue) }
        'URL' { return [Uri]::IsWellFormedUriString($Dependency.exact_name, [UriKind]::Absolute) }
        'REPOSITORY_URL' { return [Uri]::IsWellFormedUriString($Dependency.exact_name, [UriKind]::Absolute) }
        'PROJECT_URL' { return [Uri]::IsWellFormedUriString($Dependency.exact_name, [UriKind]::Absolute) }
        default { return $false }
    }
}

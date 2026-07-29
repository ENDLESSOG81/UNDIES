function Join-UndiesReportList { param([array]$Items) if($Items -and $Items.Count){ return ($Items -join '; ') } return 'NONE' }
function Get-UndiesReportValue { param([hashtable]$Report,[string]$Key,[string]$Default='') if($Report.ContainsKey($Key) -and $null -ne $Report[$Key] -and [string]$Report[$Key] -ne ''){ return [string]$Report[$Key] } return $Default }
function New-UndiesModuleReport {
    param([string]$Root=(Get-Location).Path,[hashtable]$Report)
    $ModuleId=Get-UndiesReportValue $Report 'ModuleId' 'UNKNOWN'
    $SessionId=Get-UndiesReportValue $Report 'SessionId' 'foundation'
    $source=Get-UndiesReportValue $Report 'SourceStatus' (Get-UndiesReportValue $Report 'Status' 'UNKNOWN')
    $canonical=ConvertTo-UndiesCanonicalStatus $source
    $path=Join-Path $Root ".undies/reports/$SessionId-$ModuleId-report.md"
    New-Item -ItemType Directory -Force -Path (Split-Path -Parent $path)|Out-Null
    $body=@(
        '# UNDIES Module Report','',
        ('Module ID: {0}' -f $ModuleId),
        ('Module name: {0}' -f (Get-UndiesReportValue $Report 'ModuleName' 'UNKNOWN')),
        ('Objective: {0}' -f (Get-UndiesReportValue $Report 'Objective' 'UNKNOWN')),
        ('Start time: {0}' -f (Get-UndiesReportValue $Report 'StartTime' 'recorded in evidence')),
        ('End time: {0}' -f (Get-UndiesReportValue $Report 'EndTime' (Get-UndiesCentralTime))),
        ('Status: {0}' -f $canonical),
        ('Source status: {0}' -f $source),
        ('Canonical status: {0}' -f $canonical),
        ('Commands executed: {0}' -f (Join-UndiesReportList $Report['Commands'])),
        ('Files created: {0}' -f (Join-UndiesReportList $Report['FilesCreated'])),
        ('Files modified: {0}' -f (Join-UndiesReportList $Report['FilesModified'])),
        ('Files deleted: {0}' -f (Join-UndiesReportList $Report['FilesDeleted'])),
        ('Tests executed: {0}' -f (Join-UndiesReportList $Report['Tests'])),
        ('Evidence locations: {0}' -f (Get-UndiesReportValue $Report 'Evidence' ".undies/evidence/$SessionId.jsonl")),
        ('Warnings: {0}' -f (Join-UndiesReportList $Report['Warnings'])),
        ('Failures: {0}' -f (Join-UndiesReportList $Report['Failures'])),
        ('Dependencies: {0}' -f (Join-UndiesReportList $Report['Dependencies'])),
        ('Manual actions: {0}' -f (Join-UndiesReportList $Report['ManualActions'])),
        ('Continuation decision: {0}' -f (Get-UndiesReportValue $Report 'ContinuationDecision' $(if($canonical -eq 'BLUE'){'PAUSE'}else{'advance'}))),
        ('Resume point: {0}' -f (Get-UndiesReportValue $Report 'ResumePoint' 'NONE')),
        ('Commit hash: {0}' -f (Get-UndiesReportValue $Report 'CommitHash' 'NONE')),
        ('Push result: {0}' -f (Get-UndiesReportValue $Report 'PushResult' 'NONE'))
    )
    if($canonical -eq 'BLUE'){
        $body += @('BLUE explanation: BLUE is a safe pause, not a failure.',('Required item: {0}' -f (Get-UndiesReportValue $Report 'RequiredItem' 'See dependency record')),('Sensitive: {0}' -f (Get-UndiesReportValue $Report 'Sensitive' 'UNKNOWN')),('Validation command: {0}' -f (Get-UndiesReportValue $Report 'ValidationCommand' 'See dependency record')))
    }
    $body|Set-Content -LiteralPath $path -Encoding UTF8
    return $path
}
function New-UndiesSessionReport { param([string]$Root=(Get-Location).Path,[string]$SessionId='foundation',[array]$ModuleResults=@(),[string]$FinalVerdict='GREEN',[string]$RepositoryUrl='https://github.com/ENDLESSOG81/UNDIES.git',[string]$DefaultBranch='main',[string]$WorkingBranch='feature/und-011-blue-gate',[string]$StartingCommit='UNKNOWN',[string]$EndingCommit='UNKNOWN',[array]$CommitHistory=@(),[array]$PushResults=@(),[string]$MainMergeResult='NOT RUN') $path=Join-Path $Root ".undies/reports/$SessionId-session-report.md"; New-Item -ItemType Directory -Force -Path (Split-Path -Parent $path)|Out-Null; $normalized=@($ModuleResults|ForEach-Object{[pscustomobject]@{module_id=$_.module_id;status=(ConvertTo-UndiesCanonicalStatus $_.status);source_status=$_.status}}); $green=@($normalized|Where-Object status -eq 'GREEN').Count; $yellow=@($normalized|Where-Object status -eq 'YELLOW').Count; $blue=@($normalized|Where-Object status -eq 'BLUE').Count; $red=@($normalized|Where-Object status -eq 'RED').Count; $blocked=@($normalized|Where-Object status -eq 'BLOCKED').Count; $body=@('# UNDIES Final Session Report','','Mission ID: UND-REPO-FOUNDATION-001',('Session ID: {0}' -f $SessionId),'Project name: UNDIES','Project code: UND','Version: 0.3.0-alpha.1',('Workspace: {0}' -f (Resolve-Path -LiteralPath $Root).Path),('Repository URL: {0}' -f $RepositoryUrl),('Default branch: {0}' -f $DefaultBranch),('Working branch: {0}' -f $WorkingBranch),('Starting commit: {0}' -f $StartingCommit),('Ending commit: {0}' -f $EndingCommit),'Per-module verdict:'); foreach($m in $normalized){$body += ('- {0}: {1} (source: {2})' -f $m.module_id,$m.status,$m.source_status)}; $body += @(('Status totals: GREEN={0} YELLOW={1} BLUE={2} RED={3} BLOCKED={4}' -f $green,$yellow,$blue,$red,$blocked),'BLUE summary: BLUE is a safe pause for exact external input or authority, not a failure.','Test totals: see tests/run-tests.ps1 and module reports','Evidence summary: see .undies/evidence/','External connections: Git remote push/fetch only','Credentials requested or used: NONE RECORDED','Git actions: normal commits and pushes only',('Commit history: {0}' -f ($CommitHistory -join '; ')),('Push results: {0}' -f ($PushResults -join '; ')),('Main merge result: {0}' -f $MainMergeResult),('Final verdict: {0}' -f $FinalVerdict)); $body|Set-Content -LiteralPath $path -Encoding UTF8; return $path }




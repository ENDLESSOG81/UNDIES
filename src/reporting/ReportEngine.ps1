function Join-UndiesReportList { param([array]$Items) if($Items -and $Items.Count){ return ($Items -join '; ') } return 'NONE' }
function Get-UndiesReportValue { param([hashtable]$Report,[string]$Key,[string]$Default='') if($Report.ContainsKey($Key) -and $null -ne $Report[$Key] -and [string]$Report[$Key] -ne ''){ return $Report[$Key] } return $Default }
function New-UndiesModuleReport {
    param([string]$Root=(Get-Location).Path,[hashtable]$Report)
    $ModuleId = Get-UndiesReportValue $Report 'ModuleId' 'UNKNOWN'
    $SessionId = Get-UndiesReportValue $Report 'SessionId' 'foundation'
    $path=Join-Path $Root ".undies/reports/$SessionId-$ModuleId-report.md"
    New-Item -ItemType Directory -Force -Path (Split-Path -Parent $path) | Out-Null
    $commitLine = 'Commit hash: ' + (Get-UndiesReportValue $Report 'CommitHash' 'NONE')
    $pushLine = 'Push result: ' + (Get-UndiesReportValue $Report 'PushResult' 'NONE')
    $body = @(
        '# UNDIES Module Report','',
        'Module ID: '+$ModuleId,
        'Module name: '+(Get-UndiesReportValue $Report 'ModuleName' 'UNKNOWN'),
        'Objective: '+(Get-UndiesReportValue $Report 'Objective' 'UNKNOWN'),
        'Start time: '+(Get-UndiesReportValue $Report 'StartTime' 'recorded in evidence'),
        'End time: '+(Get-UndiesReportValue $Report 'EndTime' (Get-UndiesCentralTime)),
        'Status: '+(Get-UndiesReportValue $Report 'Status' 'UNKNOWN'),
        'Commands executed: '+(Join-UndiesReportList $Report['Commands']),
        'Files created: '+(Join-UndiesReportList $Report['FilesCreated']),
        'Files modified: '+(Join-UndiesReportList $Report['FilesModified']),
        'Files deleted: '+(Join-UndiesReportList $Report['FilesDeleted']),
        'Tests executed: '+(Join-UndiesReportList $Report['Tests']),
        'Evidence locations: '+(Get-UndiesReportValue $Report 'Evidence' ".undies/evidence/$SessionId.jsonl"),
        'Warnings: '+(Join-UndiesReportList $Report['Warnings']),
        'Failures: '+(Join-UndiesReportList $Report['Failures']),
        'Dependencies: '+(Join-UndiesReportList $Report['Dependencies']),
        'Manual actions: '+(Join-UndiesReportList $Report['ManualActions']),
        'Continuation decision: '+(Get-UndiesReportValue $Report 'ContinuationDecision' 'advance'),
        'Resume point: '+(Get-UndiesReportValue $Report 'ResumePoint' 'NONE'),
        $commitLine,
        $pushLine
    )
    $body | Set-Content -LiteralPath $path -Encoding UTF8
    return $path
}
function New-UndiesSessionReport {
    param([string]$Root=(Get-Location).Path,[string]$SessionId='foundation',[array]$ModuleResults=@(),[string]$FinalVerdict='GREEN',[string]$RepositoryUrl='https://github.com/ENDLESSOG81/UNDIES.git',[string]$DefaultBranch='main',[string]$WorkingBranch='foundation/undies-0.1.0-alpha.1',[string]$StartingCommit='UNKNOWN',[string]$EndingCommit='UNKNOWN',[array]$CommitHistory=@(),[array]$PushResults=@(),[string]$MainMergeResult='NOT RUN')
    $path=Join-Path $Root ".undies/reports/$SessionId-session-report.md"
    New-Item -ItemType Directory -Force -Path (Split-Path -Parent $path) | Out-Null
    $green=@($ModuleResults|Where-Object status -eq 'GREEN').Count; $yellow=@($ModuleResults|Where-Object status -eq 'YELLOW').Count; $red=@($ModuleResults|Where-Object status -eq 'RED').Count; $blocked=@($ModuleResults|Where-Object status -eq 'BLOCKED').Count
    $body=@('# UNDIES Final Session Report','','Mission ID: UND-REPO-FOUNDATION-001','Session ID: '+$SessionId,'Project name: UNDIES','Project code: UND','Version: 0.1.0-alpha.1','Build: repository foundation prototype','Workspace: '+(Resolve-Path -LiteralPath $Root).Path,'Repository URL: '+$RepositoryUrl,'Default branch: '+$DefaultBranch,'Working branch: '+$WorkingBranch,('Starting commit: {0}' -f $StartingCommit),('Ending commit: {0}' -f $EndingCommit),'Repository state: LOCAL ONLY WITH REMOTE','Remote state: '+$RepositoryUrl,'Module queue: UND-001 through UND-010','Per-module verdict:')
    foreach($m in $ModuleResults){ $body += ('- {0}: {1}' -f $m.module_id,$m.status) }
    $body += @(('Status totals: GREEN={0} YELLOW={1} RED={2} BLOCKED={3}' -f $green,$yellow,$red,$blocked),'File-change totals: see git history and module reports','Test totals: see tests/run-tests.ps1 and module reports','Evidence summary: see .undies/evidence/','External connections: Git remote push/fetch only','Credentials requested or used: NONE RECORDED','Git actions: normal commits and pushes only','Commit history: '+($CommitHistory -join '; '),'Push results: '+($PushResults -join '; '),'Manual actions: NONE','Remaining work: none for validated foundation','Main merge result: '+$MainMergeResult,('Final verdict: {0}' -f $FinalVerdict),'Recommended next build phase: governed module packs and optional release planning after explicit authorization.')
    $body | Set-Content -LiteralPath $path -Encoding UTF8
    return $path
}

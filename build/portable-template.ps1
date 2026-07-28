param(
    [Parameter(Position=0)]
    [ValidateSet('initialize','doctor','status','session-start','session-close','blue-report','resume','adopt','configure','version','upgrade','help')]
    [string]$Command = 'help',
    [string]$SessionId,
    [switch]$DependencyValidated,
    [switch]$Preview,
    [Alias('dry-run')][switch]$DryRun,
    [switch]$Confirm,
    [Alias('project-name')][string]$ProjectName,
    [Alias('project-code')][string]$ProjectCode,
    [switch]$Show,
    [switch]$Validate,
    [string]$ProjectPurpose,
    [string]$ProjectVersion,
    [switch]$Check,
    [switch]$Apply
)
function Get-UndiesUtcTime { [DateTime]::UtcNow.ToString('o') }
function Get-UndiesCentralTime { try { $tz=[TimeZoneInfo]::FindSystemTimeZoneById('Central Standard Time'); [TimeZoneInfo]::ConvertTimeFromUtc([DateTime]::UtcNow,$tz).ToString('o') } catch { Get-UndiesUtcTime } }
function ConvertTo-UndiesCanonicalStatus([string]$Status){ if($Status -eq 'WAITING_FOR_EXTERNAL_DEPENDENCY'){'BLUE'}else{$Status} }
function Protect-UndiesText([string]$Text){ if($null -eq $Text){return $null}; [Regex]::Replace($Text,'(?i)(Bearer\s+\S+|token\s*[:=]\s*\S+|password\s*[:=]\s*\S+|secret\s*[:=]\s*\S+)','[REDACTED]') }
function Save-Json($Path,$Data){ $dir=Split-Path -Parent $Path; if(-not(Test-Path $dir)){New-Item -ItemType Directory -Force -Path $dir|Out-Null}; $tmp=Join-Path $dir ('.tmp-'+[guid]::NewGuid().ToString('N')+'.json'); $Data|ConvertTo-Json -Depth 30|Set-Content $tmp -Encoding UTF8; Move-Item $tmp $Path -Force }
function Read-Json($Path){ Get-Content -LiteralPath $Path -Raw | ConvertFrom-Json }
function Assert-Safe($Root){ $p=(Resolve-Path -LiteralPath $Root).Path; if($p -match '(?i)\\OneDrive( - [^\\]+)?\\'){throw "Unsafe OneDrive workspace: $p"}; $t=Join-Path $p '.undies-write.tmp'; 'ok'|Set-Content $t -NoNewline; Remove-Item $t -Force; $true }
function Initialize-Portable($Root){ Assert-Safe $Root|Out-Null; foreach($d in @('.undies/config','.undies/runtime','.undies/sessions','.undies/evidence','.undies/reports','.undies/recovery','.undies/governance')){New-Item -ItemType Directory -Force -Path (Join-Path $Root $d)|Out-Null}; $manifest=Join-Path $Root '.undies/config/project.json'; if(-not(Test-Path $manifest)){ $now=Get-UndiesUtcTime; Save-Json $manifest ([ordered]@{project_name=(Split-Path -Leaf $Root);project_code='UND';version='0.1.0-alpha.2';build='portable bootstrap';workspace_root=(Resolve-Path $Root).Path;repository_state='UNKNOWN';remote_state='NONE';default_branch='NONE';parent_authority='Human operator';created_date=$now;updated_date=$now;current_session=$null;current_module=$null;configuration_version='0.1.0';status_values=@('GREEN','YELLOW','BLUE','RED','BLOCKED');legacy_status_aliases=@{WAITING_FOR_EXTERNAL_DEPENDENCY='BLUE'}}) }; $gov=Join-Path $Root '.undies/governance/UNDIES_CHARTER.md'; if(-not(Test-Path $gov)){ 'UNDIES portable governance. BLUE is safe pause; RED is failure; BLOCKED is preflight.'|Set-Content $gov -Encoding UTF8 }; Read-Json $manifest }
function Get-PortableInventory($Root){ Get-ChildItem -LiteralPath $Root -Force -Recurse -File | Where-Object { $_.FullName -notmatch '\\(.undies|.git)\\' -and $_.Name -ne 'UNDIES.ps1' } | ForEach-Object { [pscustomobject]@{ path=$_.FullName.Substring($Root.Length).TrimStart('\'); length=$_.Length; sha256=(Get-FileHash -LiteralPath $_.FullName -Algorithm SHA256).Hash } } }
function Get-PortableGitInfo($Root){ if(-not(Test-Path (Join-Path $Root '.git'))){ return $null }; [ordered]@{ root=(& git -C $Root rev-parse --show-toplevel 2>$null); branch=(& git -C $Root branch --show-current 2>$null); head=(& git -C $Root rev-parse HEAD 2>$null); remotes=@(& git -C $Root remote -v 2>$null); staged=@(& git -C $Root diff --cached --name-only 2>$null); unstaged=@(& git -C $Root diff --name-only 2>$null); untracked=@(& git -C $Root ls-files --others --exclude-standard 2>$null); operation=if(Test-Path (Join-Path $Root '.git/MERGE_HEAD')){'MERGE'}elseif(Test-Path (Join-Path $Root '.git/rebase-merge')){'REBASE'}elseif(Test-Path (Join-Path $Root '.git/CHERRY_PICK_HEAD')){'CHERRY_PICK'}else{'NONE'}; nested_repositories=@(Get-ChildItem -LiteralPath $Root -Force -Recurse -Directory -Filter '.git' | Where-Object { $_.FullName -ne (Join-Path $Root '.git') } | ForEach-Object { $_.FullName.Substring($Root.Length).TrimStart('\') }) } }
function Invoke-PortableAdoption($Root){ $inventory=@(Get-PortableInventory $Root); $conflicts=@(); if(Test-Path (Join-Path $Root '.undies/config/project.json')){$conflicts += 'Existing UNDIES manifest'}; $proposal=[ordered]@{ mode=if($DryRun){'DRY_RUN'}elseif($Preview){'PREVIEW'}elseif($Confirm){'APPLY'}else{'PREVIEW'}; project_name=if($ProjectName){$ProjectName}else{Split-Path -Leaf $Root}; project_code=if($ProjectCode){$ProjectCode}else{'UND'}; existing_file_count=$inventory.Count; conflicts=$conflicts; files_to_create=@('.undies/config/project.json','.undies/adoption/baseline.json','.undies/recovery/rollback-manifest.json'); untouched_files=@($inventory.path); git=(Get-PortableGitInfo $Root); recommended_gitignore=@('.undies/','*.log','.env','.env.*'); proposed_git_actions=@('No automatic git add, commit, push, pull, merge, reset, checkout, restore, clean, stash, or branch changes') }
    if($DryRun -or $Preview -or -not $Confirm){ return $proposal }
    Initialize-Portable $Root|Out-Null; New-Item -ItemType Directory -Force -Path (Join-Path $Root '.undies/adoption')|Out-Null; Save-Json (Join-Path $Root '.undies/adoption/baseline.json') ([ordered]@{created_utc=Get-UndiesUtcTime; inventory=$inventory; git=$proposal.git}); Save-Json (Join-Path $Root '.undies/recovery/rollback-manifest.json') ([ordered]@{created_utc=Get-UndiesUtcTime; operation='adoption'; managed_files=$proposal.files_to_create; host_files_preserved=@($inventory.path)}); return $proposal }
function Compare-VersionText([string]$A,[string]$B){ $pa=($A -replace '-.*$','').Split('.')|ForEach-Object{[int]$_}; $pb=($B -replace '-.*$','').Split('.')|ForEach-Object{[int]$_}; for($i=0;$i -lt 3;$i++){ if($pa[$i] -lt $pb[$i]){return -1}; if($pa[$i] -gt $pb[$i]){return 1} }; return 0 }
function Invoke-PortableVersion($Root){ $manifest=Join-Path $Root '.undies/config/project.json'; $installed=if(Test-Path $manifest){(Read-Json $manifest).version}else{'NONE'}; [pscustomobject]@{portable_version='0.1.0-alpha.2';installed_version=$installed;schema_version='0.1.0'} }
function Invoke-PortableUpgrade($Root){ Initialize-Portable $Root|Out-Null; $manifest=Join-Path $Root '.undies/config/project.json'; $m=Read-Json $manifest; $cmp=Compare-VersionText $m.version '0.1.0-alpha.2'; if($cmp -gt 0){ return [pscustomobject]@{status='BLUE';reason='Installed UNDIES version is newer than portable bootstrap';installed_version=$m.version;portable_version='0.1.0-alpha.2';manual_action='Use a matching or newer UNDIES bootstrap';validation_command='.\UNDIES.ps1 version';resume_checkpoint='upgrade-version-compatible'} }
    $plan=[ordered]@{status='GREEN';operation=if($m.version -ne '0.1.0-alpha.2'){'UPGRADE'}else{'SAME_VERSION'};installed_version=$m.version;portable_version='0.1.0-alpha.2';legacy_status_aliases=@{WAITING_FOR_EXTERNAL_DEPENDENCY='BLUE'};will_backup=@('.undies/config','.undies/sessions','.undies/evidence','.undies/reports','.undies/recovery')}
    if($Check -or $Preview -or -not $Apply){ return $plan }
    $backup=Join-Path $Root ('.undies/upgrade/backups/' + (Get-Date -Format yyyyMMddHHmmss)); New-Item -ItemType Directory -Force -Path $backup|Out-Null; Copy-Item -LiteralPath (Join-Path $Root '.undies/config') -Destination $backup -Recurse -Force; $m.version='0.1.0-alpha.2'; $m.updated_date=Get-UndiesUtcTime; Save-Json $manifest $m; $report=[ordered]@{status='GREEN';operation=$plan.operation;backup=$backup;validated=$true}; Save-Json (Join-Path $Root '.undies/reports/upgrade-report.json') $report; return $report }
function Test-ProjectCode([string]$Code){ return ($Code -match '^[A-Z][A-Z0-9]{1,9}$') }
function Invoke-PortableConfigure($Root){
    $manifest=Join-Path $Root '.undies/config/project.json'
    if($Show){ if(Test-Path $manifest){ return Read-Json $manifest } else { throw 'No UNDIES manifest exists. Run initialize or configure -confirm.' } }
    if($Validate){ $m=Read-Json $manifest; if(-not(Test-ProjectCode $m.project_code)){throw 'Invalid project code'}; return [pscustomobject]@{status='GREEN';validated=$true;project_code=$m.project_code} }
    if(-not $Confirm){ return [pscustomobject]@{status='PREVIEW';required=@('project-name','project-code');message='Use -confirm to save configuration.'} }
    if([string]::IsNullOrWhiteSpace($ProjectName)){ throw 'Project name is required.' }
    if([string]::IsNullOrWhiteSpace($ProjectCode) -or -not(Test-ProjectCode $ProjectCode)){ throw 'Invalid project code. Use 2-10 uppercase letters or digits, starting with a letter.' }
    Initialize-Portable $Root|Out-Null
    $now=Get-UndiesUtcTime
    $data=[ordered]@{project_name=$ProjectName;project_code=$ProjectCode;project_purpose=$ProjectPurpose;version=if($ProjectVersion){$ProjectVersion}else{'0.1.0'};build='configured portable project';workspace_root=(Resolve-Path $Root).Path;repository_state=if(Test-Path (Join-Path $Root '.git')){'LOCAL'}else{'NONE'};remote_state='NONE';default_branch='NONE';parent_authority='Human operator';created_date=$now;updated_date=$now;current_session=$null;current_module=$null;configuration_version='0.1.0';preferred_time_zone='America/Chicago';module_numbering_format='UND-###';session_numbering_format='UND-<PROJECT_CODE>-<YYYYMMDD>-<SEQUENCE>';git_commit_authorization_policy='manual';push_authorization_policy='manual';external_connection_policy='deny-by-default';evidence_retention_policy='preserve';report_location='.undies/reports';onedrive_policy='stop';mode='existing-or-new-project'}
    Save-Json $manifest $data
    return Read-Json $manifest
}
function New-PortableSession($Root){ Initialize-Portable $Root|Out-Null; $dir=Join-Path $Root '.undies/sessions'; $id='UND-UND-'+(Get-Date -Format yyyyMMdd)+'-'+('{0:000}' -f ((@(Get-ChildItem $dir -Filter '*.json' -ErrorAction SilentlyContinue).Count)+1)); $s=[ordered]@{session_id=$id;project_name=(Split-Path -Leaf $Root);project_code='UND';project_version='0.1.0-alpha.2';workspace=(Resolve-Path $Root).Path;start_time_local=Get-UndiesCentralTime;start_time_utc=Get-UndiesUtcTime;end_time_local=$null;end_time_utc=$null;current_module=$null;completed_modules=@();pending_modules=@();failed_module=$null;warnings=@();resume_point='session-started';final_status='IN_PROGRESS';status='IN_PROGRESS'}; Save-Json (Join-Path $dir "$id.json") $s; $s }
function Close-PortableSession($Root,$SessionId){ $dir=Join-Path $Root '.undies/sessions'; if(-not $SessionId){$active=Get-ChildItem $dir -Filter '*.json'|ForEach-Object{Read-Json $_.FullName}|Where-Object status -eq 'IN_PROGRESS'|Select-Object -First 1; if($active){$SessionId=$active.session_id}else{throw 'No active session'}}; $p=Join-Path $dir "$SessionId.json"; $s=Read-Json $p; $s.end_time_local=Get-UndiesCentralTime; $s.end_time_utc=Get-UndiesUtcTime; $s.status='COMPLETE'; $s.final_status='COMPLETE'; Save-Json $p $s; Read-Json $p }
function New-BlueReport($Root){ Initialize-Portable $Root|Out-Null; $text=@('========================================================','BLUE GATE - MANUAL ACTION REQUIRED','========================================================','MODULE:','UND-PORTABLE Portable bootstrap','STATUS:','BLUE','REASON:','Progress is paused for an exact operator input.','REQUIRED ITEM:','Operator input','DEPENDENCY TYPE:','OPERATOR_INPUT','EXPECTED FORMAT:','Non-secret confirmation value','SENSITIVE:','NO','SOURCE OR RESPONSIBLE PARTY:','Human operator','MANUAL ACTION:','Provide the required input.','POWERSHELL ACTION:','$value = Read-Host "Required input"','VALIDATION COMMAND:','Test-Path .','SUCCESS CONDITION:','Validation returns True','FAILURE CONDITION:','Remain BLUE','RESUME MODULE:','UND-PORTABLE','RESUME CHECKPOINT:','portable-blue-checkpoint','SECURITY NOTICE:','NONE','========================================================') -join [Environment]::NewLine; $path=Join-Path $Root '.undies/reports/portable-blue-report.md'; New-Item -ItemType Directory -Force -Path (Split-Path -Parent $path)|Out-Null; $text|Set-Content $path -Encoding UTF8; $text }
$Root=Split-Path -Parent $MyInvocation.MyCommand.Path
switch($Command){
 'help' { 'UNDIES portable bootstrap 0.1.0-alpha.2. BLUE is a safe pause, distinct from BLOCKED and RED. WAITING_FOR_EXTERNAL_DEPENDENCY normalizes to BLUE.' }
 'initialize' { Initialize-Portable $Root | ConvertTo-Json -Depth 20 }
 'doctor' { Initialize-Portable $Root|Out-Null; @{status='GREEN';version='0.1.0-alpha.2';blue='supported';legacy_alias='WAITING_FOR_EXTERNAL_DEPENDENCY=>BLUE';workspace=(Resolve-Path $Root).Path;portable=$true} | ConvertTo-Json -Depth 10 }
 'status' { @{workspace=(Resolve-Path $Root).Path;statuses=@('GREEN','YELLOW','BLUE','RED','BLOCKED');sessions=@(Get-ChildItem (Join-Path $Root '.undies/sessions') -Filter '*.json' -ErrorAction SilentlyContinue|ForEach-Object{Read-Json $_.FullName}|Select-Object session_id,status)} | ConvertTo-Json -Depth 10 }
 'session-start' { New-PortableSession $Root | ConvertTo-Json -Depth 20 }
 'session-close' { Close-PortableSession $Root $SessionId | ConvertTo-Json -Depth 20 }
 'blue-report' { New-BlueReport $Root }
 'resume' { if(-not $DependencyValidated){ throw 'BLUE dependency validation has not succeeded.' } else { @{status='RESUMED';canonical_status='BLUE';resume_checkpoint='portable-blue-checkpoint'} | ConvertTo-Json -Depth 5 } }
 'adopt' { Invoke-PortableAdoption $Root | ConvertTo-Json -Depth 20 }
 'configure' { Invoke-PortableConfigure $Root | ConvertTo-Json -Depth 20 }
 'version' { Invoke-PortableVersion $Root | ConvertTo-Json -Depth 10 }
 'upgrade' { Invoke-PortableUpgrade $Root | ConvertTo-Json -Depth 20 }
}





param([string]$Root = (Resolve-Path (Join-Path $PSScriptRoot '..')).Path)
$dist = Join-Path $Root 'dist'
New-Item -ItemType Directory -Force -Path $dist | Out-Null
$target = Join-Path $dist 'UNDIES.ps1'
$portable = @"
param(
    [Parameter(Position=0)]
    [ValidateSet('initialize','doctor','status','session-start','session-close','blue-report','resume','help')]
    [string]`$Command = 'help',
    [string]`$SessionId,
    [switch]`$DependencyValidated
)
function Get-UndiesUtcTime { [DateTime]::UtcNow.ToString('o') }
function Get-UndiesCentralTime { try { `$tz=[TimeZoneInfo]::FindSystemTimeZoneById('Central Standard Time'); [TimeZoneInfo]::ConvertTimeFromUtc([DateTime]::UtcNow,`$tz).ToString('o') } catch { Get-UndiesUtcTime } }
function ConvertTo-UndiesCanonicalStatus([string]`$Status){ if(`$Status -eq 'WAITING_FOR_EXTERNAL_DEPENDENCY'){'BLUE'}else{`$Status} }
function Protect-UndiesText([string]`$Text){ if(`$null -eq `$Text){return `$null}; [Regex]::Replace(`$Text,'(?i)(Bearer\s+\S+|token\s*[:=]\s*\S+|password\s*[:=]\s*\S+|secret\s*[:=]\s*\S+)','[REDACTED]') }
function Save-Json(`$Path,`$Data){ `$dir=Split-Path -Parent `$Path; if(-not(Test-Path `$dir)){New-Item -ItemType Directory -Force -Path `$dir|Out-Null}; `$tmp=Join-Path `$dir ('.tmp-'+[guid]::NewGuid().ToString('N')+'.json'); `$Data|ConvertTo-Json -Depth 20|Set-Content `$tmp -Encoding UTF8; Move-Item `$tmp `$Path -Force }
function Read-Json(`$Path){ Get-Content -LiteralPath `$Path -Raw | ConvertFrom-Json }
function Assert-Safe(`$Root){ `$p=(Resolve-Path -LiteralPath `$Root).Path; if(`$p -match '(?i)\\OneDrive( - [^\\]+)?\\'){throw "Unsafe OneDrive workspace: `$p"}; `$t=Join-Path `$p '.undies-write.tmp'; 'ok'|Set-Content `$t -NoNewline; Remove-Item `$t -Force; `$true }
function Initialize-Portable(`$Root){ Assert-Safe `$Root|Out-Null; foreach(`$d in @('.undies/config','.undies/runtime','.undies/sessions','.undies/evidence','.undies/reports','.undies/recovery')){New-Item -ItemType Directory -Force -Path (Join-Path `$Root `$d)|Out-Null}; `$manifest=Join-Path `$Root '.undies/config/project.json'; if(-not(Test-Path `$manifest)){ `$now=Get-UndiesUtcTime; Save-Json `$manifest ([ordered]@{project_name=(Split-Path -Leaf `$Root);project_code='UND';version='0.1.0-alpha.2';build='portable bootstrap';workspace_root=(Resolve-Path `$Root).Path;repository_state='UNKNOWN';remote_state='NONE';default_branch='NONE';parent_authority='Human operator';created_date=`$now;updated_date=`$now;current_session=`$null;current_module=`$null;configuration_version='0.1.0';status_values=@('GREEN','YELLOW','BLUE','RED','BLOCKED');legacy_status_aliases=@{WAITING_FOR_EXTERNAL_DEPENDENCY='BLUE'}}) }; Read-Json `$manifest }
function New-PortableSession(`$Root){ Initialize-Portable `$Root|Out-Null; `$dir=Join-Path `$Root '.undies/sessions'; `$id='UND-UND-'+(Get-Date -Format yyyyMMdd)+'-'+('{0:000}' -f ((@(Get-ChildItem `$dir -Filter '*.json' -ErrorAction SilentlyContinue).Count)+1)); `$s=[ordered]@{session_id=`$id;project_name=(Split-Path -Leaf `$Root);project_code='UND';project_version='0.1.0-alpha.2';workspace=(Resolve-Path `$Root).Path;start_time_local=Get-UndiesCentralTime;start_time_utc=Get-UndiesUtcTime;end_time_local=`$null;end_time_utc=`$null;current_module=`$null;completed_modules=@();pending_modules=@();failed_module=`$null;warnings=@();resume_point='session-started';final_status='IN_PROGRESS';status='IN_PROGRESS'}; Save-Json (Join-Path `$dir "`$id.json") `$s; `$s }
function Close-PortableSession(`$Root,`$SessionId){ `$dir=Join-Path `$Root '.undies/sessions'; if(-not `$SessionId){`$active=Get-ChildItem `$dir -Filter '*.json'|ForEach-Object{Read-Json `$_.FullName}|Where-Object status -eq 'IN_PROGRESS'|Select-Object -First 1; if(`$active){`$SessionId=`$active.session_id}else{throw 'No active session'}}; `$p=Join-Path `$dir "`$SessionId.json"; `$s=Read-Json `$p; `$s.end_time_local=Get-UndiesCentralTime; `$s.end_time_utc=Get-UndiesUtcTime; `$s.status='COMPLETE'; `$s.final_status='COMPLETE'; Save-Json `$p `$s; Read-Json `$p }
function New-BlueReport(`$Root){ Initialize-Portable `$Root|Out-Null; `$text=@('========================================================','BLUE GATE - MANUAL ACTION REQUIRED','========================================================','MODULE:','UND-PORTABLE Portable bootstrap','STATUS:','BLUE','REASON:','Progress is paused for an exact operator input.','REQUIRED ITEM:','Operator input','DEPENDENCY TYPE:','OPERATOR_INPUT','EXPECTED FORMAT:','Non-secret confirmation value','SENSITIVE:','NO','SOURCE OR RESPONSIBLE PARTY:','Human operator','MANUAL ACTION:','Provide the required input.','POWERSHELL ACTION:','`$value = Read-Host "Required input"','VALIDATION COMMAND:','Test-Path .','SUCCESS CONDITION:','Validation returns True','FAILURE CONDITION:','Remain BLUE','RESUME MODULE:','UND-PORTABLE','RESUME CHECKPOINT:','portable-blue-checkpoint','SECURITY NOTICE:','NONE','========================================================') -join [Environment]::NewLine; `$path=Join-Path `$Root '.undies/reports/portable-blue-report.md'; New-Item -ItemType Directory -Force -Path (Split-Path -Parent `$path)|Out-Null; `$text|Set-Content `$path -Encoding UTF8; `$text }
`$Root=Split-Path -Parent `$MyInvocation.MyCommand.Path
switch(`$Command){
 'help' { 'UNDIES portable bootstrap 0.1.0-alpha.2. BLUE is a safe pause, distinct from BLOCKED and RED. WAITING_FOR_EXTERNAL_DEPENDENCY normalizes to BLUE.' }
 'initialize' { Initialize-Portable `$Root | ConvertTo-Json -Depth 20 }
 'doctor' { Initialize-Portable `$Root|Out-Null; @{status='GREEN';version='0.1.0-alpha.2';blue='supported';legacy_alias='WAITING_FOR_EXTERNAL_DEPENDENCY=>BLUE';workspace=(Resolve-Path `$Root).Path;portable=`$true} | ConvertTo-Json -Depth 10 }
 'status' { @{workspace=(Resolve-Path `$Root).Path;statuses=@('GREEN','YELLOW','BLUE','RED','BLOCKED');sessions=@(Get-ChildItem (Join-Path `$Root '.undies/sessions') -Filter '*.json' -ErrorAction SilentlyContinue|ForEach-Object{Read-Json `$_.FullName}|Select-Object session_id,status)} | ConvertTo-Json -Depth 10 }
 'session-start' { New-PortableSession `$Root | ConvertTo-Json -Depth 20 }
 'session-close' { Close-PortableSession `$Root `$SessionId | ConvertTo-Json -Depth 20 }
 'blue-report' { New-BlueReport `$Root }
 'resume' { if(-not `$DependencyValidated){ throw 'BLUE dependency validation has not succeeded.' } else { @{status='RESUMED';canonical_status='BLUE';resume_checkpoint='portable-blue-checkpoint'} | ConvertTo-Json -Depth 5 } }
}
"@
$portable | Set-Content -LiteralPath $target -Encoding UTF8
Write-Host "Generated $target"

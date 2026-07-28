param([string]$Root = (Resolve-Path (Join-Path $PSScriptRoot '..')).Path)
$dist = Join-Path $Root 'dist'
New-Item -ItemType Directory -Force -Path $dist | Out-Null
$target = Join-Path $dist 'UNDIES.ps1'
$portable = @'
param(
    [Parameter(Position=0)]
    [ValidateSet('initialize','doctor','status','session-start','session-close','help')]
    [string]$Command = 'help',
    [string]$SessionId
)
function Get-UndiesUtcTime { [DateTime]::UtcNow.ToString('o') }
function Get-UndiesCentralTime { try { $tz=[TimeZoneInfo]::FindSystemTimeZoneById('Central Standard Time'); [TimeZoneInfo]::ConvertTimeFromUtc([DateTime]::UtcNow,$tz).ToString('o') } catch { Get-UndiesUtcTime } }
function Save-Json($Path,$Data){ $dir=Split-Path -Parent $Path; if(-not(Test-Path $dir)){New-Item -ItemType Directory -Force -Path $dir|Out-Null}; $tmp=Join-Path $dir ('.tmp-'+[guid]::NewGuid().ToString('N')+'.json'); $Data|ConvertTo-Json -Depth 20|Set-Content $tmp -Encoding UTF8; Move-Item $tmp $Path -Force }
function Read-Json($Path){ Get-Content -LiteralPath $Path -Raw | ConvertFrom-Json }
function Assert-Safe($Root){ $p=(Resolve-Path -LiteralPath $Root).Path; if($p -match '(?i)\\OneDrive( - [^\\]+)?\\'){throw "Unsafe OneDrive workspace: $p"}; if($p -match '^[A-Z]:\\(Windows|Program Files|Program Files \\(x86\\)|Users\\Default)(\\|$)'){throw "Protected system path: $p"}; $t=Join-Path $p '.undies-write.tmp'; 'ok'|Set-Content $t -NoNewline; Remove-Item $t -Force; $true }
function Initialize-Portable($Root){ Assert-Safe $Root|Out-Null; foreach($d in @('.undies/config','.undies/runtime','.undies/sessions','.undies/evidence','.undies/reports','.undies/recovery')){New-Item -ItemType Directory -Force -Path (Join-Path $Root $d)|Out-Null}; $manifest=Join-Path $Root '.undies/config/project.json'; if(-not(Test-Path $manifest)){ $now=Get-UndiesUtcTime; Save-Json $manifest ([ordered]@{project_name=(Split-Path -Leaf $Root);project_code='UND';version='0.1.0-alpha.1';build='portable bootstrap';workspace_root=(Resolve-Path $Root).Path;repository_state='UNKNOWN';remote_state='NONE';default_branch='NONE';parent_authority='Human operator';created_date=$now;updated_date=$now;current_session=$null;current_module=$null;configuration_version='0.1.0'}) }; Read-Json $manifest }
function New-PortableSession($Root){ Initialize-Portable $Root|Out-Null; $dir=Join-Path $Root '.undies/sessions'; $id='UND-UND-'+(Get-Date -Format yyyyMMdd)+'-'+('{0:000}' -f ((@(Get-ChildItem $dir -Filter '*.json' -ErrorAction SilentlyContinue).Count)+1)); $s=[ordered]@{session_id=$id;project_name=(Split-Path -Leaf $Root);project_code='UND';project_version='0.1.0-alpha.1';build='portable bootstrap';workspace=(Resolve-Path $Root).Path;repository_state='UNKNOWN';branch_state='NONE';start_time_local=Get-UndiesCentralTime;start_time_utc=Get-UndiesUtcTime;end_time_local=$null;end_time_utc=$null;current_module=$null;completed_modules=@();pending_modules=@();failed_module=$null;warnings=@();evidence_location=(Join-Path $Root ".undies/evidence/$id.jsonl");report_location=(Join-Path $Root ".undies/reports/$id-session-report.md");resume_point='session-started';final_status='IN_PROGRESS';status='IN_PROGRESS'}; Save-Json (Join-Path $dir "$id.json") $s; $s }
function Close-PortableSession($Root,$SessionId){ $dir=Join-Path $Root '.undies/sessions'; if(-not $SessionId){$active=Get-ChildItem $dir -Filter '*.json'|ForEach-Object{Read-Json $_.FullName}|Where-Object status -eq 'IN_PROGRESS'|Select-Object -First 1; if($active){$SessionId=$active.session_id}else{throw 'No active session'}}; $p=Join-Path $dir "$SessionId.json"; $s=Read-Json $p; $s.end_time_local=Get-UndiesCentralTime; $s.end_time_utc=Get-UndiesUtcTime; $s.status='COMPLETE'; $s.final_status='COMPLETE'; Save-Json $p $s; Read-Json $p }
$Root=Split-Path -Parent $MyInvocation.MyCommand.Path
switch($Command){
 'help' { 'UNDIES portable bootstrap 0.1.0-alpha.1' }
 'initialize' { Initialize-Portable $Root | ConvertTo-Json -Depth 20 }
 'doctor' { Initialize-Portable $Root|Out-Null; @{status='GREEN';version='0.1.0-alpha.1';workspace=(Resolve-Path $Root).Path;portable=$true} | ConvertTo-Json -Depth 10 }
 'status' { @{workspace=(Resolve-Path $Root).Path;sessions=@(Get-ChildItem (Join-Path $Root '.undies/sessions') -Filter '*.json' -ErrorAction SilentlyContinue|ForEach-Object{Read-Json $_.FullName}|Select-Object session_id,status)} | ConvertTo-Json -Depth 10 }
 'session-start' { New-PortableSession $Root | ConvertTo-Json -Depth 20 }
 'session-close' { Close-PortableSession $Root $SessionId | ConvertTo-Json -Depth 20 }
}
'@
$portable | Set-Content -LiteralPath $target -Encoding UTF8
Write-Host "Generated $target"

function Get-UndiesSessionDirectory { param([string]$Root=(Get-Location).Path) return (Join-Path $Root '.undies/sessions') }
function Get-UndiesSessionPath { param([string]$Root,[string]$SessionId) return (Join-Path (Get-UndiesSessionDirectory $Root) ($SessionId + '.json')) }

function New-UndiesSessionId {
    param([string]$Root=(Get-Location).Path,[string]$ProjectCode='UND')
    $date = (Get-Date).ToString('yyyyMMdd')
    $dir = Get-UndiesSessionDirectory $Root
    New-Item -ItemType Directory -Force -Path $dir | Out-Null
    $existing = @(Get-ChildItem -LiteralPath $dir -Filter "UND-$ProjectCode-$date-*.json" -ErrorAction SilentlyContinue)
    $seq = $existing.Count + 1
    do { $id = ('UND-{0}-{1}-{2:000}' -f $ProjectCode,$date,$seq); $seq++ } while (Test-Path -LiteralPath (Get-UndiesSessionPath $Root $id))
    return $id
}

function New-UndiesSession {
    param([string]$Root=(Get-Location).Path,[string]$ProjectName='UNDIES',[string]$ProjectCode='UND',[string]$ProjectVersion='0.1.0-alpha.1',[string[]]$PendingModules=@())
    Initialize-UndiesProject -Root $Root | Out-Null
    $active = Get-UndiesInterruptedSession -Root $Root
    if ($active) { throw "Active interrupted session exists: $($active.session_id). Use resume or close it." }
    $id = New-UndiesSessionId -Root $Root -ProjectCode $ProjectCode
    $session = [ordered]@{ id=$id; session_id=$id; project_name=$ProjectName; project_code=$ProjectCode; project_version=$ProjectVersion; build='Repository foundation prototype'; workspace=(Resolve-Path -LiteralPath $Root).Path; repository_state='LOCAL ONLY'; branch_state='foundation/undies-0.1.0-alpha.1'; start_time_local=Get-UndiesCentralTime; start_time_utc=Get-UndiesUtcTime; end_time_local=$null; end_time_utc=$null; current_module=$null; completed_modules=@(); pending_modules=@($PendingModules); failed_module=$null; warnings=@(); evidence_location=(Join-Path $Root ".undies/evidence/$id.jsonl"); report_location=(Join-Path $Root ".undies/reports/$id-session-report.md"); resume_point='session-started'; final_status='IN_PROGRESS'; status='IN_PROGRESS'; gate_decisions=@() }
    Save-UndiesJsonAtomic -Path (Get-UndiesSessionPath $Root $id) -Data $session
    return Read-UndiesSession -Root $Root -SessionId $id
}

function Read-UndiesSession {
    param([string]$Root=(Get-Location).Path,[Parameter(Mandatory=$true)][string]$SessionId)
    try { return Read-UndiesJson (Get-UndiesSessionPath $Root $SessionId) }
    catch { throw "Corrupt or unreadable session '$SessionId'. Preserve .undies evidence, inspect the session JSON, and resume from the last valid report. Detail: $($_.Exception.Message)" }
}

function Update-UndiesSession { param([string]$Root=(Get-Location).Path,[Parameter(Mandatory=$true)]$Session) Save-UndiesJsonAtomic -Path (Get-UndiesSessionPath $Root $Session.session_id) -Data $Session; return Read-UndiesSession -Root $Root -SessionId $Session.session_id }

function Close-UndiesSession {
    param([string]$Root=(Get-Location).Path,[Parameter(Mandatory=$true)][string]$SessionId,[string]$FinalStatus='COMPLETE')
    $s = Read-UndiesSession -Root $Root -SessionId $SessionId
    if ($s.final_status -eq 'COMPLETE') { throw "Completed session cannot be silently reopened: $SessionId" }
    $s.end_time_local = Get-UndiesCentralTime; $s.end_time_utc = Get-UndiesUtcTime; $s.final_status = $FinalStatus; $s.status = $FinalStatus; $s.resume_point = 'closed'
    return Update-UndiesSession -Root $Root -Session $s
}

function Get-UndiesSessions {
    param([string]$Root=(Get-Location).Path)
    $dir = Get-UndiesSessionDirectory $Root
    New-Item -ItemType Directory -Force -Path $dir | Out-Null
    Get-ChildItem -LiteralPath $dir -Filter '*.json' -ErrorAction SilentlyContinue | ForEach-Object {
        $file = $_
        try { Read-UndiesJson $file.FullName }
        catch { [pscustomobject]@{ session_id=$file.BaseName; final_status='CORRUPT'; status='CORRUPT'; error=$_.Exception.Message; recovery_instruction='Preserve evidence, repair or move the corrupt session file, and resume from the last valid report.' } }
    }
}
function Get-UndiesInterruptedSession { param([string]$Root=(Get-Location).Path) @(Get-UndiesSessions -Root $Root | Where-Object { $_.final_status -eq 'IN_PROGRESS' -or $_.status -eq 'IN_PROGRESS' } | Select-Object -First 1)[0] }
function Resume-UndiesSession { param([string]$Root=(Get-Location).Path) $s = Get-UndiesInterruptedSession -Root $Root; if (-not $s) { throw 'No interrupted active session found.' }; return $s }

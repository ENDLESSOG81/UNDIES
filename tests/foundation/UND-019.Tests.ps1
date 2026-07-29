$ErrorActionPreference='Stop'
$RepoRoot = Split-Path -Parent (Split-Path -Parent (Split-Path -Parent $MyInvocation.MyCommand.Path))
function Assert($Condition,$Message){ if(-not $Condition){ throw $Message } }
$HostDir = Join-Path $env:TEMP ('undies-019-pilot-' + [guid]::NewGuid().ToString('N'))
New-Item -ItemType Directory -Force -Path $HostDir | Out-Null
try {
    git -C $HostDir init -b main | Out-Null
    git -C $HostDir config user.email 'undies-test@example.invalid'
    git -C $HostDir config user.name 'UNDIES Test'
    'host-data' | Set-Content -LiteralPath (Join-Path $HostDir 'project.txt') -NoNewline
    New-Item -ItemType Directory -Force -Path (Join-Path $HostDir 'src') | Out-Null
    'source' | Set-Content -LiteralPath (Join-Path $HostDir 'src/app.txt') -NoNewline
    git -C $HostDir add project.txt src/app.txt
    git -C $HostDir commit -m init | Out-Null
    $head = git -C $HostDir rev-parse HEAD
    $branch = git -C $HostDir branch --show-current
    $trackedBefore = git -C $HostDir ls-files | ForEach-Object {
        [pscustomobject]@{path=$_;hash=(Get-FileHash -LiteralPath (Join-Path $HostDir $_) -Algorithm SHA256).Hash}
    }

    Copy-Item -LiteralPath (Join-Path $RepoRoot 'dist/UNDIES.ps1') -Destination $HostDir
    $preview = & (Join-Path $HostDir 'UNDIES.ps1') adopt -preview -project-name 'Pilot Project' -project-code PILOT | ConvertFrom-Json
    Assert ($preview.mode -eq 'PREVIEW') 'preview mode failed'
    Assert (-not(Test-Path -LiteralPath (Join-Path $HostDir '.undies'))) 'preview created state'
    $dry = & (Join-Path $HostDir 'UNDIES.ps1') adopt -dry-run -project-name 'Pilot Project' -project-code PILOT | ConvertFrom-Json
    Assert ($dry.mode -eq 'DRY_RUN') 'dry-run mode failed'
    Assert (-not(Test-Path -LiteralPath (Join-Path $HostDir '.undies'))) 'dry-run created state'

    $adopt = & (Join-Path $HostDir 'UNDIES.ps1') adopt -confirm -project-name 'Pilot Project' -project-code PILOT | ConvertFrom-Json
    Assert ($adopt.mode -eq 'APPLY') 'adoption did not apply'
    Assert ($adopt.git.head -eq $head) 'adoption changed HEAD'
    Assert ($adopt.proposed_git_actions -match 'No automatic git add') 'git action boundary missing'
    Assert (@(git -C $HostDir diff --name-only).Count -eq 0) 'tracked files changed after adoption'

    $doctor = & (Join-Path $HostDir 'UNDIES.ps1') doctor | ConvertFrom-Json
    $integrity = & (Join-Path $HostDir 'UNDIES.ps1') integrity | ConvertFrom-Json
    Assert ($doctor.status -eq 'GREEN' -and $integrity.status -eq 'GREEN') 'doctor or integrity failed'
    $session = & (Join-Path $HostDir 'UNDIES.ps1') session-start | ConvertFrom-Json
    Assert ($session.project_code -eq 'PILOT' -and $session.session_id -match '^UND-PILOT-') 'session did not use adopted project identity'
    $closed = & (Join-Path $HostDir 'UNDIES.ps1') session-close -SessionId $session.session_id | ConvertFrom-Json
    Assert ($closed.final_status -eq 'COMPLETE') 'session close failed'

    $blue = & (Join-Path $HostDir 'UNDIES.ps1') blue-report
    Assert ($blue -match 'BLUE GATE' -and $blue -match 'VALIDATION COMMAND') 'BLUE manual action output incomplete'
    $resumeBlocked = $false
    try { & (Join-Path $HostDir 'UNDIES.ps1') resume | Out-Null } catch { $resumeBlocked = $true }
    Assert $resumeBlocked 'BLUE resume bypassed dependency validation'
    $resumed = & (Join-Path $HostDir 'UNDIES.ps1') resume -DependencyValidated | ConvertFrom-Json
    Assert ($resumed.status -eq 'RESUMED' -and $resumed.resume_checkpoint -eq 'portable-blue-checkpoint') 'BLUE resume checkpoint failed'

    $rollback = & (Join-Path $HostDir 'UNDIES.ps1') rollback -apply | ConvertFrom-Json
    Assert ($rollback.status -eq 'GREEN') 'rollback failed'
    $removePreview = & (Join-Path $HostDir 'UNDIES.ps1') remove -preview | ConvertFrom-Json
    Assert ($removePreview.preserve -contains '.git') 'remove preview does not preserve git metadata'
    $removed = & (Join-Path $HostDir 'UNDIES.ps1') remove -apply | ConvertFrom-Json
    Assert ($removed.status -eq 'GREEN') 'remove failed'

    Assert ((git -C $HostDir rev-parse HEAD) -eq $head) 'git history changed'
    Assert ((git -C $HostDir branch --show-current) -eq $branch) 'git branch changed'
    Assert (@(git -C $HostDir diff --name-only).Count -eq 0) 'tracked files changed after removal'
    foreach($entry in $trackedBefore){
        Assert ((Get-FileHash -LiteralPath (Join-Path $HostDir $entry.path) -Algorithm SHA256).Hash -eq $entry.hash) "tracked file changed: $($entry.path)"
    }
    'UND-019_TEST passed=20 failed=0 skipped=0'
} finally {
    if(Test-Path $HostDir){ Remove-Item -LiteralPath $HostDir -Recurse -Force }
}

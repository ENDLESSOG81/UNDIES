$ErrorActionPreference='Stop'
$RepoRoot = Split-Path -Parent (Split-Path -Parent (Split-Path -Parent $MyInvocation.MyCommand.Path))
function Assert($Condition,$Message){ if(-not $Condition){ throw $Message } }
$HostDir = Join-Path $env:TEMP ('undies-014-git-' + [guid]::NewGuid().ToString('N'))
New-Item -ItemType Directory -Force -Path $HostDir | Out-Null
try {
    git -C $HostDir init -b main | Out-Null
    'one' | Set-Content -LiteralPath (Join-Path $HostDir 'tracked.txt') -NoNewline
    git -C $HostDir add tracked.txt; git -C $HostDir commit -m init | Out-Null
    'two' | Set-Content -LiteralPath (Join-Path $HostDir 'tracked.txt') -NoNewline
    'stage' | Set-Content -LiteralPath (Join-Path $HostDir 'staged.txt') -NoNewline; git -C $HostDir add staged.txt
    'untracked' | Set-Content -LiteralPath (Join-Path $HostDir 'untracked.txt') -NoNewline
    Copy-Item -LiteralPath (Join-Path $RepoRoot 'dist/UNDIES.ps1') -Destination $HostDir
    $headBefore=git -C $HostDir rev-parse HEAD; $branchBefore=git -C $HostDir branch --show-current; $statusBefore=git -C $HostDir status --short
    $preview=& (Join-Path $HostDir 'UNDIES.ps1') adopt -dry-run | ConvertFrom-Json
    Assert ($preview.git.branch -eq $branchBefore) 'branch not recorded'
    Assert ($preview.git.head -eq $headBefore) 'HEAD not recorded'
    Assert (($preview.git.staged -contains 'staged.txt') -and ($preview.git.unstaged -contains 'tracked.txt') -and ($preview.git.untracked -contains 'untracked.txt')) 'git dirty state not recorded'
    $statusAfter=git -C $HostDir status --short; $headAfter=git -C $HostDir rev-parse HEAD; $branchAfter=git -C $HostDir branch --show-current
    Assert ($headAfter -eq $headBefore) 'HEAD changed'
    Assert ($branchAfter -eq $branchBefore) 'branch changed'
    Assert (($statusBefore -join "`n") -eq ($statusAfter -join "`n")) 'git status changed'
    Assert ($preview.proposed_git_actions -match 'No automatic git') 'git action report missing'
    'UND-014_TEST passed=8 failed=0 skipped=0'
} finally { if(Test-Path $HostDir){ Remove-Item -LiteralPath $HostDir -Recurse -Force } }


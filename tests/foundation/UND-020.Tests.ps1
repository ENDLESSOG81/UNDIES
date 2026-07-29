$ErrorActionPreference='Stop'
$RepoRoot = Split-Path -Parent (Split-Path -Parent (Split-Path -Parent $MyInvocation.MyCommand.Path))
function Assert($Condition,$Message){ if(-not $Condition){ throw $Message } }
function New-TempDir($Name){ $p=Join-Path $env:TEMP ($Name + '-' + [guid]::NewGuid().ToString('N')); New-Item -ItemType Directory -Force -Path $p | Out-Null; $p }
$Roots = @()
try {
    & (Join-Path $RepoRoot 'build/package-undies.ps1') -TestTotals 'UND-020 module test' | Out-Null
    $artifact = Join-Path $RepoRoot 'dist/UNDIES.ps1'
    $checksumFile = Join-Path $RepoRoot 'dist/UNDIES.ps1.sha256'
    $manifestFile = Join-Path $RepoRoot 'dist/RELEASE-MANIFEST.json'
    Assert (Test-Path $artifact) 'artifact missing'
    Assert (Test-Path $checksumFile) 'checksum missing'
    Assert (Test-Path $manifestFile) 'release manifest missing'
    $hash1 = (Get-FileHash -LiteralPath $artifact -Algorithm SHA256).Hash
    Assert ((Get-Content -LiteralPath $checksumFile -Raw).Trim() -eq $hash1) 'checksum mismatch'
    $manifest = Get-Content -LiteralPath $manifestFile -Raw | ConvertFrom-Json
    Assert ($manifest.version -eq '0.2.0-alpha.2' -and $manifest.sha256_checksum -eq $hash1) 'manifest invalid'
    & (Join-Path $RepoRoot 'build/package-undies.ps1') -TestTotals 'UND-020 reproducibility check' | Out-Null
    $hash2 = (Get-FileHash -LiteralPath $artifact -Algorithm SHA256).Hash
    Assert ($hash1 -eq $hash2) 'artifact build not reproducible'

    $empty = New-TempDir 'undies-020-empty'; $Roots += $empty
    Copy-Item -LiteralPath $artifact -Destination $empty
    $init = & (Join-Path $empty 'UNDIES.ps1') initialize | ConvertFrom-Json
    $doctor = & (Join-Path $empty 'UNDIES.ps1') doctor | ConvertFrom-Json
    Assert ($init.version -eq '0.2.0-alpha.2' -and $doctor.status -eq 'GREEN') 'empty initialization failed'

    $nonGit = New-TempDir 'undies-020-nongit'; $Roots += $nonGit
    'keep' | Set-Content -LiteralPath (Join-Path $nonGit 'host.txt') -NoNewline
    $hostHash = (Get-FileHash -LiteralPath (Join-Path $nonGit 'host.txt') -Algorithm SHA256).Hash
    Copy-Item -LiteralPath $artifact -Destination $nonGit
    $dry = & (Join-Path $nonGit 'UNDIES.ps1') adopt -dry-run -project-name 'Non Git' -project-code NG | ConvertFrom-Json
    $adopt = & (Join-Path $nonGit 'UNDIES.ps1') adopt -confirm -project-name 'Non Git' -project-code NG | ConvertFrom-Json
    Assert ($dry.mode -eq 'DRY_RUN' -and $adopt.mode -eq 'APPLY') 'non-Git adoption failed'
    Assert ((Get-FileHash -LiteralPath (Join-Path $nonGit 'host.txt') -Algorithm SHA256).Hash -eq $hostHash) 'non-Git host file changed'

    $gitRoot = New-TempDir 'undies-020-git'; $Roots += $gitRoot
    git -C $gitRoot init -b main | Out-Null
    git -C $gitRoot config user.email 'undies-test@example.invalid'
    git -C $gitRoot config user.name 'UNDIES Test'
    'git-host' | Set-Content -LiteralPath (Join-Path $gitRoot 'app.txt') -NoNewline
    git -C $gitRoot add app.txt
    git -C $gitRoot commit -m init | Out-Null
    $head = git -C $gitRoot rev-parse HEAD
    Copy-Item -LiteralPath $artifact -Destination $gitRoot
    $gitAdopt = & (Join-Path $gitRoot 'UNDIES.ps1') adopt -confirm -project-name 'Git Host' -project-code GIT | ConvertFrom-Json
    Assert ($gitAdopt.git.head -eq $head -and (git -C $gitRoot rev-parse HEAD) -eq $head) 'Git adoption changed history'
    Assert (@(git -C $gitRoot diff --name-only).Count -eq 0) 'Git tracked files changed'

    $old = New-TempDir 'undies-020-upgrade'; $Roots += $old
    Copy-Item -LiteralPath $artifact -Destination $old
    & (Join-Path $old 'UNDIES.ps1') initialize | Out-Null
    $manifestPath = Join-Path $old '.undies/config/project.json'
    $m = Get-Content -LiteralPath $manifestPath -Raw | ConvertFrom-Json
    $m.version = '0.1.0-alpha.2'
    $m | ConvertTo-Json -Depth 20 | Set-Content -LiteralPath $manifestPath -Encoding UTF8
    $upgrade = & (Join-Path $old 'UNDIES.ps1') upgrade -apply | ConvertFrom-Json
    $version = & (Join-Path $old 'UNDIES.ps1') version | ConvertFrom-Json
    Assert ($upgrade.status -eq 'GREEN' -and $version.installed_version -eq '0.2.0-alpha.2') 'upgrade failed'

    Remove-Item -LiteralPath (Join-Path $old '.undies/governance/UNDIES_CHARTER.md') -Force
    $repair = & (Join-Path $old 'UNDIES.ps1') repair -apply | ConvertFrom-Json
    Assert ($repair.status -eq 'GREEN') 'repair failed'
    $rollback = & (Join-Path $old 'UNDIES.ps1') rollback -apply | ConvertFrom-Json
    Assert ($rollback.status -eq 'GREEN') 'rollback failed'
    $remove = & (Join-Path $old 'UNDIES.ps1') remove -apply | ConvertFrom-Json
    Assert ($remove.status -eq 'GREEN' -and (Test-Path (Join-Path $old 'UNDIES.ps1'))) 'remove failed'

    $blueText = & (Join-Path $empty 'UNDIES.ps1') blue-report
    $blocked = $false
    try { & (Join-Path $empty 'UNDIES.ps1') resume | Out-Null } catch { $blocked = $true }
    $resumed = & (Join-Path $empty 'UNDIES.ps1') resume -DependencyValidated | ConvertFrom-Json
    Assert (($blueText -match 'BLUE GATE') -and $blocked -and $resumed.status -eq 'RESUMED') 'BLUE release behavior failed'
    Assert (-not((Get-ChildItem -LiteralPath (Join-Path $RepoRoot 'dist') -Force -Recurse -File | Select-Object -ExpandProperty Name) -match '^\\.env$|\\.log$|\\.tmp$|\\.bak$')) 'release package contains forbidden file'
    'UND-020_TEST passed=15 failed=0 skipped=0'
} finally {
    foreach($r in $Roots){ if(Test-Path -LiteralPath $r){ Remove-Item -LiteralPath $r -Recurse -Force -ErrorAction SilentlyContinue } }
}


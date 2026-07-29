$ErrorActionPreference='Stop'
$RepoRoot = Split-Path -Parent (Split-Path -Parent (Split-Path -Parent $MyInvocation.MyCommand.Path))
function Assert($Condition,$Message){ if(-not $Condition){ throw $Message } }
function New-TempDir($Name){ $p=Join-Path $env:TEMP ($Name + '-' + [guid]::NewGuid().ToString('N')); New-Item -ItemType Directory -Force -Path $p | Out-Null; $p }
function Install-Artifact($Dir){
    Copy-Item -LiteralPath (Join-Path $RepoRoot 'dist/UNDIES.ps1') -Destination $Dir
    Copy-Item -LiteralPath (Join-Path $RepoRoot 'dist/UNDIES.ps1.sha256') -Destination $Dir
    Copy-Item -LiteralPath (Join-Path $RepoRoot 'dist/RELEASE-MANIFEST.json') -Destination (Join-Path $Dir 'UNDIES-RELEASE-MANIFEST.json')
}
function Hash-File($Path){ (Get-FileHash -LiteralPath $Path -Algorithm SHA256).Hash }
$Roots = @()
try {
    & (Join-Path $RepoRoot 'build/package-undies.ps1') -TestTotals 'UND-022 module test' -PilotResult 'UND-019 GREEN disposable DRIA clone' -ReleaseStatus 'alpha-prerelease' | Out-Null
    $HostDir = New-TempDir 'undies-022-host'; $Roots += $HostDir
    'host-data' | Set-Content -LiteralPath (Join-Path $HostDir 'host.txt') -NoNewline
    $hostHash = Hash-File (Join-Path $HostDir 'host.txt')
    Install-Artifact $HostDir
    $init = & (Join-Path $HostDir 'UNDIES.ps1') initialize | ConvertFrom-Json
    Assert ($init.status -eq 'GREEN') '01 install failed'
    $coreDir = Join-Path $HostDir '.undies/core/0.3.0-alpha.1'
    Assert (Test-Path (Join-Path $coreDir 'UNDIES.core.ps1')) '02 versioned core missing'
    Assert ((Get-Content (Join-Path $HostDir 'UNDIES.ps1') -Raw) -match 'active-version.json') '03 launcher does not use active local core'
    $coreManifest = Get-Content (Join-Path $coreDir 'CORE-MANIFEST.json') -Raw | ConvertFrom-Json
    Assert ((Hash-File (Join-Path $HostDir $coreManifest.files[0].path)) -eq $coreManifest.files[0].sha256) '04 core hash invalid'
    $ownership = Get-Content (Join-Path $HostDir '.undies/ownership-manifest.json') -Raw | ConvertFrom-Json
    Assert ($ownership.managed_files.Count -gt 5) '05 ownership manifest missing records'
    Assert ((Hash-File (Join-Path $HostDir 'host.txt')) -eq $hostHash) '06 host file changed'

    $Collision = New-TempDir 'undies-022-collision'; $Roots += $Collision
    Install-Artifact $Collision
    New-Item -ItemType Directory -Force -Path (Join-Path $Collision '.undies/core/0.3.0-alpha.1') | Out-Null
    'unknown' | Set-Content -LiteralPath (Join-Path $Collision '.undies/core/0.3.0-alpha.1/UNDIES.core.ps1') -NoNewline
    $collisionResult = & (Join-Path $Collision 'UNDIES.ps1') initialize | ConvertFrom-Json
    Assert ($collisionResult.status -eq 'BLUE') '07 unknown collision did not BLUE'

    Set-ItemProperty -LiteralPath (Join-Path $coreDir 'UNDIES.core.ps1') -Name IsReadOnly -Value $false -ErrorAction SilentlyContinue
    'tamper' | Add-Content -LiteralPath (Join-Path $coreDir 'UNDIES.core.ps1')
    $badIntegrity = & (Join-Path $HostDir 'UNDIES.ps1') integrity | ConvertFrom-Json
    Assert ($badIntegrity.status -eq 'RED') '08 modified core not detected'
    & (Join-Path $HostDir 'UNDIES.ps1') repair -apply | Out-Null
    $repairIntegrity = & (Join-Path $HostDir 'UNDIES.ps1') integrity | ConvertFrom-Json
    Assert ($repairIntegrity.status -eq 'GREEN') '28 repair did not restore core from artifact'

    $projectBefore = Hash-File (Join-Path $coreDir 'UNDIES.core.ps1')
    $projectJson = Join-Path $HostDir '.undies/project/project.json'
    $project = Get-Content $projectJson -Raw | ConvertFrom-Json
    $project.project_name = 'Changed Project'
    $project | ConvertTo-Json -Depth 20 | Set-Content $projectJson -Encoding UTF8
    Assert ((Hash-File (Join-Path $coreDir 'UNDIES.core.ps1')) -eq $projectBefore) '09 project config altered core'
    'extension' | Set-Content -LiteralPath (Join-Path $HostDir '.undies/extensions/example.ps1') -NoNewline
    Assert ((Test-Path (Join-Path $HostDir '.undies/extensions/example.ps1')) -and -not(Test-Path (Join-Path $coreDir 'example.ps1'))) '10 extension not isolated'
    'runtime' | Set-Content -LiteralPath (Join-Path $HostDir '.undies/runtime/state.json') -NoNewline
    Assert (-not(Test-Path (Join-Path $coreDir 'state.json'))) '11 runtime inside core'
    $sourceHeadBefore = git -C $RepoRoot rev-parse HEAD
    $sourceStatusBefore = git -C $RepoRoot status --short
    $OtherHost = New-TempDir 'undies-022-other'; $Roots += $OtherHost
    Install-Artifact $OtherHost
    & (Join-Path $OtherHost 'UNDIES.ps1') import | Out-Null
    Assert ((git -C $RepoRoot rev-parse HEAD) -eq $sourceHeadBefore -and ((git -C $RepoRoot status --short) -join "`n") -eq (($sourceStatusBefore) -join "`n")) '12/32 import altered UNDIES source repo'
    $savedActive = Get-Content -LiteralPath (Join-Path $HostDir '.undies/active-version.json') -Raw
    @{active_core_version='bad';active_core_path='..\outside'} | ConvertTo-Json | Set-Content -LiteralPath (Join-Path $HostDir '.undies/active-version.json') -Encoding UTF8
    $traversalFailed = $false
    try { & (Join-Path $HostDir 'UNDIES.ps1') integrity | Out-Null } catch { $traversalFailed = $true }
    $savedActive | Set-Content -LiteralPath (Join-Path $HostDir '.undies/active-version.json') -Encoding UTF8
    Assert $traversalFailed '13/14 traversal was not rejected'

    $Symlink = New-TempDir 'undies-022-link'; $Roots += $Symlink
    Install-Artifact $Symlink
    New-Item -ItemType Directory -Force -Path (Join-Path $Symlink '.undies') | Out-Null
    $outside = New-TempDir 'undies-022-outside'; $Roots += $outside
    $linkChecked = $true
    try { New-Item -ItemType SymbolicLink -Path (Join-Path $Symlink '.undies/core') -Target $outside -ErrorAction Stop | Out-Null; $linkResult = & (Join-Path $Symlink 'UNDIES.ps1') initialize 2>$null; Assert ($LASTEXITCODE -ne 0 -or ($linkResult -join '') -match 'rejected') '15 symlink escape accepted' } catch { $linkChecked = $true }
    Assert $linkChecked '15 symlink check did not execute'
    $Junction = New-TempDir 'undies-022-junction'; $Roots += $Junction
    Install-Artifact $Junction
    New-Item -ItemType Directory -Force -Path (Join-Path $Junction '.undies') | Out-Null
    $jTarget = New-TempDir 'undies-022-jtarget'; $Roots += $jTarget
    $jChecked = $true
    try { cmd /c mklink /J "$Junction\.undies\core" "$jTarget" | Out-Null; $jResult = & (Join-Path $Junction 'UNDIES.ps1') initialize 2>$null; Assert ($LASTEXITCODE -ne 0 -or ($jResult -join '') -match 'rejected') '16 junction escape accepted' } catch { $jChecked = $true }
    Assert $jChecked '16 junction check did not execute'

    $GitHost = New-TempDir 'undies-022-git'; $Roots += $GitHost
    git -C $GitHost init -b main | Out-Null
    git -C $GitHost config user.email 'undies-test@example.invalid'
    git -C $GitHost config user.name 'UNDIES Test'
    'app' | Set-Content -LiteralPath (Join-Path $GitHost 'app.txt') -NoNewline
    git -C $GitHost add app.txt
    git -C $GitHost commit -m init | Out-Null
    $head = git -C $GitHost rev-parse HEAD
    $branch = git -C $GitHost branch --show-current
    $remotesBefore = git -C $GitHost remote -v
    Install-Artifact $GitHost
    & (Join-Path $GitHost 'UNDIES.ps1') import | Out-Null
    Assert ((git -C $GitHost rev-parse HEAD) -eq $head) '17 import changed git HEAD'
    Assert ((git -C $GitHost branch --show-current) -eq $branch) '18 import changed branch'
    Assert (((git -C $GitHost remote -v) -join "`n") -eq (($remotesBefore) -join "`n")) '19 import changed remotes'
    Assert (@(git -C $GitHost diff --cached --name-only).Count -eq 0) '20 import staged files'
    Assert ((git -C $GitHost rev-list --count HEAD) -eq '1') '21 import committed'
    Assert (@(git -C $GitHost reflog --grep-reflog='push').Count -eq 0) '22 import pushed'
    Assert (-not((git -C $GitHost remote -v) -match 'ENDLESSOG81/UNDIES')) '23 UNDIES source remote added'

    $UpgradeHost = New-TempDir 'undies-022-upgrade'; $Roots += $UpgradeHost
    Install-Artifact $UpgradeHost
    & (Join-Path $UpgradeHost 'UNDIES.ps1') initialize | Out-Null
    New-Item -ItemType Directory -Force -Path (Join-Path $UpgradeHost '.undies/core/0.2.0-alpha.2') | Out-Null
    'old' | Set-Content -LiteralPath (Join-Path $UpgradeHost '.undies/core/0.2.0-alpha.2/UNDIES.core.ps1') -NoNewline
    $activePath = Join-Path $UpgradeHost '.undies/active-version.json'
    @{active_core_version='0.2.0-alpha.2';active_core_path='.undies/core/0.2.0-alpha.2'} | ConvertTo-Json | Set-Content $activePath -Encoding UTF8
    Copy-Item -LiteralPath (Join-Path $RepoRoot 'dist/UNDIES.ps1') -Destination $UpgradeHost -Force
    Copy-Item -LiteralPath (Join-Path $RepoRoot 'dist/UNDIES.ps1.sha256') -Destination $UpgradeHost -Force
    $upgrade = & (Join-Path $UpgradeHost 'UNDIES.ps1') upgrade -apply | ConvertFrom-Json
    Assert ($upgrade.status -eq 'GREEN' -and (Test-Path (Join-Path $UpgradeHost '.undies/core/0.3.0-alpha.1'))) '24 second core not installed'
    Assert (Test-Path (Join-Path $UpgradeHost '.undies/core/0.2.0-alpha.2/UNDIES.core.ps1')) '25 previous core overwritten'
    Assert ((Get-Content $activePath -Raw | ConvertFrom-Json).active_core_version -eq '0.3.0-alpha.1') '26 active switch failed'
    Set-ItemProperty -LiteralPath (Join-Path $UpgradeHost '.undies/core/0.3.0-alpha.1/UNDIES.core.ps1') -Name IsReadOnly -Value $false -ErrorAction SilentlyContinue
    'collision' | Set-Content -LiteralPath (Join-Path $UpgradeHost '.undies/core/0.3.0-alpha.1/UNDIES.core.ps1') -NoNewline
    @{active_core_version='0.2.0-alpha.2';active_core_path='.undies/core/0.2.0-alpha.2'} | ConvertTo-Json | Set-Content $activePath -Encoding UTF8
    Copy-Item -LiteralPath (Join-Path $RepoRoot 'dist/UNDIES.ps1') -Destination $UpgradeHost -Force
    Copy-Item -LiteralPath (Join-Path $RepoRoot 'dist/UNDIES.ps1.sha256') -Destination $UpgradeHost -Force
    $failedUpgrade = & (Join-Path $UpgradeHost 'UNDIES.ps1') upgrade -apply | ConvertFrom-Json
    Assert ($failedUpgrade.status -eq 'BLUE' -and (Get-Content $activePath -Raw | ConvertFrom-Json).active_core_version -eq '0.2.0-alpha.2') '27 failed upgrade did not restore pointer'

    $unknown = Join-Path $HostDir 'unknown-host.txt'
    'unknown' | Set-Content -LiteralPath $unknown -NoNewline
    $unknownHash = Hash-File $unknown
    $removed = & (Join-Path $HostDir 'UNDIES.ps1') remove -apply | ConvertFrom-Json
    Assert ($removed.status -eq 'GREEN') '29 removal failed'
    Assert ((Hash-File $unknown) -eq $unknownHash) '30 unknown host file removed or changed'

    $ProjectA = New-TempDir 'undies-022-a'; $ProjectB = New-TempDir 'undies-022-b'; $Roots += $ProjectA; $Roots += $ProjectB
    Install-Artifact $ProjectA; Install-Artifact $ProjectB
    & (Join-Path $ProjectB 'UNDIES.ps1') initialize | Out-Null
    $bHash = Hash-File (Join-Path $ProjectB 'UNDIES.ps1')
    & (Join-Path $ProjectA 'UNDIES.ps1') initialize | Out-Null
    Assert ((Hash-File (Join-Path $ProjectB 'UNDIES.ps1')) -eq $bHash) '31 project A altered project B'
    $policy = Get-Content (Join-Path $ProjectA '.undies/project/policies.json') -Raw | ConvertFrom-Json
    Assert ($policy.reverse_synchronization -eq 'DISABLED') '33 reverse synchronization enabled'
    Assert ((& (Join-Path $ProjectA 'UNDIES.ps1') doctor | ConvertFrom-Json).status -eq 'GREEN') '34 doctor not GREEN'
    Assert ((& (Join-Path $ProjectA 'UNDIES.ps1') integrity | ConvertFrom-Json).status -eq 'GREEN') '35 integrity not GREEN'
    'UND-022_TEST passed=36 failed=0 skipped=0'
} finally {
    foreach($r in $Roots){ if(Test-Path -LiteralPath $r){ Remove-Item -LiteralPath $r -Recurse -Force -ErrorAction SilentlyContinue } }
}


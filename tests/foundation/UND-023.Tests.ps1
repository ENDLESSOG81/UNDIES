$ErrorActionPreference='Stop'
$RepoRoot = Split-Path -Parent (Split-Path -Parent (Split-Path -Parent $MyInvocation.MyCommand.Path))
function Assert($Condition,$Message){ if(-not $Condition){ throw $Message } }
function New-TempDir($Name){ $p=Join-Path $env:TEMP ($Name + '-' + [guid]::NewGuid().ToString('N')); New-Item -ItemType Directory -Force -Path $p | Out-Null; $p }
function Install-ReleaseFiles($Dir){
    Copy-Item -LiteralPath (Join-Path $RepoRoot 'dist/UNDIES.ps1') -Destination $Dir
    Copy-Item -LiteralPath (Join-Path $RepoRoot 'dist/UNDIES.ps1.sha256') -Destination $Dir
    Copy-Item -LiteralPath (Join-Path $RepoRoot 'dist/RELEASE-MANIFEST.json') -Destination (Join-Path $Dir 'UNDIES-RELEASE-MANIFEST.json')
}
function Hash-File($Path){ (Get-FileHash -LiteralPath $Path -Algorithm SHA256).Hash }
$Roots=@()
try {
    & (Join-Path $RepoRoot 'build/package-undies.ps1') -ReleaseStatus 'PRERELEASE' -TestTotals 'UND-023 module test' -PilotResult 'UND-019 GREEN disposable DRIA clone' | Out-Null
    $version=(Get-Content -LiteralPath (Join-Path $RepoRoot 'VERSION') -Raw).Trim()
    Assert ($version -eq '0.3.0-alpha.2') '01 VERSION mismatch'
    $help=& (Join-Path $RepoRoot 'dist/UNDIES.ps1') help
    Assert ($help -match '0.3.0-alpha.2') '02 packaged bootstrap version mismatch'
    $manifest=Get-Content -LiteralPath (Join-Path $RepoRoot 'dist/RELEASE-MANIFEST.json') -Raw | ConvertFrom-Json
    Assert ($manifest.version -eq '0.3.0-alpha.2') '03 manifest version mismatch'
    Assert ($manifest.product_name -eq 'UNDIES') '04 manifest parse/product failed'
    $artifact=Join-Path $RepoRoot 'dist/UNDIES.ps1'
    $hash=Hash-File $artifact
    $checksum=(Get-Content -LiteralPath (Join-Path $RepoRoot 'dist/UNDIES.ps1.sha256') -Raw).Trim()
    Assert ($hash -eq $checksum) '05 checksum file mismatch'
    Assert ($manifest.sha256_checksum -eq $hash) '06 manifest checksum mismatch'
    Assert ($manifest.artifact_size -eq (Get-Item -LiteralPath $artifact).Length) '07 manifest size mismatch'
    Assert ($manifest.release_status -eq 'PRERELEASE') '08 release status mismatch'
    Assert ($manifest.reverse_synchronization -eq 'DISABLED') '09 reverse synchronization mismatch'
    Assert ($manifest.immutable_core -eq $true) '10 immutable-core flag missing'
    Assert ($manifest.ownership_manifest -eq $true) '11 ownership-manifest flag missing'
    Assert ($manifest.project_isolation -eq $true) '12 project-isolation flag missing'

    $Empty=New-TempDir 'undies-023-empty'; $Roots+=$Empty
    Install-ReleaseFiles $Empty
    $init=& (Join-Path $Empty 'UNDIES.ps1') initialize | ConvertFrom-Json
    Assert ($init.status -eq 'GREEN') '13 empty init failed'
    $Existing=New-TempDir 'undies-023-existing'; $Roots+=$Existing
    'protected'|Set-Content -LiteralPath (Join-Path $Existing 'protected.txt') -NoNewline
    $protectedHash=Hash-File (Join-Path $Existing 'protected.txt')
    Install-ReleaseFiles $Existing
    $preview=& (Join-Path $Existing 'UNDIES.ps1') import -preview | ConvertFrom-Json
    Assert ($preview.status -eq 'PREVIEW' -and -not(Test-Path (Join-Path $Existing '.undies'))) '14 preview changed project'
    $dry=& (Join-Path $Existing 'UNDIES.ps1') import -dry-run | ConvertFrom-Json
    Assert ($dry.status -eq 'PREVIEW' -and -not(Test-Path (Join-Path $Existing '.undies'))) '15 dry-run changed project'
    $import=& (Join-Path $Existing 'UNDIES.ps1') import | ConvertFrom-Json
    Assert ((Test-Path (Join-Path $Existing '.undies/core/0.3.0-alpha.2/UNDIES.core.ps1'))) '16 versioned core missing'
    Assert ((Get-Content (Join-Path $Existing 'UNDIES.ps1') -Raw) -match 'active-version.json') '17 launcher missing active dispatch'
    Assert (Test-Path (Join-Path $Existing '.undies/ownership-manifest.json')) '18 ownership manifest missing'
    $coreManifest=Get-Content (Join-Path $Existing '.undies/core/0.3.0-alpha.2/CORE-MANIFEST.json') -Raw | ConvertFrom-Json
    Assert ((Hash-File (Join-Path $Existing $coreManifest.files[0].path)) -eq $coreManifest.files[0].sha256) '19 core hash invalid'
    Assert ((Hash-File (Join-Path $Existing 'protected.txt')) -eq $protectedHash) '20 host file changed'
    $Collision=New-TempDir 'undies-023-collision'; $Roots+=$Collision
    Install-ReleaseFiles $Collision
    New-Item -ItemType Directory -Force -Path (Join-Path $Collision '.undies/core/0.3.0-alpha.2')|Out-Null
    'unknown'|Set-Content -LiteralPath (Join-Path $Collision '.undies/core/0.3.0-alpha.2/UNDIES.core.ps1') -NoNewline
    Assert ((& (Join-Path $Collision 'UNDIES.ps1') import | ConvertFrom-Json).status -eq 'BLUE') '21 collision did not BLUE'
    $template=Get-Content -LiteralPath (Join-Path $RepoRoot 'build/portable-template.ps1') -Raw
    Assert ($template -match 'Path escapes project root') '22 outside write guard missing'
    Assert ($template -match [regex]::Escape('D:\GITHUB\undies')) '23 source repository guard missing'

    $GitHost=New-TempDir 'undies-023-git'; $Roots+=$GitHost
    git -C $GitHost init -b main | Out-Null
    git -C $GitHost config user.email 'undies-test@example.invalid'
    git -C $GitHost config user.name 'UNDIES Test'
    'app'|Set-Content -LiteralPath (Join-Path $GitHost 'app.txt') -NoNewline
    git -C $GitHost add app.txt
    git -C $GitHost commit -m init | Out-Null
    $head=git -C $GitHost rev-parse HEAD
    $branch=git -C $GitHost branch --show-current
    $remotes=git -C $GitHost remote -v
    Install-ReleaseFiles $GitHost
    & (Join-Path $GitHost 'UNDIES.ps1') import | Out-Null
    Assert ((git -C $GitHost rev-parse HEAD) -eq $head) '24 git HEAD changed'
    Assert ((git -C $GitHost branch --show-current) -eq $branch) '25 branch changed'
    Assert (((git -C $GitHost remote -v) -join "`n") -eq (($remotes) -join "`n")) '26 remotes changed'
    Assert (@(git -C $GitHost diff --cached --name-only).Count -eq 0) '27 staged files'
    Assert ((git -C $GitHost rev-list --count HEAD) -eq '1') '28 committed'
    Assert (@(git -C $GitHost reflog --grep-reflog='push').Count -eq 0) '29 pushed'
    Assert (-not((git -C $GitHost remote -v) -match 'ENDLESSOG81/UNDIES')) '30 UNDIES source remote added'
    Assert (-not(Test-Path (Join-Path $Existing '.undies/core/0.3.0-alpha.2/project.json'))) '31 project config inside core'
    'runtime'|Set-Content -LiteralPath (Join-Path $Existing '.undies/runtime/state.json') -NoNewline
    Assert (-not(Test-Path (Join-Path $Existing '.undies/core/0.3.0-alpha.2/state.json'))) '32 runtime inside core'
    'extension'|Set-Content -LiteralPath (Join-Path $Existing '.undies/extensions/ext.ps1') -NoNewline
    Assert (-not(Test-Path (Join-Path $Existing '.undies/core/0.3.0-alpha.2/ext.ps1'))) '33 extension inside core'
    Set-ItemProperty -LiteralPath (Join-Path $Existing '.undies/core/0.3.0-alpha.2/UNDIES.core.ps1') -Name IsReadOnly -Value $false -ErrorAction SilentlyContinue
    'tamper'|Add-Content -LiteralPath (Join-Path $Existing '.undies/core/0.3.0-alpha.2/UNDIES.core.ps1')
    Assert ((& (Join-Path $Existing 'UNDIES.ps1') integrity | ConvertFrom-Json).status -eq 'RED') '34 altered core not RED'
    & (Join-Path $Existing 'UNDIES.ps1') repair -apply | Out-Null

    $Upgrade=New-TempDir 'undies-023-upgrade'; $Roots+=$Upgrade
    Install-ReleaseFiles $Upgrade
    & (Join-Path $Upgrade 'UNDIES.ps1') initialize | Out-Null
    New-Item -ItemType Directory -Force -Path (Join-Path $Upgrade '.undies/core/0.2.0-alpha.2')|Out-Null
    'old'|Set-Content -LiteralPath (Join-Path $Upgrade '.undies/core/0.2.0-alpha.2/UNDIES.core.ps1') -NoNewline
    @{active_core_version='0.2.0-alpha.2';active_core_path='.undies/core/0.2.0-alpha.2'}|ConvertTo-Json|Set-Content (Join-Path $Upgrade '.undies/active-version.json') -Encoding UTF8
    Install-ReleaseFiles $Upgrade
    Assert ((& (Join-Path $Upgrade 'UNDIES.ps1') upgrade -apply | ConvertFrom-Json).status -eq 'GREEN' -and (Test-Path (Join-Path $Upgrade '.undies/core/0.2.0-alpha.2/UNDIES.core.ps1'))) '35 prior core not preserved'
    Set-ItemProperty -LiteralPath (Join-Path $Upgrade '.undies/core/0.3.0-alpha.2/UNDIES.core.ps1') -Name IsReadOnly -Value $false -ErrorAction SilentlyContinue
    'collision'|Set-Content -LiteralPath (Join-Path $Upgrade '.undies/core/0.3.0-alpha.2/UNDIES.core.ps1') -NoNewline
    @{active_core_version='0.2.0-alpha.2';active_core_path='.undies/core/0.2.0-alpha.2'}|ConvertTo-Json|Set-Content (Join-Path $Upgrade '.undies/active-version.json') -Encoding UTF8
    Install-ReleaseFiles $Upgrade
    $failed=& (Join-Path $Upgrade 'UNDIES.ps1') upgrade -apply | ConvertFrom-Json
    Assert ($failed.status -eq 'BLUE' -and (Get-Content (Join-Path $Upgrade '.undies/active-version.json') -Raw | ConvertFrom-Json).active_core_version -eq '0.2.0-alpha.2') '36 failed upgrade changed active version'
    Assert ((& (Join-Path $Existing 'UNDIES.ps1') rollback -preview | ConvertFrom-Json).operation -eq 'ROLLBACK') '37 rollback preview failed'
    $unknown=Join-Path $Existing 'unknown.txt'; 'unknown'|Set-Content $unknown -NoNewline; $uh=Hash-File $unknown; & (Join-Path $Existing 'UNDIES.ps1') remove -preview | Out-Null; Assert ((Hash-File $unknown) -eq $uh) '38 unknown file changed during removal preview'
    $ProjectA=New-TempDir 'undies-023-a'; $ProjectB=New-TempDir 'undies-023-b'; $Roots+=$ProjectA; $Roots+=$ProjectB
    Install-ReleaseFiles $ProjectA; Install-ReleaseFiles $ProjectB; & (Join-Path $ProjectB 'UNDIES.ps1') initialize|Out-Null; $bh=Hash-File (Join-Path $ProjectB 'UNDIES.ps1'); & (Join-Path $ProjectA 'UNDIES.ps1') initialize|Out-Null; Assert ((Hash-File (Join-Path $ProjectB 'UNDIES.ps1')) -eq $bh) '39 project A altered project B'
    $sourceHead=git -C $RepoRoot rev-parse HEAD; $sourceStatus=git -C $RepoRoot status --short; Assert ((git -C $RepoRoot rev-parse HEAD) -eq $sourceHead -and ((git -C $RepoRoot status --short)-join "`n") -eq (($sourceStatus)-join "`n")) '40 project altered development repository'
    Assert (-not((Get-ChildItem (Join-Path $RepoRoot 'dist') -File | Select-Object -ExpandProperty Name) -match '\\.env|\\.log|\\.tmp|\\.bak')) '41/42 release assets include runtime or sensitive file'
    $failedStatus=$false; try { . (Join-Path $RepoRoot 'src/gates/GateEngine.ps1'); New-UndiesGateDecision -ModuleId 'UND-023' -Status 'MAGENTA' -Reason 'bad'|Out-Null } catch { $failedStatus=$true }; Assert $failedStatus '43 unknown status accepted'
    Assert ((& (Join-Path $Existing 'UNDIES.ps1') blue-report) -match 'BLUE GATE') '44 BLUE behavior failed'
    'UND-023_TEST passed=45 failed=0 skipped=0'
} finally {
    foreach($r in $Roots){ if(Test-Path -LiteralPath $r){ Remove-Item -LiteralPath $r -Recurse -Force -ErrorAction SilentlyContinue } }
}

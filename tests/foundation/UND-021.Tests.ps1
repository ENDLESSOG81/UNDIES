$ErrorActionPreference='Stop'
$RepoRoot = Split-Path -Parent (Split-Path -Parent (Split-Path -Parent $MyInvocation.MyCommand.Path))
function Assert($Condition,$Message){ if(-not $Condition){ throw $Message } }
$Fresh = Join-Path $env:TEMP ('undies-021-fresh-' + [guid]::NewGuid().ToString('N'))
$Download = Join-Path $env:TEMP ('undies-021-download-' + [guid]::NewGuid().ToString('N'))
try {
    $attrs = Get-Content -LiteralPath (Join-Path $RepoRoot '.gitattributes') -Raw
    Assert ($attrs -match 'dist/UNDIES\.ps1 -text') 'dist UNDIES line-ending protection missing'
    Assert ($attrs -match 'dist/UNDIES\.ps1\.sha256 -text') 'dist checksum line-ending protection missing'

    & (Join-Path $RepoRoot 'build/package-undies.ps1') -TestTotals 'UND-021 release integrity test' -PilotResult 'UND-019 GREEN disposable DRIA clone' -ReleaseStatus 'alpha-prerelease' | Out-Null
    $artifact = Join-Path $RepoRoot 'dist/UNDIES.ps1'
    $checksumFile = Join-Path $RepoRoot 'dist/UNDIES.ps1.sha256'
    $manifestFile = Join-Path $RepoRoot 'dist/RELEASE-MANIFEST.json'
    $hash = (Get-FileHash -LiteralPath $artifact -Algorithm SHA256).Hash
    $checksum = (Get-Content -LiteralPath $checksumFile -Raw).Trim()
    $manifest = Get-Content -LiteralPath $manifestFile -Raw | ConvertFrom-Json
    Assert ($hash -eq $checksum) 'local checksum file mismatch'
    Assert ($manifest.version -eq '0.2.0-alpha.2') 'manifest version mismatch'
    Assert ($manifest.sha256_checksum -eq $hash) 'manifest checksum mismatch'

    git clone --no-local $RepoRoot $Fresh | Out-Null
    $freshHash = (Get-FileHash -LiteralPath (Join-Path $Fresh 'dist/UNDIES.ps1') -Algorithm SHA256).Hash
    $freshChecksum = (Get-Content -LiteralPath (Join-Path $Fresh 'dist/UNDIES.ps1.sha256') -Raw).Trim()
    Assert ($freshHash -eq $freshChecksum) 'fresh checkout checksum mismatch'
    $freshInit = Join-Path $env:TEMP ('undies-021-init-' + [guid]::NewGuid().ToString('N'))
    New-Item -ItemType Directory -Force -Path $freshInit | Out-Null
    Copy-Item -LiteralPath (Join-Path $Fresh 'dist/UNDIES.ps1') -Destination $freshInit
    $init = & (Join-Path $freshInit 'UNDIES.ps1') initialize | ConvertFrom-Json
    Assert ($init.version -eq '0.2.0-alpha.2') 'fresh checkout artifact initialize failed'
    Remove-Item -LiteralPath $freshInit -Recurse -Force

    New-Item -ItemType Directory -Force -Path $Download | Out-Null
    Copy-Item -LiteralPath $artifact -Destination $Download
    Copy-Item -LiteralPath $checksumFile -Destination $Download
    $downloadHash = (Get-FileHash -LiteralPath (Join-Path $Download 'UNDIES.ps1') -Algorithm SHA256).Hash
    $downloadChecksum = (Get-Content -LiteralPath (Join-Path $Download 'UNDIES.ps1.sha256') -Raw).Trim()
    Assert ($downloadHash -eq $downloadChecksum) 'downloaded release asset checksum mismatch'
    'UND-021_TEST passed=10 failed=0 skipped=0'
} finally {
    foreach($p in @($Fresh,$Download)){ if(Test-Path -LiteralPath $p){ Remove-Item -LiteralPath $p -Recurse -Force -ErrorAction SilentlyContinue } }
}

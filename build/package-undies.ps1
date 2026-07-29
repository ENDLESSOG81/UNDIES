param(
    [string]$Root = (Resolve-Path (Join-Path $PSScriptRoot '..')).Path,
    [string]$ReleaseStatus = 'alpha-prerelease',
    [string]$PilotResult = 'UND-019 GREEN',
    [string]$TestTotals = 'pending'
)
$ErrorActionPreference = 'Stop'
$dist = Join-Path $Root 'dist'
$version = (Get-Content -LiteralPath (Join-Path $Root 'VERSION') -Raw).Trim()
$artifact = Join-Path $dist 'UNDIES.ps1'
$checksumFile = Join-Path $dist 'UNDIES.ps1.sha256'
$manifestFile = Join-Path $dist 'RELEASE-MANIFEST.json'
New-Item -ItemType Directory -Force -Path $dist | Out-Null
Copy-Item -LiteralPath (Join-Path $Root 'build/portable-template.ps1') -Destination $artifact -Force
$hash = Get-FileHash -LiteralPath $artifact -Algorithm SHA256
$hash.Hash | Set-Content -LiteralPath $checksumFile -Encoding ASCII
try { $sourceCommit = (git -C $Root rev-parse HEAD 2>$null) } catch { $sourceCommit = 'UNKNOWN' }
$manifest = [ordered]@{
    product_name = 'UNDIES'
    version = $version
    build_date_utc = [DateTime]::UtcNow.ToString('o')
    source_commit = $sourceCommit
    powershell_compatibility = @('PowerShell 7 preferred','Windows PowerShell 5.1 compatible where standard .NET APIs are available')
    artifact_filename = 'UNDIES.ps1'
    artifact_size = (Get-Item -LiteralPath $artifact).Length
    sha256_checksum = $hash.Hash
    supported_deployment_modes = @('empty-folder initialize','existing non-Git adoption','existing Git repository adoption','upgrade','repair','rollback','removal')
    supported_upgrade_range = @('0.1.0-alpha.1','0.1.0-alpha.2','0.2.0-alpha.1')
    required_dependencies = @('PowerShell','standard .NET APIs')
    external_connections = @('none required for portable operation')
    known_limitations = @('alpha prerelease','GitHub release publication may require authenticated external tooling','project-specific test execution requires operator authorization')
    test_totals = $TestTotals
    pilot_result = $PilotResult
    release_status = $ReleaseStatus
}
$manifest | ConvertTo-Json -Depth 20 | Set-Content -LiteralPath $manifestFile -Encoding UTF8
Write-Host "Generated $artifact"
Write-Host "Generated $checksumFile"
Write-Host "Generated $manifestFile"

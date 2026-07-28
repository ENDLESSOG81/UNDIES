param([string]$Root = (Resolve-Path (Join-Path $PSScriptRoot '..')).Path)
$dist = Join-Path $Root 'dist'
New-Item -ItemType Directory -Force -Path $dist | Out-Null
Copy-Item -LiteralPath (Join-Path $Root 'build/portable-template.ps1') -Destination (Join-Path $dist 'UNDIES.ps1') -Force
Write-Host "Generated $(Join-Path $dist 'UNDIES.ps1')"

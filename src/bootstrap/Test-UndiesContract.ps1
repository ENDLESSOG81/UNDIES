param(
    [string]$Root = (Resolve-Path (Join-Path $PSScriptRoot '..\..')).Path,
    [string[]]$ModuleFiles = @()
)
. (Join-Path $PSScriptRoot 'Core.ps1')
$result = Test-UndiesContracts -Root $Root -ModuleFiles $ModuleFiles
$result | ConvertTo-Json -Depth 20
if (-not $result.Passed) { exit 1 }

param([switch]$Quiet)
$ErrorActionPreference = 'Stop'
$Root = Resolve-Path (Join-Path $PSScriptRoot '..\..')
$NormativeFiles = @(
    'README.md',
    'docs/governance/STERILE-GOVERNANCE.md',
    'docs/governance/ADOPTION-REFERENCE-MODEL.md',
    'docs/operations/EMBEDDED-CORE-TRANSITION.md',
    'docs/operations/MIGRATING-EMBEDDED-ADOPTIONS.md',
    'docs/operations/VALIDATION-POLICY.md',
    'templates/adoption/UNDIES.md',
    'templates/adoption/project.yaml',
    'schemas/adoption-project.schema.json'
)
$Forbidden = @(
    'BBCN',
    'The Vault',
    'SOCKS',
    'RAMWISE',
    'DIRA',
    'DRIA',
    'AIRDS',
    'RICO',
    'Discord',
    'Supabase',
    'CockroachDB',
    'Vercel',
    'Railway',
    'C:\\',
    'D:\\GITHUB',
    'D:/GITHUB',
    'ENDLESSOG81/(?!UNDIES)'
)
$failures = New-Object System.Collections.Generic.List[string]
foreach($relative in $NormativeFiles){
    $path = Join-Path $Root $relative
    if(-not (Test-Path -LiteralPath $path)){
        $failures.Add("Missing normative file: $relative")
        continue
    }
    $text = Get-Content -LiteralPath $path -Raw
    foreach($pattern in $Forbidden){
        if($text -match $pattern){
            $failures.Add("Forbidden project-specific term '$pattern' found in $relative")
        }
    }
}
$template = Get-Content -LiteralPath (Join-Path $Root 'templates/adoption/project.yaml') -Raw
foreach($required in @('<PROJECT_NAME>','<PROJECT_CODE>','<UNDIES_VERSION>','<UNDIES_SOURCE_COMMIT>','source_dependency: "NONE"','reverse_synchronization: "DISABLED"','copied_core: false')){
    if($template -notlike "*$required*"){
        $failures.Add("project.yaml template missing $required")
    }
}
$readme = Get-Content -LiteralPath (Join-Path $Root 'README.md') -Raw
foreach($required in @('UNDIES.md','.undies/project.yaml','source repository','Reverse synchronization')){
    if($readme -notlike "*$required*"){
        $failures.Add("README missing sterile model phrase: $required")
    }
}
if($failures.Count -gt 0){
    $failures | ForEach-Object { Write-Host "[FAIL] $_" }
    exit 1
}
if(-not $Quiet){ Write-Host 'TOTAL passed=1 failed=0 skipped=0' }
exit 0

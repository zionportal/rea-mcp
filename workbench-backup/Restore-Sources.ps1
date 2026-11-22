[CmdletBinding()]
param(
    [Parameter(Mandatory=$true)][string]$Destination,
    [string[]]$Only
)

$ErrorActionPreference = 'Stop'
$library = Get-Content -LiteralPath (Join-Path $PSScriptRoot 'repository-library.json') -Raw | ConvertFrom-Json
if ($library.schema_version -ne 1) { throw 'Unsupported repository library version.' }
if (-not (Get-Command git -ErrorAction SilentlyContinue)) { throw 'Git is required.' }
$entries = @($library.repositories)
if ($Only) {
    foreach ($name in $Only) {
        if (-not ($entries | Where-Object { $_.name -ceq $name })) { throw "Unknown repository: $name" }
    }
    $entries = @($entries | Where-Object { $Only -ccontains $_.name })
}
$dest = [IO.Path]::GetFullPath($Destination)
if (-not (Test-Path -LiteralPath $dest -PathType Container)) { throw "Destination must be an existing folder: $dest" }
$paths = @{}
foreach ($src in $entries) {
    if ($src.name -notmatch '^[A-Za-z0-9._-]+$' -or $src.name -in @('.', '..') -or $src.commit -notmatch '^[0-9a-f]{40}$' -or $src.url -notmatch '^https://github\.com/[A-Za-z0-9_.-]+/[A-Za-z0-9_.-]+\.git$' -or $src.location -notin @('sources','root')) { throw 'Invalid repository library entry.' }
    $parent = if ($src.location -eq 'root') { $dest } else { Join-Path $dest 'sources' }
    $checkout = Join-Path $parent $src.name
    if ($paths.ContainsKey($checkout) -or (Test-Path -LiteralPath $checkout)) { throw "Source destination already exists or is duplicated: $checkout" }
    $paths[$checkout] = $true
}
$oldLfs = $env:GIT_LFS_SKIP_SMUDGE
$env:GIT_LFS_SKIP_SMUDGE = '1'
try {
    foreach ($src in $entries) {
        $parent = if ($src.location -eq 'root') { $dest } else { Join-Path $dest 'sources' }
        New-Item -ItemType Directory -Path $parent -Force | Out-Null
        $checkout = Join-Path $parent $src.name
        & git init --quiet $checkout
        if ($LASTEXITCODE -ne 0) { throw "git init failed: $($src.name)" }
        & git -C $checkout remote add origin $src.url
        if ($LASTEXITCODE -ne 0) { throw "git remote failed: $($src.name)" }
        & git -C $checkout -c core.longpaths=true fetch --quiet --depth 1 origin $src.commit
        if ($LASTEXITCODE -ne 0) { throw "Source fetch failed: $($src.name)" }
        & git -C $checkout -c core.longpaths=true checkout --quiet --detach FETCH_HEAD
        if ($LASTEXITCODE -ne 0) { throw "Source checkout failed: $($src.name)" }
        $actual = (& git -C $checkout rev-parse HEAD).Trim()
        if ($LASTEXITCODE -ne 0 -or $actual -cne $src.commit) { throw "Source commit mismatch: $($src.name)" }
        Write-Host "Restored source $($src.name) at $actual"
    }
} finally { $env:GIT_LFS_SKIP_SMUDGE = $oldLfs }

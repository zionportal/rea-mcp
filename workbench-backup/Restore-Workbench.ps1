[CmdletBinding()]
param(
    [Parameter(Mandatory=$true)][string]$Destination,
    [string]$CacheDirectory,
    [switch]$AllowDownload,
    [string[]]$Only,
    [switch]$IncludeSources,
    [switch]$InstallPlaywright
)

$ErrorActionPreference = 'Stop'
$manifest = Get-Content -LiteralPath (Join-Path $PSScriptRoot 'artifacts.json') -Raw | ConvertFrom-Json
if ($manifest.schema_version -ne 1) { throw 'Unsupported manifest version.' }
if (($IncludeSources -or $InstallPlaywright) -and -not $AllowDownload) { throw 'Source checkouts and Playwright setup need -AllowDownload.' }
if ($Only -and ($IncludeSources -or $InstallPlaywright)) { throw '-Only is for a partial restore and cannot be combined with source or browser setup.' }

$requested = @($manifest.archives)
if ($Only) {
    foreach ($name in $Only) {
        if (-not ($manifest.archives | Where-Object { $_.file -ceq $name })) { throw "Unknown artifact: $name" }
    }
    $requested = @($manifest.archives | Where-Object { $Only -ccontains $_.file })
}

$dest = [IO.Path]::GetFullPath($Destination)
if (Test-Path -LiteralPath $dest) { throw "Destination already exists; refusing to overwrite: $dest" }
$parent = Split-Path -Parent $dest
if (-not (Test-Path -LiteralPath $parent -PathType Container)) { throw "Destination parent does not exist: $parent" }
if ($CacheDirectory) {
    $cache = (Resolve-Path -LiteralPath $CacheDirectory).Path
    if (-not (Test-Path -LiteralPath $cache -PathType Container)) { throw 'CacheDirectory must be a folder.' }
} else { $cache = $null }

# Validate every selected manifest entry before creating the destination.
foreach ($item in $requested) {
    if ($item.file -ne [IO.Path]::GetFileName($item.file) -or $item.file -match '[\\/:]') { throw 'Invalid archive file name in manifest.' }
    if ($item.destination -notmatch '^[A-Za-z0-9._-]+$' -or $item.destination -in @('.', '..')) { throw 'Invalid destination in manifest.' }
    if ($item.sha256 -notmatch '^[a-fA-F0-9]{64}$') { throw 'Invalid checksum in manifest.' }
    if ($item.method -notin @('tar', 'seven_sfx', 'seven_nsis', 'keep')) { throw 'Unknown extraction method.' }
    $uri = [uri]$item.url
    if ($uri.Scheme -ne 'https' -or $uri.UserInfo -or $uri.Host -notin @('github.com','nodejs.org','registry.npmjs.org','mirror.httrack.com','renderdoc.org','qemu.weilnetz.de','download.sysinternals.com','www.angusj.com')) { throw 'Unapproved download URL in manifest.' }
}
if (($requested | Where-Object { $_.method -eq 'seven_sfx' }) -and -not ($requested | Where-Object { $_.file -eq '7z2606-extra.7z' })) { throw '7-Zip SFX requires including 7z2606-extra.7z.' }
if (($requested | Where-Object { $_.method -eq 'seven_nsis' }) -and -not (($requested | Where-Object { $_.file -eq '7z2606-extra.7z' }) -and ($requested | Where-Object { $_.file -eq '7z2606-x64.exe' }))) { throw 'QEMU extraction requires both 7-Zip artifacts.' }

New-Item -ItemType Directory -Path $dest | Out-Null
$downloadDir = Join-Path $dest 'downloads'
New-Item -ItemType Directory -Path $downloadDir | Out-Null
$completed = [System.Collections.Generic.List[string]]::new()
try {
    foreach ($item in $requested) {
        $archive = Join-Path $downloadDir $item.file
        $cached = if ($cache) { Join-Path $cache $item.file } else { $null }
        if ($cached -and (Test-Path -LiteralPath $cached -PathType Leaf)) {
            Copy-Item -LiteralPath $cached -Destination $archive
        } elseif ($AllowDownload) {
            Write-Host "Downloading $($item.file)"
            Invoke-WebRequest -Uri $item.url -OutFile $archive -UseBasicParsing
        } else { throw "Missing cached artifact $($item.file); supply a cache or explicitly allow downloads." }
        if ((Get-Item -LiteralPath $archive).Length -ne [long]$item.size) { throw "Size mismatch: $($item.file)" }
        if ((Get-FileHash -LiteralPath $archive -Algorithm SHA256).Hash -ne $item.sha256) { throw "SHA-256 mismatch: $($item.file)" }
        if ($item.method -ne 'keep') {
            $target = Join-Path $dest $item.destination
            New-Item -ItemType Directory -Path $target -Force | Out-Null
            switch ($item.method) {
                'tar' {
                    $arguments = @('-xf', $archive, '-C', $target)
                    if ($item.strip_components -gt 0) { $arguments += "--strip-components=$($item.strip_components)" }
                    & tar.exe @arguments
                }
                'seven_sfx' { & (Join-Path $dest '7zip-extra\x64\7za.exe') x $archive "-o$target" -y | Out-Null }
                'seven_nsis' { & (Join-Path $dest '7zip\7z.exe') x $archive "-o$target" -y | Out-Null }
            }
            if ($LASTEXITCODE -ne 0) { throw "Extraction failed for $($item.file): $LASTEXITCODE" }
        }
        $completed.Add($item.file)
        Write-Host "Restored $($item.file)"
    }

    if (-not $Only) {
        Get-ChildItem -LiteralPath (Join-Path $PSScriptRoot 'first-party') -File | Copy-Item -Destination $dest
        $pwDir = Join-Path $dest 'playwright'
        New-Item -ItemType Directory -Path $pwDir -Force | Out-Null
        Copy-Item -LiteralPath (Join-Path $PSScriptRoot 'playwright-lock\package.json'),(Join-Path $PSScriptRoot 'playwright-lock\package-lock.json') -Destination $pwDir
    }

    if ($InstallPlaywright) {
        $nodeRoot = Join-Path $dest 'node-v24.22.3-win-x64'
        $node = Join-Path $nodeRoot 'node.exe'
        $oldPath = $env:PATH; $oldBrowsers = $env:PLAYWRIGHT_BROWSERS_PATH
        try {
            $env:PATH = "$nodeRoot;$env:PATH"
            $env:PLAYWRIGHT_BROWSERS_PATH = Join-Path $dest 'playwright\browsers'
            & $node (Join-Path $nodeRoot 'node_modules\npm\bin\npm-cli.js') ci --prefix (Join-Path $dest 'playwright') --no-audit --no-fund
            if ($LASTEXITCODE -ne 0) { throw 'Playwright npm installation failed.' }
            & $node (Join-Path $dest 'playwright\node_modules\playwright\cli.js') install chromium
            if ($LASTEXITCODE -ne 0) { throw 'Playwright browser installation failed.' }
        } finally { $env:PATH = $oldPath; $env:PLAYWRIGHT_BROWSERS_PATH = $oldBrowsers }
    }

    if ($IncludeSources) {
        & (Join-Path $PSScriptRoot 'Restore-Sources.ps1') -Destination $dest
        New-Item -ItemType Directory -Path (Join-Path $dest 'sources') -Force | Out-Null
        Copy-Item -LiteralPath (Join-Path $PSScriptRoot 'sources-inventory.md') -Destination (Join-Path $dest 'sources\README.md')
    }
    $receipt = [ordered]@{status='selected_artifacts_restored'; partial=[bool]$Only; artifacts=@($completed); sources_requested=[bool]$IncludeSources; playwright_requested=[bool]$InstallPlaywright; emba_ready=$false; mcp_registered=$false; created_utc=[DateTime]::UtcNow.ToString('o')}
    $receipt | ConvertTo-Json -Depth 5 | Set-Content -LiteralPath (Join-Path $dest 'restore-receipt.json') -Encoding utf8
    Write-Host "Restore finished at $dest. Read restore-receipt.json and the setup notes."
} catch {
    Write-Error "Restore stopped; partial files remain at $dest. Nothing was overwritten. $($_.Exception.Message)"
    exit 1
}

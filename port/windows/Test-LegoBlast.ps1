param(
    [string]$VcpkgRoot = $env:VCPKG_ROOT,
    [string]$BuildDir,
    [switch]$BuildOnly
)
$ErrorActionPreference = 'Stop'

function Invoke-Checked {
    param([string]$Program, [string[]]$Arguments)
    & $Program @Arguments
    if ($LASTEXITCODE -ne 0) {
        throw "$Program a retourne le code $LASTEXITCODE."
    }
}

$root = (Resolve-Path (Join-Path $PSScriptRoot '..\..')).Path
$port = Join-Path $root 'port'
if (-not $BuildDir) {
    $BuildDir = Join-Path $port 'out\windows'
}
$BuildDir = [IO.Path]::GetFullPath($BuildDir)
if (-not (Get-Command cmake -ErrorAction SilentlyContinue)) {
    throw 'Installez CMake et ajoutez-le au PATH.'
}
if (-not $VcpkgRoot) {
    foreach ($candidate in @($env:VCPKG_INSTALLATION_ROOT, (Join-Path $port 'out\vcpkg'))) {
        if ($candidate -and (Test-Path (Join-Path $candidate 'scripts\buildsystems\vcpkg.cmake'))) {
            $VcpkgRoot = $candidate
            break
        }
    }
}
if (-not $VcpkgRoot) {
    if (-not (Get-Command git -ErrorAction SilentlyContinue)) {
        throw 'Installez Git pour recuperer vcpkg, ou definissez VCPKG_ROOT.'
    }
    $VcpkgRoot = Join-Path $port 'out\vcpkg'
    New-Item -ItemType Directory -Force (Split-Path -Parent $VcpkgRoot) | Out-Null
    Invoke-Checked 'git' @('clone', '--depth', '1', '--branch', '2025.10.17',
        'https://github.com/microsoft/vcpkg.git', $VcpkgRoot)
}
$toolchain = Join-Path $VcpkgRoot 'scripts\buildsystems\vcpkg.cmake'
if (-not (Test-Path $toolchain)) {
    throw "Installation vcpkg introuvable dans $VcpkgRoot."
}
if (-not (Test-Path (Join-Path $VcpkgRoot 'vcpkg.exe'))) {
    Invoke-Checked (Join-Path $VcpkgRoot 'bootstrap-vcpkg.bat') @('-disableMetrics')
}

Invoke-Checked 'cmake' @('-S', $port, '-B', $BuildDir, '-G', 'Visual Studio 17 2022',
    '-A', 'x64', "-DCMAKE_TOOLCHAIN_FILE=$toolchain", '-DVCPKG_TARGET_TRIPLET=x64-windows',
    '-DBUILD_TESTING=OFF')
Invoke-Checked 'cmake' @('--build', $BuildDir, '--config', 'Release', '--parallel')
$release = Join-Path $BuildDir 'Release'
$preview = Join-Path $release 'asset_preview.exe'
$assets = Join-Path $release 'demo-assets'
New-Item -ItemType Directory -Force $assets | Out-Null

$worlds = Join-Path $root 'amiga\src\LEGO_WORLDS'
Copy-Item (Join-Path $worlds 'lego2.png') (Join-Path $assets 'lanczos.png') -Force
Copy-Item (Join-Path $worlds 'lego2_pixelart.png') (Join-Path $assets 'pixel-art.png') -Force
$manifest = @{
    version = 1
    images = [ordered]@{
        'lanczos' = @{
            logical_size = @(300, 192)
            pixel_size = @(1600, 1024)
            variants = @{ '1' = @{ image = 'lanczos.png' } }
        }
        'pixel-art' = @{
            logical_size = @(300, 192)
            pixel_size = @(1600, 1024)
            variants = @{ '1' = @{ image = 'pixel-art.png' } }
        }
    }
    sounds = @{}
    music = @{}
}
$manifestPath = Join-Path $assets 'manifest.json'
[IO.File]::WriteAllText($manifestPath, ($manifest | ConvertTo-Json -Depth 8))
Copy-Item (Join-Path $PSScriptRoot 'Ouvrir-Apercu.cmd') $release -Force
Invoke-Checked $preview @($assets, '--check')
if (-not $BuildOnly) {
    Invoke-Checked $preview @($assets)
}

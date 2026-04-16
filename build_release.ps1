# build_release.ps1 — Sync release repo from source repo
# Run from the gamma-mp-release directory
# Sources files from the stalker-gamma-online repo and local ANOMALY build
#
# Usage: powershell -ExecutionPolicy Bypass -File build_release.ps1

$ErrorActionPreference = "Stop"
$releaseDir = Split-Path -Parent $MyInvocation.MyCommand.Definition
$sourceRepo = "$env:USERPROFILE\Documents\GitHub\stalker-gamma-online\gamma-mp"

Write-Host ""
Write-Host "=== GAMMA MP Release Builder ===" -ForegroundColor Cyan
Write-Host "  Release dir: $releaseDir" -ForegroundColor DarkGray
Write-Host "  Source repo: $sourceRepo" -ForegroundColor DarkGray
Write-Host ""

# --- Verify source repo exists ---
if (-not (Test-Path "$sourceRepo\lua-sync")) {
    Write-Host "ERROR: Source repo not found at $sourceRepo" -ForegroundColor Red
    Write-Host "Expected stalker-gamma-online\gamma-mp\lua-sync\ to exist."
    pause; exit 1
}

# --- 1. Sync scripts from lua-sync ---
Write-Host "Syncing scripts..." -ForegroundColor Yellow
$scriptsDir = Join-Path $releaseDir "scripts"
New-Item -ItemType Directory -Path $scriptsDir -Force | Out-Null

$scripts = @(
    "mp_core.script",
    "mp_protocol.script",
    "mp_host_events.script",
    "mp_client_state.script",
    "mp_alife_guard.script",
    "mp_puppet.script",
    "mp_ui.script"
)

foreach ($s in $scripts) {
    $src = Join-Path $sourceRepo "lua-sync\$s"
    if (Test-Path $src) {
        Copy-Item $src (Join-Path $scriptsDir $s) -Force
        Write-Host "  [OK] $s" -ForegroundColor Green
    } else {
        Write-Host "  [SKIP] $s (not found)" -ForegroundColor Yellow
    }
}

# --- 2. Sync mod patches ---
Write-Host "Syncing mod patches..." -ForegroundColor Yellow
$patchSource = Join-Path $sourceRepo "mod-patches"
$patchDir = Join-Path $releaseDir "patches"
New-Item -ItemType Directory -Path $patchDir -Force | Out-Null
if (Test-Path $patchSource) {
    $patches = Get-ChildItem $patchSource -Filter "*.script"
    foreach ($p in $patches) {
        Copy-Item $p.FullName (Join-Path $patchDir $p.Name) -Force
        Write-Host "  [OK] $($p.Name) (mod patch)" -ForegroundColor Green
    }
} else {
    Write-Host "  [SKIP] No mod-patches directory" -ForegroundColor Yellow
}

# --- 3. Sync UI XML ---
Write-Host "Syncing UI..." -ForegroundColor Yellow
$uiDir = Join-Path $releaseDir "ui"
New-Item -ItemType Directory -Path $uiDir -Force | Out-Null

$uiSource = Join-Path $sourceRepo "..\gamedata\configs\ui\ui_mp_menu.xml"
if (-not (Test-Path $uiSource)) {
    # Try alternate location in GAMMA overwrite
    $uiSource = "C:\GAMMA\overwrite\gamedata\configs\ui\ui_mp_menu.xml"
}
if (Test-Path $uiSource) {
    Copy-Item $uiSource (Join-Path $uiDir "ui_mp_menu.xml") -Force
    Write-Host "  [OK] ui_mp_menu.xml" -ForegroundColor Green
} else {
    Write-Host "  [WARN] ui_mp_menu.xml not found - check source path" -ForegroundColor Yellow
}

# --- 4. Sync engine binaries from ANOMALY build ---
Write-Host "Syncing engine binaries..." -ForegroundColor Yellow
$binDir = Join-Path $releaseDir "bin"
New-Item -ItemType Directory -Path $binDir -Force | Out-Null

$anomalyBin = "C:\ANOMALY\bin"
$engineSource = Join-Path $anomalyBin "AnomalyDX11AVX.exe"
if (Test-Path $engineSource) {
    Copy-Item $engineSource (Join-Path $binDir "AnomalyDX11AVX.exe") -Force
    Write-Host "  [OK] AnomalyDX11AVX.exe" -ForegroundColor Green
} else {
    Write-Host "  [WARN] AnomalyDX11AVX.exe not found at $engineSource" -ForegroundColor Yellow
}

# DLLs — copy from ANOMALY bin or from gns-bridge build
$dlls = @(
    "gns_bridge.dll",
    "GameNetworkingSockets.dll",
    "abseil_dll.dll",
    "libcrypto-3-x64.dll",
    "libprotobuf.dll"
)

foreach ($dll in $dlls) {
    $src = Join-Path $anomalyBin $dll
    if (Test-Path $src) {
        Copy-Item $src (Join-Path $binDir $dll) -Force
        Write-Host "  [OK] $dll" -ForegroundColor Green
    } else {
        # Already in release bin from previous build?
        if (Test-Path (Join-Path $binDir $dll)) {
            Write-Host "  [KEEP] $dll (already in release)" -ForegroundColor DarkGray
        } else {
            Write-Host "  [WARN] $dll not found" -ForegroundColor Yellow
        }
    }
}

# --- 5. Read version from mp_core.script ---
$coreScript = Join-Path $scriptsDir "mp_core.script"
$version = "unknown"
if (Test-Path $coreScript) {
    $match = Select-String -Path $coreScript -Pattern 'MP_VERSION\s*=\s*"([^"]+)"'
    if ($match) {
        $version = $match.Matches[0].Groups[1].Value
    }
}
Write-Host ""
Write-Host "Version: $version" -ForegroundColor Cyan

# --- 6. Write version stamp ---
$versionFile = Join-Path $releaseDir "VERSION"
Set-Content $versionFile $version -NoNewline
Write-Host "  [OK] VERSION file written" -ForegroundColor Green

# --- 7. Summary ---
Write-Host ""
Write-Host "=== Release Contents ===" -ForegroundColor Yellow

$totalFiles = 0
Write-Host "  bin/" -ForegroundColor White
Get-ChildItem $binDir | ForEach-Object {
    $size = [math]::Round($_.Length / 1MB, 1)
    Write-Host "    $($_.Name) ($size MB)" -ForegroundColor DarkGray
    $totalFiles++
}

Write-Host "  scripts/" -ForegroundColor White
Get-ChildItem $scriptsDir | ForEach-Object {
    $size = [math]::Round($_.Length / 1KB, 1)
    Write-Host "    $($_.Name) ($size KB)" -ForegroundColor DarkGray
    $totalFiles++
}

Write-Host "  patches/" -ForegroundColor White
if (Test-Path $patchDir) {
    Get-ChildItem $patchDir | ForEach-Object {
        $size = [math]::Round($_.Length / 1KB, 1)
        Write-Host "    $($_.Name) ($size KB)" -ForegroundColor DarkGray
        $totalFiles++
    }
}

Write-Host "  ui/" -ForegroundColor White
Get-ChildItem $uiDir | ForEach-Object {
    $size = [math]::Round($_.Length / 1KB, 1)
    Write-Host "    $($_.Name) ($size KB)" -ForegroundColor DarkGray
    $totalFiles++
}

Write-Host ""
Write-Host "Total: $totalFiles files" -ForegroundColor Cyan
Write-Host ""
Write-Host "Next steps:" -ForegroundColor Yellow
Write-Host "  1. Review changes:  git diff" -ForegroundColor DarkGray
Write-Host "  2. Commit:          git add -A && git commit -m 'release: v$version'" -ForegroundColor DarkGray
Write-Host "  3. Tag:             git tag v$version" -ForegroundColor DarkGray
Write-Host "  4. Push:            git push origin main --tags" -ForegroundColor DarkGray
Write-Host "  5. GitHub release:  gh release create v$version --title 'v$version' --generate-notes" -ForegroundColor DarkGray
Write-Host ""

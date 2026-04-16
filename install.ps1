# GAMMA Multiplayer — Installer
# Right-click → Run with PowerShell, or: powershell -ExecutionPolicy Bypass -File install.ps1

$ErrorActionPreference = "Stop"
$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Definition

# --- Ask for Anomaly path ---
$anomalyDefault = "C:\ANOMALY"
$anomalyPath = Read-Host "Anomaly install folder [$anomalyDefault]"
if ([string]::IsNullOrWhiteSpace($anomalyPath)) { $anomalyPath = $anomalyDefault }

$hasAvx = Test-Path (Join-Path $anomalyPath "bin\AnomalyDX11AVX.exe")
$hasStd = Test-Path (Join-Path $anomalyPath "bin\AnomalyDX11.exe")
if (-not ($hasAvx -or $hasStd)) {
    Write-Host "ERROR: Cannot find AnomalyDX11.exe or AnomalyDX11AVX.exe in $anomalyPath\bin\" -ForegroundColor Red
    Write-Host "Make sure you pointed to the right Anomaly folder."
    pause; exit 1
}

# --- Ask for GAMMA path ---
$gammaDefault = "C:\GAMMA"
$gammaPath = Read-Host "GAMMA install folder [$gammaDefault]"
if ([string]::IsNullOrWhiteSpace($gammaPath)) { $gammaPath = $gammaDefault }

if (-not (Test-Path (Join-Path $gammaPath "overwrite"))) {
    Write-Host "ERROR: Cannot find 'overwrite' folder in $gammaPath" -ForegroundColor Red
    Write-Host "Make sure you pointed to the right GAMMA folder."
    pause; exit 1
}

Write-Host ""
Write-Host "Anomaly: $anomalyPath" -ForegroundColor Cyan
Write-Host "GAMMA:   $gammaPath" -ForegroundColor Cyan
Write-Host ""

# --- Backup stock AVX exe ---
$avxExe = Join-Path $anomalyPath "bin\AnomalyDX11AVX.exe"
$avxBackup = Join-Path $anomalyPath "bin\AnomalyDX11AVX_stock.exe"
if (Test-Path $avxExe) {
    if (-not (Test-Path $avxBackup)) {
        Write-Host "Backing up AnomalyDX11AVX.exe → AnomalyDX11AVX_stock.exe"
        Copy-Item $avxExe $avxBackup
    } else {
        Write-Host "Backup already exists, skipping."
    }
}

# --- Copy patched engine into AVX slot ---
Write-Host "Installing patched engine..."
Copy-Item (Join-Path $scriptDir "bin\AnomalyDX11.exe") $avxExe -Force

# --- Copy DLLs ---
Write-Host "Installing networking DLLs..."
$dlls = @("gns_bridge.dll", "GameNetworkingSockets.dll", "abseil_dll.dll", "libcrypto-3-x64.dll", "libprotobuf.dll")
foreach ($dll in $dlls) {
    Copy-Item (Join-Path $scriptDir "bin\$dll") (Join-Path $anomalyPath "bin\$dll") -Force
}

# --- Copy scripts ---
Write-Host "Installing scripts..."
$scriptsDir = Join-Path $gammaPath "overwrite\gamedata\scripts"
New-Item -ItemType Directory -Path $scriptsDir -Force | Out-Null
$scripts = @("mp_core.script", "mp_protocol.script", "mp_host_events.script", "mp_client_state.script", "mp_alife_guard.script", "mp_puppet.script", "mp_ui.script")
foreach ($s in $scripts) {
    Copy-Item (Join-Path $scriptDir "scripts\$s") (Join-Path $scriptsDir $s) -Force
}

# --- Copy mod patches (surge guards, etc.) ---
Write-Host "Installing mod patches..."
$patchDir = Join-Path $scriptDir "patches"
if (Test-Path $patchDir) {
    $patchFiles = Get-ChildItem $patchDir -Filter "*.script"
    foreach ($p in $patchFiles) {
        Copy-Item $p.FullName (Join-Path $scriptsDir $p.Name) -Force
        Write-Host "  [OK] $($p.Name) (mod patch)" -ForegroundColor Green
    }
} else {
    Write-Host "  No patches directory, skipping." -ForegroundColor Yellow
}

# --- Copy UI XML ---
Write-Host "Installing UI..."
$uiDir = Join-Path $gammaPath "overwrite\gamedata\configs\ui"
New-Item -ItemType Directory -Path $uiDir -Force | Out-Null
Copy-Item (Join-Path $scriptDir "ui\ui_mp_menu.xml") (Join-Path $uiDir "ui_mp_menu.xml") -Force

# --- Fix unjam mod keybind collision (R key opens MP menu without this) ---
Write-Host "Patching unjam mod keybind..."
$unjamScript = Join-Path $gammaPath "mods\G.A.M.M.A. Unjam Reload on the same key\gamedata\scripts\arti_jamming.script"
if (Test-Path $unjamScript) {
    $content = Get-Content $unjamScript -Raw
    if ($content -match 'bind wpn_reload kF10') {
        $content = $content -replace 'bind wpn_reload kF10', 'bind wpn_reload kRSHIFT'
        Set-Content $unjamScript $content -NoNewline
        Write-Host "  Patched: wpn_reload moved from F10 to RSHIFT (F10 is MP menu)" -ForegroundColor Green
    } else {
        Write-Host "  Already patched or mod updated, skipping." -ForegroundColor Yellow
    }
} else {
    Write-Host "  Unjam mod not found, skipping." -ForegroundColor Yellow
}

# --- Verify ---
Write-Host ""
Write-Host "=== Verification ===" -ForegroundColor Yellow

$allOk = $true

# Engine
$target = $avxExe
if (Test-Path $target) { Write-Host "  OK  $target" -ForegroundColor Green }
else { Write-Host "  FAIL  $target" -ForegroundColor Red; $allOk = $false }

# DLLs
foreach ($dll in $dlls) {
    $target = Join-Path $anomalyPath "bin\$dll"
    if (Test-Path $target) { Write-Host "  OK  $target" -ForegroundColor Green }
    else { Write-Host "  FAIL  $target" -ForegroundColor Red; $allOk = $false }
}

# Scripts
foreach ($s in $scripts) {
    $target = Join-Path $scriptsDir $s
    if (Test-Path $target) { Write-Host "  OK  $target" -ForegroundColor Green }
    else { Write-Host "  FAIL  $target" -ForegroundColor Red; $allOk = $false }
}

# Patches
if (Test-Path $patchDir) {
    foreach ($p in $patchFiles) {
        $target = Join-Path $scriptsDir $p.Name
        if (Test-Path $target) { Write-Host "  OK  $target" -ForegroundColor Green }
        else { Write-Host "  FAIL  $target" -ForegroundColor Red; $allOk = $false }
    }
}

# UI
$target = Join-Path $uiDir "ui_mp_menu.xml"
if (Test-Path $target) { Write-Host "  OK  $target" -ForegroundColor Green }
else { Write-Host "  FAIL  $target" -ForegroundColor Red; $allOk = $false }

Write-Host ""
if ($allOk) {
    Write-Host "Done. Launch GAMMA through MO2. Press F10 in-game to open the MP menu. Enter the host's IP and click Connect." -ForegroundColor Green
} else {
    Write-Host "Some files failed to install. Check the errors above." -ForegroundColor Red
}
pause

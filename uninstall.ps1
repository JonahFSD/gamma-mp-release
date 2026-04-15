# GAMMA Multiplayer — Uninstaller
# Right-click → Run with PowerShell, or: powershell -ExecutionPolicy Bypass -File uninstall.ps1

$ErrorActionPreference = "Stop"

# --- Ask for Anomaly path ---
$anomalyDefault = "C:\ANOMALY"
$anomalyPath = Read-Host "Anomaly install folder [$anomalyDefault]"
if ([string]::IsNullOrWhiteSpace($anomalyPath)) { $anomalyPath = $anomalyDefault }

# --- Ask for GAMMA path ---
$gammaDefault = "C:\GAMMA"
$gammaPath = Read-Host "GAMMA install folder [$gammaDefault]"
if ([string]::IsNullOrWhiteSpace($gammaPath)) { $gammaPath = $gammaDefault }

# --- Restore stock AVX exe ---
$avxExe = Join-Path $anomalyPath "bin\AnomalyDX11AVX.exe"
$avxBackup = Join-Path $anomalyPath "bin\AnomalyDX11AVX_stock.exe"
if (Test-Path $avxBackup) {
    Write-Host "Restoring stock AnomalyDX11AVX.exe..."
    Copy-Item $avxBackup $avxExe -Force
    Remove-Item $avxBackup
} else {
    Write-Host "No backup found at $avxBackup — skipping engine restore." -ForegroundColor Yellow
}

# --- Remove DLLs ---
Write-Host "Removing networking DLLs..."
$dlls = @("gns_bridge.dll", "GameNetworkingSockets.dll", "abseil_dll.dll", "libcrypto-3-x64.dll", "libprotobuf.dll")
foreach ($dll in $dlls) {
    $target = Join-Path $anomalyPath "bin\$dll"
    if (Test-Path $target) { Remove-Item $target }
}

# --- Remove scripts ---
Write-Host "Removing MP scripts..."
$scriptsDir = Join-Path $gammaPath "overwrite\gamedata\scripts"
$scripts = @("mp_core.script", "mp_protocol.script", "mp_host_events.script", "mp_client_state.script", "mp_alife_guard.script", "mp_ui.script")
foreach ($s in $scripts) {
    $target = Join-Path $scriptsDir $s
    if (Test-Path $target) { Remove-Item $target }
}

# --- Remove UI XML ---
Write-Host "Removing MP UI..."
$uiTarget = Join-Path $gammaPath "overwrite\gamedata\configs\ui\ui_mp_menu.xml"
if (Test-Path $uiTarget) { Remove-Item $uiTarget }

# --- Revert unjam mod keybind patch ---
Write-Host "Reverting unjam mod keybind..."
$unjamScript = Join-Path $gammaPath "mods\G.A.M.M.A. Unjam Reload on the same key\gamedata\scripts\arti_jamming.script"
if (Test-Path $unjamScript) {
    $content = Get-Content $unjamScript -Raw
    if ($content -match 'bind wpn_reload kRSHIFT') {
        $content = $content -replace 'bind wpn_reload kRSHIFT', 'bind wpn_reload kF10'
        Set-Content $unjamScript $content -NoNewline
        Write-Host "  Reverted: wpn_reload back to F10" -ForegroundColor Green
    } else {
        Write-Host "  Already stock, skipping." -ForegroundColor Yellow
    }
} else {
    Write-Host "  Unjam mod not found, skipping." -ForegroundColor Yellow
}

Write-Host ""
Write-Host "Reverted to stock GAMMA." -ForegroundColor Green
pause

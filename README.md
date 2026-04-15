# GAMMA Multiplayer

Co-op multiplayer mod for S.T.A.L.K.E.R. Anomaly GAMMA. Syncs player position, health, inventory, and A-Life state between players over LAN or internet using Valve GameNetworkingSockets.

## Requirements

- S.T.A.L.K.E.R. Anomaly 1.5.3
- GAMMA modpack installed and working

## Install

Right-click `install.ps1` → **Run with PowerShell**.

Or from a terminal:

```
powershell -ExecutionPolicy Bypass -File install.ps1
```

The installer will ask for your Anomaly and GAMMA folders, back up your stock engine, and copy everything into place.

## Play

1. Launch GAMMA through MO2 as usual.
2. Press **F10** in-game to open the MP menu.
3. Enter the host's IP address and click **Connect**.

## Uninstall

Right-click `uninstall.ps1` → **Run with PowerShell**. This restores your stock engine and removes all MP files.

## Host Setup

The host needs UDP+TCP port **44140** forwarded/open. Clients don't need any port configuration.

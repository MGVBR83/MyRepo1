# ==============================================================================
# 07-start-vm.ps1
#
# SECTION 7 — Start VM only if it was running before this deployment.
# vmWasRunning is read from deploy-state.json (set by 05-check-vm-state.ps1).
# If the VM was already stopped before this run, it is left stopped.
# ==============================================================================

[CmdletBinding()]
param (
    [Parameter(Mandatory = $true)]
    [string]$StateFilePath          # Path to deploy-state.json (read-only)
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

function Write-Section { param([string]$Title)
    Write-Host "`n============================================================" -ForegroundColor Cyan
    Write-Host "  $Title" -ForegroundColor Cyan
    Write-Host "============================================================" -ForegroundColor Cyan
}
function Write-Ok   { param([string]$Msg) Write-Host "[OK]   $Msg" -ForegroundColor Green }
function Write-Info { param([string]$Msg) Write-Host "[INFO] $Msg" -ForegroundColor Cyan }

Write-Section "SECTION 7 — Start VM"

# ── Load state ─────────────────────────────────────────────────────────────────
if (-not (Test-Path $StateFilePath)) {
    Write-Error "[ERROR] State file not found: $StateFilePath"; exit 1
}
$state = Get-Content $StateFilePath -Raw | ConvertFrom-Json

$resourceGroupName = $state.resourceGroupName
$vmName            = $state.vmName
$vmWasRunning      = [bool]$state.vmWasRunning

if ($vmWasRunning) {
    Write-Info "VM '$vmName' was running before this deployment — restarting..."

    $startOut = az vm start `
        --resource-group $resourceGroupName `
        --name           $vmName 2>&1

    if ($LASTEXITCODE -ne 0) {
        Write-Error "[ERROR] Failed to start VM '$vmName'. Details: $startOut"; exit 1
    }

    Write-Ok "VM '$vmName' started successfully."
}
else {
    Write-Info "VM '$vmName' was already stopped before this run — leaving in stopped state."
    Write-Info "Start the VM manually when ready."
}

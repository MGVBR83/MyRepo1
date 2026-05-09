# ==============================================================================
# 05-check-vm-state.ps1
#
# SECTION 5 — Check VM power state and stop if running.
# Writes vmWasRunning (bool) back to state so 07-start-vm.ps1
# knows whether to restart the VM after NIC attachment.
# ==============================================================================

[CmdletBinding()]
param (
    [Parameter(Mandatory = $true)]
    [string]$StateFilePath          # Path to deploy-state.json (read + update)
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

function Write-Section { param([string]$Title)
    Write-Host "`n============================================================" -ForegroundColor Cyan
    Write-Host "  $Title" -ForegroundColor Cyan
    Write-Host "============================================================" -ForegroundColor Cyan
}
function Write-Ok      { param([string]$Msg) Write-Host "[OK]   $Msg" -ForegroundColor Green }
function Write-Info    { param([string]$Msg) Write-Host "[INFO] $Msg" -ForegroundColor Cyan }

Write-Section "SECTION 5 — Check VM Power State"

# ── Load state ─────────────────────────────────────────────────────────────────
if (-not (Test-Path $StateFilePath)) {
    Write-Error "[ERROR] State file not found: $StateFilePath"; exit 1
}
$state = Get-Content $StateFilePath -Raw | ConvertFrom-Json

$resourceGroupName = $state.resourceGroupName
$vmName            = $state.vmName

Write-Info "Fetching instance view for VM '$vmName'..."

$vmStateJson = az vm get-instance-view `
    --resource-group $resourceGroupName `
    --name           $vmName `
    --output         json 2>&1

if ($LASTEXITCODE -ne 0) {
    Write-Error "[ERROR] Failed to get VM instance view. Details: $vmStateJson"; exit 1
}

$vmView    = $vmStateJson | ConvertFrom-Json
$powerCode = ($vmView.instanceView.statuses |
              Where-Object { $_.code -like "PowerState/*" }).code

Write-Info "Current VM power state: $powerCode"

$vmWasRunning = $false

switch ($powerCode) {
    "PowerState/running" {
        Write-Info "VM is running — stopping now (required before NIC attachment)..."
        $stopOut = az vm stop `
            --resource-group $resourceGroupName `
            --name           $vmName 2>&1
        if ($LASTEXITCODE -ne 0) {
            Write-Error "[ERROR] Failed to stop VM '$vmName'. Details: $stopOut"; exit 1
        }
        Write-Ok "VM '$vmName' stopped."
        $vmWasRunning = $true
    }
    { $_ -in @("PowerState/deallocated","PowerState/stopped") } {
        Write-Info "VM is already stopped/deallocated — no action needed."
        $vmWasRunning = $false
    }
    default {
        Write-Warning "Unexpected power state '$powerCode'. Proceeding anyway..."
        $vmWasRunning = $false
    }
}

# ── Persist vmWasRunning to state ──────────────────────────────────────────────
$state.vmWasRunning = $vmWasRunning
$state | ConvertTo-Json -Depth 5 | Set-Content -Path $StateFilePath -Encoding UTF8
Write-Ok "State updated: vmWasRunning = $vmWasRunning"

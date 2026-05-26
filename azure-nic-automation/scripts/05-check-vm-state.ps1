# ==============================================================================
# 05-check-vm-state.ps1
#
# SECTION 5 — Check VM power state and deallocate if needed.
# Writes vmWasRunning (bool) back to state so 07-start-vm.ps1
# knows whether to restart the VM after NIC attachment.
# ==============================================================================

[CmdletBinding()]
param (
    [Parameter(Mandatory = $true)]
    [string]$StateFilePath
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

function Get-VmPowerState {
    param(
        [Parameter(Mandatory = $true)][string]$ResourceGroupName,
        [Parameter(Mandatory = $true)][string]$VmName
    )

    $vmStateJson = az vm get-instance-view `
        --resource-group $ResourceGroupName `
        --name           $VmName `
        --output         json 2>&1

    if ($LASTEXITCODE -ne 0) {
        throw "Failed to get VM instance view. Details: $vmStateJson"
    }

    $vmView = $vmStateJson | ConvertFrom-Json
    return ($vmView.instanceView.statuses | Where-Object { $_.code -like "PowerState/*" } | Select-Object -First 1).code
}

Write-Section "SECTION 5 — Check VM Power State"

if (-not (Test-Path -LiteralPath $StateFilePath)) {
    Write-Error "[ERROR] State file not found: $StateFilePath"
    exit 1
}

$state = Get-Content -LiteralPath $StateFilePath -Raw | ConvertFrom-Json

$resourceGroupName = $state.resourceGroupName
$vmName            = $state.vmName

if ([string]::IsNullOrWhiteSpace($resourceGroupName)) {
    Write-Error "[ERROR] resourceGroupName is missing in state file."
    exit 1
}
if ([string]::IsNullOrWhiteSpace($vmName)) {
    Write-Error "[ERROR] vmName is missing in state file."
    exit 1
}

Write-Info "Fetching instance view for VM '$vmName'..."
$powerCode = Get-VmPowerState -ResourceGroupName $resourceGroupName -VmName $vmName
Write-Info "Current VM power state: $powerCode"

$vmWasRunning = $false

switch ($powerCode) {
    "PowerState/running" {
        Write-Info "VM is running — deallocating now (required before NIC attachment)..."

        $deallocateOut = az vm deallocate `
            --resource-group $resourceGroupName `
            --name           $vmName `
            --output         none 2>&1

        if ($LASTEXITCODE -ne 0) {
            Write-Error "[ERROR] Failed to deallocate VM '$vmName'. Details: $deallocateOut"
            exit 1
        }

        $vmWasRunning = $true
    }

    "PowerState/stopped" {
        Write-Info "VM is stopped but not deallocated — deallocating now (required before NIC attachment)..."

        $deallocateOut = az vm deallocate `
            --resource-group $resourceGroupName `
            --name           $vmName `
            --output         none 2>&1

        if ($LASTEXITCODE -ne 0) {
            Write-Error "[ERROR] Failed to deallocate VM '$vmName'. Details: $deallocateOut"
            exit 1
        }

        $vmWasRunning = $false
    }

    "PowerState/deallocated" {
        Write-Info "VM is already deallocated — no action needed."
        $vmWasRunning = $false
    }

    default {
        Write-Warning "Unexpected power state '$powerCode'. Attempting to deallocate before NIC attachment..."

        $deallocateOut = az vm deallocate `
            --resource-group $resourceGroupName `
            --name           $vmName `
            --output         none 2>&1

        if ($LASTEXITCODE -ne 0) {
            Write-Error "[ERROR] Failed to deallocate VM '$vmName' from state '$powerCode'. Details: $deallocateOut"
            exit 1
        }

        $vmWasRunning = $false
    }
}

Write-Info "Verifying VM reached deallocated state..."
$maxAttempts = 30
$attempt = 0

do {
    Start-Sleep -Seconds 10
    $attempt++
    $currentPowerCode = Get-VmPowerState -ResourceGroupName $resourceGroupName -VmName $vmName
    Write-Info "Current VM power state after deallocate attempt $attempt/$maxAttempts : $currentPowerCode"
} until ($currentPowerCode -eq "PowerState/deallocated" -or $attempt -ge $maxAttempts)

if ($currentPowerCode -ne "PowerState/deallocated") {
    Write-Error "[ERROR] VM '$vmName' did not reach 'PowerState/deallocated' in time. Current state: $currentPowerCode"
    exit 1
}

Write-Ok "VM '$vmName' is deallocated."

$state | Add-Member -NotePropertyName vmWasRunning -NotePropertyValue $vmWasRunning -Force
$state | ConvertTo-Json -Depth 10 | Set-Content -LiteralPath $StateFilePath -Encoding UTF8

Write-Ok "State updated: vmWasRunning = $vmWasRunning"

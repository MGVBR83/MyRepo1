# ==============================================================================
# 06-attach-nic.ps1
#
# SECTION 6 — Attach the new NIC to the target VM.
# VM must already be in a stopped/deallocated state.
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
function Write-Ok   { param([string]$Msg) Write-Host "[OK]   $Msg" -ForegroundColor Green }
function Write-Info { param([string]$Msg) Write-Host "[INFO] $Msg" -ForegroundColor Cyan }

Write-Section "SECTION 6 — Attach NIC to VM"

if (-not (Test-Path -LiteralPath $StateFilePath)) {
    Write-Error "[ERROR] State file not found: $StateFilePath"
    exit 1
}

$state = Get-Content -LiteralPath $StateFilePath -Raw | ConvertFrom-Json

$resourceGroupName = $state.resourceGroupName
$vmName            = $state.vmName
$newNicName        = $state.newNicName

if ([string]::IsNullOrWhiteSpace($resourceGroupName)) {
    Write-Error "[ERROR] resourceGroupName is missing in state file."
    exit 1
}
if ([string]::IsNullOrWhiteSpace($vmName)) {
    Write-Error "[ERROR] vmName is missing in state file."
    exit 1
}
if ([string]::IsNullOrWhiteSpace($newNicName)) {
    Write-Error "[ERROR] newNicName is missing in state file."
    exit 1
}

Write-Info "Attaching NIC '$newNicName' to VM '$vmName'..."

$attachOut = az vm nic add `
    --resource-group $resourceGroupName `
    --vm-name        $vmName `
    --nics           $newNicName `
    --output         json 2>&1

if ($LASTEXITCODE -ne 0) {
    Write-Error "[ERROR] Failed to attach NIC '$newNicName' to VM '$vmName'. Details: $attachOut"
    exit 1
}

Write-Ok "NIC '$newNicName' attached to VM '$vmName' successfully."

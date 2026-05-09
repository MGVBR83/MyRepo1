# ==============================================================================
# 03-create-nic.ps1
#
# SECTION 3 — Create NIC on Subnet 3 and attach to ASG.
# Reads deploy-state.json for the ASG ID and subnet info,
# creates the NIC, then writes the NIC ID back into state.
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
function Write-Ok   { param([string]$Msg) Write-Host "[OK]   $Msg" -ForegroundColor Green }
function Write-Info { param([string]$Msg) Write-Host "[INFO] $Msg" -ForegroundColor Cyan }

Write-Section "SECTION 3 — Create NIC on Subnet 3"

# ── Load state ─────────────────────────────────────────────────────────────────
if (-not (Test-Path $StateFilePath)) {
    Write-Error "[ERROR] State file not found: $StateFilePath"; exit 1
}
$state = Get-Content $StateFilePath -Raw | ConvertFrom-Json

$resourceGroupName = $state.resourceGroupName
$location          = $state.location
$newNicName        = $state.newNicName
$subnet3Id         = $state.subnet3Id
$asgId             = $state.asgId

if ([string]::IsNullOrWhiteSpace($asgId)) {
    Write-Error "[ERROR] ASG ID is missing from state. Did 02-create-asg.ps1 run successfully?"; exit 1
}

Write-Info "Creating NIC '$newNicName' on Subnet3, attaching to ASG '$($state.asgName)'..."

# ── Create NIC ─────────────────────────────────────────────────────────────────
$nicJson = az network nic create `
    --resource-group              $resourceGroupName `
    --name                        $newNicName `
    --location                    $location `
    --subnet                      $subnet3Id `
    --application-security-groups $asgId `
    --output                      json 2>&1

if ($LASTEXITCODE -ne 0) {
    Write-Error "[ERROR] Failed to create NIC '$newNicName'. Details: $nicJson"; exit 1
}

$nic   = $nicJson | ConvertFrom-Json
$nicId = $nic.NewNIC.id

if ([string]::IsNullOrWhiteSpace($nicId)) {
    # Fallback: some CLI versions nest differently
    $nicId = $nic.id
}

Write-Ok "NIC created. ID: $nicId"

# ── Persist NIC ID to state ────────────────────────────────────────────────────
$state.nicId = $nicId
$state | ConvertTo-Json -Depth 5 | Set-Content -Path $StateFilePath -Encoding UTF8
Write-Ok "State updated with NIC ID."

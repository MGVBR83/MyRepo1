# ==============================================================================
# 01-resolve-location.ps1
#
# SECTION 1 — Resolve Azure location from Resource Group.
# Reads config, resolves location if not specified, writes resolved values
# to a shared state file (deploy-state.json) for downstream scripts.
# ==============================================================================

[CmdletBinding()]
param (
    [Parameter(Mandatory = $true)]
    [string]$ConfigPath,            # Path to deploy-config.json

    [Parameter(Mandatory = $true)]
    [string]$VmSide,                # "A" or "B"

    [Parameter(Mandatory = $true)]
    [string]$VmName,                # Target VM name

    [Parameter(Mandatory = $true)]
    [string]$StateFilePath          # Path to write deploy-state.json
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

Write-Section "SECTION 1 — Resolve Location"

# ── Load config ────────────────────────────────────────────────────────────────
if (-not (Test-Path $ConfigPath)) {
    Write-Error "[ERROR] Config file not found: $ConfigPath"; exit 1
}
$config = Get-Content $ConfigPath -Raw | ConvertFrom-Json

$resourceGroupName = $config.resourceGroupName
$location          = $config.location

# ── Validate VM side ───────────────────────────────────────────────────────────
$vmSideUpper = $VmSide.ToUpper().Trim()
if ($vmSideUpper -notin @("A","B")) {
    Write-Error "[ERROR] VmSide must be 'A' or 'B'. Got: '$VmSide'"; exit 1
}

# ── Resolve location if not provided ──────────────────────────────────────────
if ([string]::IsNullOrWhiteSpace($location)) {
    Write-Info "Location not set in config — resolving from Resource Group '$resourceGroupName'..."
    $rgJson = az group show --name $resourceGroupName --output json 2>&1
    if ($LASTEXITCODE -ne 0) {
        Write-Error "[ERROR] Failed to fetch Resource Group. Details: $rgJson"; exit 1
    }
    $location = ($rgJson | ConvertFrom-Json).location
    Write-Ok "Location resolved: $location"
} else {
    Write-Ok "Location from config: $location"
}

# ── Write state file ───────────────────────────────────────────────────────────
$state = @{
    resourceGroupName = $resourceGroupName
    location          = $location
    vmSide            = $vmSideUpper
    vmName            = $VmName
    asgName           = $config.asgName
    newNicName        = $config.newNicName
    subnet1Id         = $config.subnet1Id
    subnet2Id         = $config.subnet2Id
    subnet3Id         = $config.subnet3Id
    subnet1NsgName    = $config.subnet1NsgName
    subnet2NsgName    = $config.subnet2NsgName
    subnet3NsgName    = $config.subnet3NsgName
    asgId             = ""       # populated by 02-create-asg.ps1
    nicId             = ""       # populated by 03-create-nic.ps1
    vmWasRunning      = $false   # populated by 05-check-vm-state.ps1
}

$state | ConvertTo-Json -Depth 5 | Set-Content -Path $StateFilePath -Encoding UTF8
Write-Ok "State written to: $StateFilePath"

Write-Host "`n  Resource Group : $resourceGroupName"
Write-Host "  Location       : $location"
Write-Host "  VM Side        : $vmSideUpper"
Write-Host "  VM Name        : $VmName"

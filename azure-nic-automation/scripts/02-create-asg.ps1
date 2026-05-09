# ==============================================================================
# 02-create-asg.ps1
#
# SECTION 2 — Create Application Security Group (ASG).
# Reads deploy-state.json, creates the ASG, then writes the ASG ID back
# into the state file so downstream scripts can reference it.
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

Write-Section "SECTION 2 — Create Application Security Group"

# ── Load state ─────────────────────────────────────────────────────────────────
if (-not (Test-Path $StateFilePath)) {
    Write-Error "[ERROR] State file not found: $StateFilePath"; exit 1
}
$state = Get-Content $StateFilePath -Raw | ConvertFrom-Json

$resourceGroupName = $state.resourceGroupName
$location          = $state.location
$asgName           = $state.asgName

Write-Info "Creating ASG '$asgName' in '$resourceGroupName' ($location)..."

# ── Create ASG ─────────────────────────────────────────────────────────────────
$asgJson = az network asg create `
    --resource-group $resourceGroupName `
    --name           $asgName `
    --location       $location `
    --output         json 2>&1

if ($LASTEXITCODE -ne 0) {
    Write-Error "[ERROR] Failed to create ASG '$asgName'. Details: $asgJson"; exit 1
}

$asg   = $asgJson | ConvertFrom-Json
$asgId = $asg.id

if ([string]::IsNullOrWhiteSpace($asgId)) {
    Write-Error "[ERROR] ASG was created but ID is null/empty."; exit 1
}

Write-Ok "ASG created. ID: $asgId"

# ── Persist ASG ID to state ────────────────────────────────────────────────────
$state.asgId = $asgId
$state | ConvertTo-Json -Depth 5 | Set-Content -Path $StateFilePath -Encoding UTF8
Write-Ok "State updated with ASG ID."

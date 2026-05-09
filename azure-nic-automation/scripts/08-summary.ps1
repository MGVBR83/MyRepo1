# ==============================================================================
# 08-summary.ps1
#
# SECTION 8 — Print full deployment summary from state + config.
# ==============================================================================

[CmdletBinding()]
param (
    [Parameter(Mandatory = $true)]
    [string]$ConfigPath,

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

Write-Section "SECTION 8 — Deployment Complete — Summary"

$config = Get-Content $ConfigPath    -Raw | ConvertFrom-Json
$state  = Get-Content $StateFilePath -Raw | ConvertFrom-Json

$vmFinalState = if ([bool]$state.vmWasRunning) { "Running (restarted)" } else { "Stopped (was already stopped)" }

Write-Host ""
Write-Host "  VM Side         : $($state.vmSide)-side ($($state.vmName))"
Write-Host "  Resource Group  : $($state.resourceGroupName)"
Write-Host "  Location        : $($state.location)"
Write-Host "  ASG Created     : $($state.asgName)"
Write-Host "  ASG ID          : $($state.asgId)"
Write-Host "  NIC Created     : $($state.newNicName)  (Subnet 3, attached to ASG)"
Write-Host "  NIC ID          : $($state.nicId)"
Write-Host "  NIC Attached to : $($state.vmName)"
Write-Host "  VM Final State  : $vmFinalState"

Write-Host "`n  NSG Rules Created:"

$nsgEntries = @(
    @{ Label = "Subnet 1"; NsgName = $state.subnet1NsgName },
    @{ Label = "Subnet 2"; NsgName = $state.subnet2NsgName },
    @{ Label = "Subnet 3"; NsgName = $state.subnet3NsgName }
)

foreach ($entry in $nsgEntries) {
    $nsgName  = $entry.NsgName
    $rulesRaw = $config.nsgRules.PSObject.Properties |
                Where-Object { $_.Name -eq $nsgName } |
                Select-Object -ExpandProperty Value

    $count = if ($rulesRaw) { $rulesRaw.Count } else { 0 }
    Write-Host "`n  [$($entry.Label) — $nsgName] ($count rule(s))"

    if ($count -eq 0) {
        Write-Host "    (no rules configured)"
        continue
    }
    foreach ($r in $rulesRaw) {
        Write-Host ("    + {0,-40} Pri:{1,-5} {2,-9} {3,-5} {4}" -f `
            $r.ruleName, $r.priority, $r.direction, $r.protocol, $r.access)
    }
}

Write-Host "`n============================================================`n" -ForegroundColor Cyan

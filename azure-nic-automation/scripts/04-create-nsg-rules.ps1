# ==============================================================================
# 04-create-nsg-rules.ps1
# SECTION 4 — Create NSG rules for all three subnets.
# ==============================================================================

[CmdletBinding()]
param (
    [Parameter(Mandatory = $true)]
    [string]$ConfigPath,            # Path to deploy-config.json

    [Parameter(Mandatory = $true)]
    [string]$StateFilePath          # Path to deploy-state.json (read-only)
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

# ── Prevent Git-Bash / MSYS from converting "*" and CIDR prefixes ─────────────
$env:MSYS_NO_PATHCONV   = 1
$env:MSYS2_ARG_CONV_EXCL = "*"

# ── Console helpers ────────────────────────────────────────────────────────────
function Write-Section { param([string]$Title)
    Write-Host "`n============================================================" -ForegroundColor Cyan
    Write-Host "  $Title" -ForegroundColor Cyan
    Write-Host "============================================================" -ForegroundColor Cyan
}
function Write-Ok   { param([string]$Msg) Write-Host "[OK]   $Msg" -ForegroundColor Green }
function Write-Info { param([string]$Msg) Write-Host "[INFO] $Msg" -ForegroundColor Cyan }
function Write-Step { param([int]$C, [int]$T, [string]$M)
    Write-Host "`n[STEP $C/$T] $M" -ForegroundColor Yellow
}

function Format-PortRange {
    param([object]$Ports)
    return @($Ports | ForEach-Object {
        $val = [string]$_
        if ($val -eq "*") { "'*'" } else { $val }
    })
}

function Format-AddressPrefix {
    param([object]$Prefixes)
    return @($Prefixes | ForEach-Object {
        $val = [string]$_
        if ($val -eq "*") { "'*'" } else { $val }
    })
}

Write-Section "SECTION 4 — Create NSG Rules"

# ── Load files ─────────────────────────────────────────────────────────────────
if (-not (Test-Path $ConfigPath))    { Write-Error "[ERROR] Config not found: $ConfigPath"; exit 1 }
if (-not (Test-Path $StateFilePath)) { Write-Error "[ERROR] State not found: $StateFilePath"; exit 1 }

$config = Get-Content $ConfigPath    -Raw | ConvertFrom-Json
$state  = Get-Content $StateFilePath -Raw | ConvertFrom-Json

$resourceGroupName = $config.nsgresourceGroupName
$asgId             = $state.asgId

if ([string]::IsNullOrWhiteSpace($asgId)) {
    Write-Error "[ERROR] ASG ID is missing from state. Did 02-create-asg.ps1 run?"; exit 1
}

# ── Helper: resolve ASG ID placeholder ────────────────────────────────────────
# In config, an empty string for sourceAsgId / destinationAsgId means
# "use the ASG created in this run" (equivalent to __USE_SCRIPT_ASG__).
function Resolve-AsgId {
    param([string]$Id)
    if ([string]::IsNullOrWhiteSpace($Id)) { return $asgId }
    return $Id
}

# ── Build ordered list of NSGs ─────────────────────────────────────────────────
$nsgEntries = @(
    @{ Label = "Subnet 1"; NsgName = $config.subnet1NsgName },
    @{ Label = "Subnet 2"; NsgName = $config.subnet2NsgName },
    @{ Label = "Subnet 3"; NsgName = $config.subnet3NsgName }
)
$totalRules = (
    $config.nsgRules.PSObject.Properties |
    ForEach-Object { $_.Value } |   # each Value is itself a rule array
    ForEach-Object { $_ } |         # flatten one level → individual rule objects
    Measure-Object
).Count

$stepNum = 0
Write-Info "Total NSG rules to create: $totalRules"

foreach ($entry in $nsgEntries) {

    $nsgName = $entry.NsgName
    Write-Host "`n  ── $($entry.Label) ($nsgName) ──" -ForegroundColor Cyan

    # Retrieve rules for this NSG from config; skip if none defined
    $rulesRaw = $config.nsgRules.PSObject.Properties |
                Where-Object { $_.Name -eq $nsgName } |
                Select-Object -ExpandProperty Value

    if (-not $rulesRaw -or $rulesRaw.Count -eq 0) {
        Write-Info "No rules defined for '$nsgName' in config — skipping."
        continue
    }

    foreach ($rule in $rulesRaw) {

        $stepNum++
        Write-Step $stepNum $totalRules "Creating rule '$($rule.ruleName)' on NSG '$nsgName'..."

        try {
            $srcPorts = Format-PortRange -Ports $rule.sourcePortRanges
            $dstPorts = Format-PortRange -Ports $rule.destinationPortRanges

            # ── Base az CLI arguments ──────────────────────────────────────────
            $azArgs = @(
                "network", "nsg", "rule", "create",
                "--resource-group", $resourceGroupName,
                "--nsg-name",       $nsgName,
                "--name",           $rule.ruleName,
                "--priority",       [string]$rule.priority,
                "--access",         $rule.access,
                "--direction",      $rule.direction,
                "--protocol",       $rule.protocol,
                "--source-port-ranges"
            )
            $azArgs += $srcPorts
            $azArgs += @("--destination-port-ranges")
            $azArgs += $dstPorts

            # ── Source: ASG or address prefix ─────────────────────────────────
            if ($rule.useAsgAsSource) {
                $srcId          = if ($rule.PSObject.Properties['sourceAsgId']) { $rule.sourceAsgId } else { "" }
                $resolvedSrcAsg = Resolve-AsgId -Id $srcId
                $azArgs        += @("--source-asgs", $resolvedSrcAsg)
                Write-Info "  Source ASG: $resolvedSrcAsg"
            } else {
                # FIX 2: Use Format-AddressPrefix to safely handle "*"
                $srcPrefixes = Format-AddressPrefix -Prefixes $rule.sourceAddressPrefixes
                $azArgs     += @("--source-address-prefixes")
                $azArgs     += $srcPrefixes
            }

            # ── Destination: ASG or address prefix ────────────────────────────
            if ($rule.useAsgAsDestination) {
                $dstId          = if ($rule.PSObject.Properties['destinationAsgId']) { $rule.destinationAsgId } else { "" }
                $resolvedDstAsg = Resolve-AsgId -Id $dstId
                $azArgs        += @("--destination-asgs", $resolvedDstAsg)
                Write-Info "  Destination ASG: $resolvedDstAsg"
            } else {
                # FIX 2: Use Format-AddressPrefix to safely handle "*"
                $dstPrefixes = Format-AddressPrefix -Prefixes $rule.destinationAddressPrefixes
                $azArgs     += @("--destination-address-prefixes")
                $azArgs     += $dstPrefixes
            }

            $azArgs  += @("--output", "json")
            $ruleJson = az @azArgs 2>&1

            if ($LASTEXITCODE -ne 0) { throw $ruleJson }

            $created = $ruleJson | ConvertFrom-Json
            Write-Ok "Rule '$($rule.ruleName)' created. ID: $($created.id)"
        }
        catch {
            Write-Error "[ERROR] Failed to create rule '$($rule.ruleName)' on '$nsgName'. Details: $_"
            exit 1
        }
    }
}

Write-Ok "All NSG rules created successfully."

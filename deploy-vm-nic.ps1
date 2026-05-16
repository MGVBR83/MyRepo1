# ==============================================================================
# deploy-vm-nic.ps1
#
# Workflow (one VM at a time â€” user picks A-side or B-side):
#   SECTION 0  â€” Collect ALL inputs interactively (fail fast before any Azure call)
#   SECTION 1  â€” Resolve location from Resource Group
#   SECTION 2  â€” Create ASG (for Subnet 3 NIC)
#   SECTION 3  â€” Create NIC on Subnet 3 and attach to ASG
#   SECTION 4  â€” Create NSG rules per subnet (Subnet1-NSG, Subnet2-NSG, Subnet3-NSG)
#   SECTION 5  â€” Check VM state â†’ Stop if running
#   SECTION 6  â€” Attach new NIC to VM
#   SECTION 7  â€” Start VM
#   SECTION 8  â€” Summary
# ==============================================================================

[CmdletBinding()]
param (
    [Parameter(Mandatory = $true)]
    [string]$ResourceGroupName,

    [Parameter(Mandatory = $true)]
    [string]$NSGResourceGroupName,

    [Parameter(Mandatory = $false)]
    [string]$Location = "",         # Leave empty to inherit from Resource Group

    # â”€â”€ Subnet IDs â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
    [Parameter(Mandatory = $true)]
    [string]$Subnet1Id,             # Existing A-side / B-side VM subnet

    [Parameter(Mandatory = $true)]
    [string]$Subnet2Id,             # Existing A-side / B-side VM subnet

    [Parameter(Mandatory = $true)]
    [string]$Subnet3Id,             # New NIC will be created here

    # â”€â”€ NSG names (one per subnet) â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
    [Parameter(Mandatory = $true)]
    [string]$Subnet1NsgName,        # NSG associated with Subnet 1

    [Parameter(Mandatory = $true)]
    [string]$Subnet2NsgName,        # NSG associated with Subnet 2

    [Parameter(Mandatory = $true)]
    [string]$Subnet3NsgName,        # NSG associated with Subnet 3

    # â”€â”€ New resources â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
    [Parameter(Mandatory = $true)]
    [string]$AsgName,               # ASG to create and attach to new NIC

    [Parameter(Mandatory = $true)]
    [string]$NewNicName             # NIC to create on Subnet 3
)

# ==============================================================================
# HELPER FUNCTIONS
# ==============================================================================
function Read-Input {
    param ([string]$Prompt, [string]$Default = "")
    if ($Default) {
        $value = Read-Host "$Prompt [$Default]"
        if ([string]::IsNullOrWhiteSpace($value)) { return $Default }
        return $value.Trim()
    }
    $value = Read-Host $Prompt
    return $value.Trim()
}

function Write-Section {
    param ([string]$Title)
    Write-Host "`n============================================================" -ForegroundColor Cyan
    Write-Host "  $Title" -ForegroundColor Cyan
    Write-Host "============================================================" -ForegroundColor Cyan
}

function Write-Step {
    param ([int]$Current, [int]$Total, [string]$Message)
    Write-Host "`n[STEP $Current/$Total] $Message" -ForegroundColor Yellow
}

function Write-Ok   { param([string]$Msg) Write-Host "[OK] $Msg" -ForegroundColor Green }
function Write-Info { param([string]$Msg) Write-Host "[INFO] $Msg" -ForegroundColor Cyan }

# ==============================================================================
# SECTION 0 â€” Collect ALL inputs interactively BEFORE any Azure calls
# ==============================================================================
Write-Section "Input Collection â€” Complete Before Deployment Starts"

# â”€â”€ 0a. VM Side selection â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
Write-Host "`n  Which VM side do you want to process?"
Write-Host "    [A] A-side VM"
Write-Host "    [B] B-side VM"
do {
    $vmSide = (Read-Host "  Enter A or B").ToUpper().Trim()
    if ($vmSide -notin @("A","B")) { Write-Warning "  Please enter A or B." }
} while ($vmSide -notin @("A","B"))

$vmName = Read-Input -Prompt "  Enter the $vmSide-side VM name"

# â”€â”€ 0b. NSG Rule collection â€” per subnet â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
$allSubnets = @(
    @{ Label = "Subnet 1"; NsgName = $Subnet1NsgName },
    @{ Label = "Subnet 2"; NsgName = $Subnet2NsgName },
    @{ Label = "Subnet 3"; NsgName = $Subnet3NsgName }
)

# $rulesByNsg is a hashtable keyed by NsgName â†’ array of rule hashtables
$rulesByNsg = @{}

foreach ($subnet in $allSubnets) {

    Write-Section "NSG Rules for $($subnet.Label) â€” NSG: $($subnet.NsgName)"

    do {
        $ruleCountInput = Read-Host "  How many NSG rules to create for $($subnet.Label)?"
        $ruleCount      = 0
        $validCount     = [int]::TryParse($ruleCountInput, [ref]$ruleCount) -and $ruleCount -ge 0
        if (-not $validCount) { Write-Warning "  Please enter 0 or a positive integer." }
    } while (-not $validCount)

    $rules = @()

    for ($i = 1; $i -le $ruleCount; $i++) {

        Write-Host "`n  -- $($subnet.Label) | Rule $i of $ruleCount --" -ForegroundColor Yellow

        $ruleName = Read-Input -Prompt "    Rule Name" -Default "$($subnet.NsgName)-Rule$i"

        do {
            $priorityInput = Read-Input -Prompt "    Priority (100â€“4096)" -Default (100 + ($i - 1) * 10).ToString()
            $priority      = 0
            $validP        = [int]::TryParse($priorityInput, [ref]$priority) -and $priority -ge 100 -and $priority -le 4096
            if (-not $validP) { Write-Warning "    Must be 100â€“4096." }
        } while (-not $validP)

        do {
            $access = (Read-Input -Prompt "    Access (Allow/Deny)" -Default "Allow").ToLower()
            if ($access -notin @("allow","deny")) { Write-Warning "    Enter Allow or Deny." }
        } while ($access -notin @("allow","deny"))
        $access = (Get-Culture).TextInfo.ToTitleCase($access)

        do {
            $direction = (Read-Input -Prompt "    Direction (Inbound/Outbound)" -Default "Inbound").ToLower()
            if ($direction -notin @("inbound","outbound")) { Write-Warning "    Enter Inbound or Outbound." }
        } while ($direction -notin @("inbound","outbound"))
        $direction = (Get-Culture).TextInfo.ToTitleCase($direction)

        do {
            $protocol = (Read-Input -Prompt "    Protocol (Tcp/Udp/Icmp/*)" -Default "Tcp").ToLower()
            if ($protocol -notin @("tcp","udp","icmp","*")) { Write-Warning "    Enter Tcp, Udp, Icmp, or *." }
        } while ($protocol -notin @("tcp","udp","icmp","*"))
        if ($protocol -ne "*") { $protocol = (Get-Culture).TextInfo.ToTitleCase($protocol) }

        $srcPortInput = Read-Input -Prompt "    Source Port Range(s) comma-separated (e.g. * or 80,443)" -Default "*"
        $srcPorts     = $srcPortInput -split "," | ForEach-Object {
            $val = $_.Trim()
            if ($val -eq "*") { "'*'"} else { $val }
        }

        $dstPortInput = Read-Input -Prompt "    Destination Port Range(s) comma-separated (e.g. 3343,135,49152-65535)" -Default "*"
        $dstPorts     = $dstPortInput -split "," | ForEach-Object {
            $val = $_.Trim()
            if ($val -eq "*") { "'*'"} else { $val }
        }
        # Source
        $useSrcAsg          = (Read-Input -Prompt "    Use ASG as Source? (yes/no)" -Default "yes").ToLower()
        $srcAsgIds          = @()
        $srcAddressPrefixes = @()
        if ($useSrcAsg -eq "yes") {
            $customSrc = Read-Input -Prompt "    Source ASG ID (blank = use '$AsgName' from this run)" -Default ""
            $srcAsgIds = if ([string]::IsNullOrWhiteSpace($customSrc)) { @("__USE_SCRIPT_ASG__") }
                         else { @($customSrc.Trim()) }
        }
        else {
            $srcPfxIn           = Read-Input -Prompt "    Source Address Prefix(es) comma-separated" -Default "*"
            $srcAddressPrefixes = $srcPfxIn -split "," | ForEach-Object { $_.Trim() }
        }

        # Destination
        $useDstAsg          = (Read-Input -Prompt "    Use ASG as Destination? (yes/no)" -Default "yes").ToLower()
        $dstAsgIds          = @()
        $dstAddressPrefixes = @()
        if ($useDstAsg -eq "yes") {
            $customDst = Read-Input -Prompt "    Destination ASG ID (blank = use '$AsgName' from this run)" -Default ""
            $dstAsgIds = if ([string]::IsNullOrWhiteSpace($customDst)) { @("__USE_SCRIPT_ASG__") }
                         else { @($customDst.Trim()) }
        }
        else {
            $dstPfxIn           = Read-Input -Prompt "    Destination Address Prefix(es) comma-separated" -Default "*"
            $dstAddressPrefixes = $dstPfxIn -split "," | ForEach-Object { $_.Trim() }
        }

        $rules += @{
            RuleName            = $ruleName
            Priority            = $priority
            Access              = $access
            Direction           = $direction
            Protocol            = $protocol
            SrcPorts            = $srcPorts
            DstPorts            = $dstPorts
            SrcAsgIds           = $srcAsgIds
            SrcAddressPrefixes  = $srcAddressPrefixes
            DstAsgIds           = $dstAsgIds
            DstAddressPrefixes  = $dstAddressPrefixes
        }
        Write-Host "    [SAVED] Rule '$ruleName' stored for $($subnet.NsgName)." -ForegroundColor Green
    }

    $rulesByNsg[$subnet.NsgName] = $rules
}

# â”€â”€ 0c. Pre-deployment summary & confirmation â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
Write-Section "Pre-Deployment Summary â€” Review Before Proceeding"

Write-Host "`n  VM Side         : $vmSide-side"
Write-Host "  VM Name         : $vmName"
Write-Host "  Resource Group  : $ResourceGroupName"
Write-Host "  New ASG         : $AsgName"
Write-Host "  New NIC (Sub3)  : $NewNicName"
Write-Host "`n  NSG Rules to be created:"

foreach ($subnet in $allSubnets) {
    $rules = $rulesByNsg[$subnet.NsgName]
    Write-Host "`n  [$($subnet.Label) â€” $($subnet.NsgName)] ($($rules.Count) rule(s))"
    if ($rules.Count -eq 0) {
        Write-Host "    (no rules)"
    }
    foreach ($r in $rules) {
        $srcDisplay = if ($r.SrcAsgIds.Count -gt 0) {
            ($r.SrcAsgIds | ForEach-Object { if ($_ -eq "__USE_SCRIPT_ASG__") { "$AsgName (this run)" } else { $_ } }) -join ", "
        } else { $r.SrcAddressPrefixes -join ", " }
        $dstDisplay = if ($r.DstAsgIds.Count -gt 0) {
            ($r.DstAsgIds | ForEach-Object { if ($_ -eq "__USE_SCRIPT_ASG__") { "$AsgName (this run)" } else { $_ } }) -join ", "
        } else { $r.DstAddressPrefixes -join ", " }

        Write-Host ("    + {0,-38} Pri:{1,-5} {2,-9} {3,-5} {4,-6} SrcPorts:{5}  DstPorts:{6}" -f `
            $r.RuleName, $r.Priority, $r.Direction, $r.Protocol, $r.Access,
            ($r.SrcPorts -join ","), ($r.DstPorts -join ","))
        Write-Host "      Src: $srcDisplay  â†’  Dst: $dstDisplay"
    }
}

Write-Host ""
$confirm = Read-Input -Prompt "Proceed with deployment? (yes/no)" -Default "yes"
if ($confirm.ToLower() -ne "yes") {
    Write-Host "`n[ABORTED] Deployment cancelled by user." -ForegroundColor Red
    exit 0
}

# ==============================================================================
# SECTION 1 â€” Resolve Location
# ==============================================================================
if (-not $Location) {
    try {
        Write-Info "Fetching location from Resource Group '$ResourceGroupName'..."
        $rgJson   = az group show --name $ResourceGroupName --output json 2>&1
        if ($LASTEXITCODE -ne 0) { throw $rgJson }
        $Location = ($rgJson | ConvertFrom-Json).location
        Write-Info "Location resolved to: $Location"
    }
    catch {
        Write-Error "[ERROR] Failed to resolve location. Details: $_"; exit 1
    }
}

# Calculate total steps: ASG + NIC + all rules across 3 NSGs + Stop(cond) + Attach + Start
$totalRules  = ($rulesByNsg.Values | ForEach-Object { $_.Count } | Measure-Object -Sum).Sum
$totalSteps  = 2 + $totalRules + 3     # ASG, NIC, rules, Stop, Attach, Start
$stepNum     = 0

# ==============================================================================
# SECTION 2 â€” Create ASG
# ==============================================================================
$stepNum++
Write-Step $stepNum $totalSteps "Creating Application Security Group '$AsgName'..."

try {
    $asgJson = az network asg create `
        --resource-group $ResourceGroupName `
        --name           $AsgName `
        --location       $Location `
        --output         json 2>&1

    if ($LASTEXITCODE -ne 0) { throw $asgJson }
    $asg   = $asgJson | ConvertFrom-Json
    $asgId = $asg.id
    if (-not $asgId) { throw "ASG ID was null or empty." }
    Write-Ok "ASG created.  ID: $asgId"
}
catch { Write-Error "[ERROR] Failed to create ASG '$AsgName'. Details: $_"; exit 1 }

# ==============================================================================
# SECTION 3 â€” Create NIC on Subnet 3 and attach to ASG
# ==============================================================================
$stepNum++
Write-Step $stepNum $totalSteps "Creating NIC '$NewNicName' on Subnet 3 and attaching to ASG '$AsgName'..."

try {
    $nicJson = az network nic create `
        --resource-group              $ResourceGroupName `
        --name                        $NewNicName `
        --location                    $Location `
        --subnet                      $Subnet3Id `
        --application-security-groups $asgId `
        --output                      json 2>&1

    if ($LASTEXITCODE -ne 0) { throw $nicJson }
    $nic   = $nicJson | ConvertFrom-Json
    $nicId = $nic.NewNIC.id
    Write-Ok "NIC created and attached to ASG.  NIC ID: $nicId"
}
catch { Write-Error "[ERROR] Failed to create NIC '$NewNicName'. Details: $_"; exit 1 }

# ==============================================================================
# SECTION 4 â€” Create NSG Rules per subnet (loop over all 3 NSGs)
# ==============================================================================
foreach ($subnet in $allSubnets) {

    $nsgName = $subnet.NsgName
    $rules   = $rulesByNsg[$nsgName]

    if ($rules.Count -eq 0) {
        Write-Info "No rules configured for $($subnet.Label) ($nsgName) â€” skipping."
        continue
    }

    Write-Host "`n  â”€â”€ $($subnet.Label) NSG Rules ($nsgName) â”€â”€" -ForegroundColor Cyan

    foreach ($rule in $rules) {

        $stepNum++
        Write-Step $stepNum $totalSteps "Creating NSG Rule '$($rule.RuleName)' on '$nsgName'..."

        try {
            # Resolve ASG placeholder
            $resolvedSrcAsgIds = $rule.SrcAsgIds | ForEach-Object {
                if ($_ -eq "__USE_SCRIPT_ASG__") { $asgId } else { $_ }
            }
            $resolvedDstAsgIds = $rule.DstAsgIds | ForEach-Object {
                if ($_ -eq "__USE_SCRIPT_ASG__") { $asgId } else { $_ }
            }

            # Build az args dynamically
            $azArgs = @(
                "network","nsg","rule","create",
                "--resource-group", $NSGResourceGroupName,
                "--nsg-name",       $nsgName,
                "--name",           $rule.RuleName,
                "--priority",       $rule.Priority,
                "--access",         $rule.Access,
                "--direction",      $rule.Direction,
                "--protocol",       $rule.Protocol,
                "--source-port-ranges"
            ) + $rule.SrcPorts + @("--destination-port-ranges") + $rule.DstPorts

            if ($resolvedSrcAsgIds.Count -gt 0) {
                $azArgs += @("--source-asgs") + $resolvedSrcAsgIds
            } elseif ($rule.SrcAddressPrefixes.Count -gt 0) {
                $azArgs += @("--source-address-prefixes") + $rule.SrcAddressPrefixes
            }

            if ($resolvedDstAsgIds.Count -gt 0) {
                $azArgs += @("--destination-asgs") + $resolvedDstAsgIds
            } elseif ($rule.DstAddressPrefixes.Count -gt 0) {
                $azArgs += @("--destination-address-prefixes") + $rule.DstAddressPrefixes
            }

            $azArgs  += @("--output","json")
            $ruleJson = az @azArgs 2>&1
            if ($LASTEXITCODE -ne 0) { throw $ruleJson }

            $createdRule = $ruleJson | ConvertFrom-Json
            Write-Ok "Rule '$($rule.RuleName)' created.  ID: $($createdRule.id)"
        }
        catch {
            Write-Error "[ERROR] Failed to create NSG Rule '$($rule.RuleName)' on '$nsgName'. Details: $_"
            exit 1
        }
    }
}

# ==============================================================================
# SECTION 5 â€” Check VM power state â†’ conditionally stop
# ==============================================================================
$stepNum++
Write-Step $stepNum $totalSteps "Checking power state of VM '$vmName'..."

try {
    $vmStateJson = az vm get-instance-view `
        --resource-group $ResourceGroupName `
        --name           $vmName `
        --output         json 2>&1

    if ($LASTEXITCODE -ne 0) { throw $vmStateJson }

    $vmView    = $vmStateJson | ConvertFrom-Json
    $powerCode = ($vmView.instanceView.statuses | Where-Object { $_.code -like "PowerState/*" }).code
    Write-Info "Current VM power state: $powerCode"

    if ($powerCode -eq "PowerState/running") {
        Write-Info "VM is running â€” stopping now..."
        $stopOut = az vm stop `
            --resource-group $ResourceGroupName `
            --name           $vmName 2>&1
        if ($LASTEXITCODE -ne 0) { throw $stopOut }
        Write-Ok "VM '$vmName' stopped successfully."
        $vmWasRunning = $true
        # Pause before attaching NIC to allow ASG/NSG changes to propagate
        Write-Info "Pausing for 120 seconds to allow resources to stabilize before attaching the NIC..."
        Start-Sleep -Seconds 120
        Write-Ok "Wait complete (120 seconds)."
    }
    elseif ($powerCode -eq "PowerState/deallocated" -or $powerCode -eq "PowerState/stopped") {
        Write-Info "VM is already stopped/deallocated â€” skipping Stop step."
        $vmWasRunning = $false
    }
    else {
        Write-Warning "Unexpected VM power state '$powerCode'. Attempting to proceed..."
        $vmWasRunning = $false
    }
}
catch { Write-Error "[ERROR] Failed to get/stop VM '$vmName'. Details: $_"; exit 1 }

# ==============================================================================
# SECTION 6 â€” Attach new NIC to VM
# ==============================================================================

$stepNum++
Write-Step $stepNum $totalSteps "Attaching NIC '$NewNicName' to VM '$vmName'..."

try {
    # 1. Get existing NICs on the VM
    $existingNics = az vm show `
        --resource-group $ResourceGroupName `
        --name           $vmName `
        --query          "networkProfile.networkInterfaces" `
        -o json | ConvertFrom-Json

    # 2. Ensure the first NIC is explicitly marked primary
    $primaryNicId = $existingNics[0].id
    $primaryNicName = $primaryNicId.Split("/")[-1]

    az network nic update `
        --resource-group $ResourceGroupName `
        --name           $primaryNicName `
        --output         none | Out-Null   # touch it so Azure refreshes the primary flag

    # 3. Now retry the original attach
    $attachOut = az vm nic add `
        --resource-group $ResourceGroupName `
        --vm-name        $vmName `
        --nics           $NewNicName `
        --output         json 2>&1

    if ($LASTEXITCODE -ne 0) { throw $attachOut }
    Write-Ok "NIC '$NewNicName' attached to VM '$vmName' successfully."
}
catch { Write-Error "[ERROR] Failed to attach NIC to VM '$vmName'. Details: $_"; exit 1 }

# ==============================================================================
# SECTION 7 â€” Start VM (only if it was running before, otherwise leave stopped)
# ==============================================================================
$stepNum++
if ($vmWasRunning) {
    Write-Step $stepNum $totalSteps "Starting VM '$vmName'..."
    try {
        $startOut = az vm start `
            --resource-group $ResourceGroupName `
            --name           $vmName 2>&1
        if ($LASTEXITCODE -ne 0) { throw $startOut }
        Write-Ok "VM '$vmName' started successfully."
    }
    catch { Write-Error "[ERROR] Failed to start VM '$vmName'. Details: $_"; exit 1 }
}
else {
    Write-Step $stepNum $totalSteps "VM '$vmName' was already stopped before this run â€” leaving in stopped state."
    Write-Info "Start the VM manually when ready."
}

# ==============================================================================
# SECTION 8 â€” Summary
# ==============================================================================
Write-Section "Deployment Complete â€” Summary"

Write-Host "  VM Side         : $vmSide-side ($vmName)"
Write-Host "  Resource Group  : $ResourceGroupName"
Write-Host "  Location        : $Location"
Write-Host "  ASG Created     : $AsgName"
Write-Host "  NIC Created     : $NewNicName  (Subnet 3, attached to ASG)"
Write-Host "  NIC Attached to : $vmName"
Write-Host "  VM Final State  : $(if ($vmWasRunning) { 'Running (restarted)' } else { 'Stopped (was already stopped)' })"
Write-Host "`n  NSG Rules Created:"
foreach ($subnet in $allSubnets) {
    $rules = $rulesByNsg[$subnet.NsgName]
    Write-Host "`n  [$($subnet.Label) â€” $($subnet.NsgName)] ($($rules.Count) rule(s))"
    foreach ($r in $rules) {
        Write-Host ("    + {0,-38} Pri:{1,-5} {2,-9} {3,-5} {4}" -f `
            $r.RuleName, $r.Priority, $r.Direction, $r.Protocol, $r.Access)
    }
}
Write-Host "`n============================================================`n" -ForegroundColor Cyan

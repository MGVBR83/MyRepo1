# Azure VM NIC Deployment — GitHub Actions Automation

Automates the full NIC attachment workflow (originally `deploy-vm-nic.ps1`) as a
**chained GitHub Actions pipeline**. Each section of the original script becomes a
discrete job with its own PowerShell script. NSG rules and all static config live
in a single JSON file — no interactive prompts needed.

---

## Repository Layout

```
.
├── .github/
│   └── workflows/
│       └── deploy-vm-nic.yml      # Main workflow — trigger this manually
├── config/
│   └── deploy-config.json         # ← Edit this for your environment
└── scripts/
    ├── 01-resolve-location.ps1
    ├── 02-create-asg.ps1
    ├── 03-create-nic.ps1
    ├── 04-create-nsg-rules.ps1
    ├── 05-check-vm-state.ps1
    ├── 06-attach-nic.ps1
    ├── 07-start-vm.ps1
    └── 08-summary.ps1
```

---

## Quick Start

### 1. Configure your environment

Edit **`config/deploy-config.json`**:

```json
{
  "resourceGroupName": "my-resource-group",
  "location": "",                          // leave empty to auto-resolve from RG
  "subnet1Id": "/subscriptions/.../subnets/subnet1",
  "subnet2Id": "/subscriptions/.../subnets/subnet2",
  "subnet3Id": "/subscriptions/.../subnets/subnet3",
  "subnet1NsgName": "subnet1-nsg",
  "subnet2NsgName": "subnet2-nsg",
  "subnet3NsgName": "subnet3-nsg",
  "asgName": "my-app-security-group",
  "newNicName": "my-new-nic",
  "nsgRules": {
    "subnet1-nsg": [ ... ],
    "subnet2-nsg": [ ... ],
    "subnet3-nsg": [ ... ]
  }
}
```

### 2. Add GitHub Secrets

Go to **Settings → Secrets and variables → Actions** and add:

| Secret name             | Value                                    |
|-------------------------|------------------------------------------|
| `AZURE_CLIENT_ID`       | Service principal / managed identity ID  |
| `AZURE_TENANT_ID`       | Azure AD tenant ID                       |
| `AZURE_SUBSCRIPTION_ID` | Target Azure subscription ID             |

> **Recommended:** Use [Workload Identity Federation (OIDC)](https://learn.microsoft.com/en-us/azure/developer/github/connect-from-azure) — no client secrets to rotate.  
> If you prefer a client secret, add `AZURE_CLIENT_SECRET` and update the `azure/login` step in the workflow.

### 3. Trigger the workflow

Go to **Actions → Deploy VM NIC → Run workflow** and fill in:

| Input         | Description                                  | Example          |
|---------------|----------------------------------------------|------------------|
| `vm_side`     | Which side to process                        | `A` or `B`       |
| `vm_name`     | Name of the target Azure VM                  | `vm-prod-a-001`  |
| `config_path` | Path to config file inside the repo (optional) | `config/deploy-config.json` |

---

## NSG Rules Config Reference

Each entry in `nsgRules` is keyed by **NSG name** and contains an array of rule objects.

```json
{
  "ruleName": "Allow-SSH-Inbound",
  "priority": 100,
  "access": "Allow",                    // "Allow" | "Deny"
  "direction": "Inbound",               // "Inbound" | "Outbound"
  "protocol": "Tcp",                    // "Tcp" | "Udp" | "Icmp" | "*"
  "sourcePortRanges": ["*"],
  "destinationPortRanges": ["22"],

  // Source — choose ONE mode:
  "useAsgAsSource": false,
  "sourceAddressPrefixes": ["10.0.0.0/8"],
  // OR:
  "useAsgAsSource": true,
  "sourceAsgId": ""                     // empty = use the ASG created in this run
                                        // or provide a full resource ID for an existing ASG

  // Destination — choose ONE mode:
  "useAsgAsDestination": true,
  "destinationAsgId": "",               // empty = use the ASG created in this run
  // OR:
  "useAsgAsDestination": false,
  "destinationAddressPrefixes": ["*"]
}
```

### ASG ID Resolution

Setting `sourceAsgId` or `destinationAsgId` to **`""`** (empty string) tells
`04-create-nsg-rules.ps1` to substitute the ID of the ASG created in step 02 of
the **same run**. Supply a full resource ID string to reference a *pre-existing* ASG instead.

---

## How State Is Shared Between Jobs

The workflow uses a GitHub Actions **artifact** (`deploy-state`) as a lightweight
key-value store:

```
Job 01 → writes  deploy-state.json  (location, names, IDs)
Job 02 → reads   deploy-state.json, writes asgId back
Job 03 → reads   deploy-state.json, writes nicId back
Job 04 → reads   deploy-state.json + config (NSG rules)
Job 05 → reads   deploy-state.json, writes vmWasRunning back
Job 06 → reads   deploy-state.json
Job 07 → reads   vmWasRunning — starts VM only if it was running before
Job 08 → reads   both files, prints full summary
```

Each job downloads the artifact at the start and uploads it again after
mutating the state, ensuring every downstream job sees the latest values.

---

## Extending / Customising

| Task | What to change |
|------|---------------|
| Add a new NSG rule | Add an entry to `config/deploy-config.json` under the relevant NSG key. No script changes needed. |
| Target a different config file | Pass a different `config_path` at workflow dispatch time. |
| Run only specific sections | Comment out the unwanted jobs and update the `needs:` chain. |
| Use a different runner OS | Change `runs-on: ubuntu-latest` to `windows-latest` if PowerShell 7+ is not installed in your org's runners. |
| Add approval gate before VM stop | Insert an `environment:` with a required reviewer on the `check-vm-state` job. |

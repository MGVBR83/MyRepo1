# terraform-azure-image-template

Terraform module (via the `azapi` provider) that creates one or more
`Microsoft.VirtualMachineImages/imageTemplates` (Azure Image Builder / VM
Image Templates, `2025-10-01` API), driven entirely from a YAML input file.

## Design

- **Root module** (`main.tf`) reads `images.yaml` (or whatever file you point
  `image_templates_file` at), and creates one `module "image_template"`
  instance per entry via `for_each`, keyed by `name`.
- **Child module** (`modules/image-template`) is a thin, direct mapping onto
  the AzAPI Terraform resource example for this resource type: `body.properties`
  is set straight from `var.properties`, with no locals reshaping it in
  between. Whatever object structure you put in the YAML's `properties` block
  is exactly what gets sent to Azure.

This means there's effectively no transformation logic to maintain: the YAML
`properties:` block uses the same camelCase keys as the ARM/AzAPI schema, so
adding a new field Azure ships next year is just a matter of adding it to the
YAML - no module code changes required.

```
terraform-azure-image-template/
├── main.tf                  # yamldecode + for_each over the child module
├── variables.tf              # image_templates_file
├── outputs.tf                # aggregated outputs across all images
├── versions.tf
├── images.yaml                # your input - one or more image definitions
└── modules/
    └── image-template/
        ├── main.tf            # the azapi_resource itself
        ├── variables.tf
        ├── outputs.tf
        └── versions.tf
```

## Usage

```bash
terraform init
terraform plan  -var="image_templates_file=./images.yaml"
terraform apply -var="image_templates_file=./images.yaml"
```

(`image_templates_file` defaults to `./images.yaml` next to the root module,
so you can usually omit the `-var`.)

## YAML shape

```yaml
image_templates:
  - name: <string>                    # ^[A-Za-z0-9-_.]{1,64}$
    resource_group_id: <string>       # full ARM resource group ID (parent_id)
    location: <string>
    identity:
      type: UserAssigned | None
      identity_ids: [<string>, ...]
    tags:                             # optional
      key: value
    properties:                       # -> body.properties, verbatim
      source: {...}                   # required, discriminated union
      distribute: [{...}, ...]        # required, at least one
      customize: [{...}, ...]         # optional
      buildTimeoutInMinutes: <int>    # optional
      autoRun: { state: Enabled|Disabled }
      errorHandling: { onCustomizerError: ..., onValidationError: ... }
      managedResourceTags: {...}
      optimize: { vmBoot: {...}, workload: {...} }
      stagingResourceGroup: <string>
      validate: { continueDistributeOnFailure: bool, sourceValidationOnly: bool, inVMValidations: [...] }
      vmProfile: { vmSize: ..., osDiskSizeGB: ..., userAssignedIdentities: [...], vnetConfig: {...} }
  - name: <second image>
    ...
```

Add as many entries under `image_templates` as you need - each becomes its
own `azapi_resource`. Names must be unique; a `check` block in the root
module fails the plan early if two entries collide (otherwise they'd silently
collapse into a single `for_each` key).

See `images.yaml` for two full worked examples (an Ubuntu image distributed
to a Compute Gallery across two regions, and a Windows image distributed as a
managed image).

## Shape reference for `properties`' discriminated-union fields

### `source` (required, one object)

| type                  | required keys                                                  |
| --------------------- | ---------------------------------------------------------------- |
| `ManagedImage`         | `imageId`                                                         |
| `PlatformImage`        | `publisher`, `offer`, `sku`, `version` (optional: `planInfo`)      |
| `SharedImageVersion`   | `imageVersionId`                                                  |

### `customize` (ordered list, each with `type` + `name`)

| type              | keys                                                                    |
| ----------------- | -------------------------------------------------------------------------- |
| `File`             | `sourceUri`, `destination`, `sha256Checksum`                               |
| `PowerShell`       | `inline` or `scriptUri`, `runElevated`, `runAsSystem`, `validExitCodes`     |
| `Shell`            | `inline` or `scriptUri`, `sha256Checksum`                                  |
| `WindowsRestart`   | `restartCommand`, `restartCheckCommand`, `restartTimeout`                  |
| `WindowsUpdate`    | `filters`, `searchCriteria`, `updateLimit`                                 |

### `distribute` (required, at least one, each needs `runOutputName`)

| type            | required keys       | notes                                                              |
| --------------- | ---------------------- | ---------------------------------------------------------------------- |
| `ManagedImage`   | `imageId`, `location`   |                                                                          |
| `SharedImage`    | `galleryImageId`         | plus `targetRegions`, `versioning` (`{ scheme: Latest\|Source }`), `replicationMode` |
| `VHD`            | —                       | optional `uri`                                                          |

### `validate.inVMValidations` (optional list)

Same shapes as `File` / `PowerShell` / `Shell` customizers above.

## Outputs

| Name                      | Description                                                        |
| --------------------------- | ---------------------------------------------------------------------- |
| `image_template_ids`         | Map of image name → resource ID                                        |
| `image_template_outputs`      | Map of image name → full ARM response body (incl. `lastRunStatus`)      |

## Notes

- The identity you assign needs `Contributor` on the staging/build resources
  it touches, plus read access to the source image and write access to the
  distribution target (managed image RG, Compute Gallery, or storage account
  for VHD).
- Creating/updating the resource doesn't trigger a build by itself unless
  `properties.autoRun.state` is `Enabled`. Otherwise trigger the `Run` action
  separately (e.g. `az image builder run` or an `azapi_resource_action`).
- Since `properties` is untyped (`any`) by design, a typo in a key name (e.g.
  `imageID` instead of `imageId`) won't be caught at plan time - it'll surface
  as an ARM validation error on `apply`. Cross-check field names against the
  table above or the [ARM schema reference](https://learn.microsoft.com/en-us/azure/templates/microsoft.virtualmachineimages/imagetemplates?pivots=deployment-language-terraform)
  when in doubt.

# Linode Instance Disk (Protected) Terraform Module

The protected variant of [`../linode_instance_disk`](../linode_instance_disk).
Its inputs, outputs, and resource are the base module's. The only difference
is a `lifecycle` block on the disk, which does two things:

- **`prevent_destroy = true`.** Terraform refuses any plan that would
  destroy or replace the disk, and fails with
  `Error: Instance cannot be destroyed`.
- **`ignore_changes` on the deploy-time attributes.** A later change to the
  image, the bootstrap SSH keys, the root password, or the StackScript plans
  no change instead of a replacement.

Use it for the boot disk of an **image-less** Linode: one whose disks and
configuration profile are their own resources, as on Linode Interfaces with
a GRUB 2 profile. There the server's data lives on this resource rather than
on the instance, so
[`../linode_instance_protected`](../linode_instance_protected) on the
instance does not protect it. A disk replaced under a running instance takes
everything on it with it, while the instance survives. Editing `image` to the
next Ubuntu LTS, for example, would otherwise plan exactly that.

## Usage

```hcl
module "boot_disk" {
  source = "github.com/Harleypig-LLC/linode-foundation-fabric//modules/linode_instance_disk_protected?ref=v2.5.0"

  linode_id        = module.instance.instance_id
  label            = "web-1-boot"
  size             = 50688
  image            = "linode/ubuntu26.04"
  authorized_users = ["alice"]
}
```

The inputs and outputs are the base module's; see
[`../linode_instance_disk`](../linode_instance_disk).

## What is ignored, and why

Each attribute in the table is used once, when the disk is deployed. Each is
`RequiresReplace` in the `linode/linode` provider
(`linode/instancedisk/framework_resource_schema.go`, read at v4.10.0).
Changing it on an existing disk is never applied in place; the provider's
only answer is a new disk.

| Attribute | Why it only matters at deploy |
|-----------|-------------------------------|
| `image` | the source the disk is deployed from |
| `authorized_keys` | written to root's `authorized_keys` at deploy |
| `authorized_users` | the same, from those users' Linode profile keys |
| `root_pass` | the initial root password |
| `stackscript_id`, `stackscript_data` | the StackScript runs once, at deploy |

So the configuration can drift from the disk on these attributes, and that
is intended: the configuration describes how to deploy a **new** disk.
Rotating keys or the root password on a running server is the
configuration-management layer's job, against the host.

**Deliberately not ignored:**

- `label` and `size`: updated in place, with no replacement. **A `size`
  change is not harmless.** The provider shuts a running Linode down for
  the resize and boots it again afterwards (`runDiskOperation` in
  `linode/instancedisk/helper.go`, v4.10.0), so the apply takes the server
  offline. With `skip_implicit_reboots` set in the provider, the apply fails
  instead. A shrink cannot go below the space the disk's files take up:
  *"it cannot be made smaller than what is required by the total size of
  the files current on the Disk"* (Linode API, *Resize a disk*, read
  2026-11-20). Below that, the resize fails at apply rather than at plan.
- `filesystem` and `linode_id`: `RequiresReplace` and read back, so ignoring
  either would leave the configuration claiming a disk that is not there. A
  change fails the plan on `prevent_destroy` instead.

## Switching an existing disk to this module

The resource address inside the module is `linode_instance_disk.this`, the
same as the base module. With the same module name, change only `source` and
run `terraform init`; the state address is unchanged. With a new name, add a
`moved` block from the old address to the new one. Either way, confirm with
`terraform plan` that the result has **0 to destroy** before applying.

## Rebuilding on purpose

`prevent_destroy` cannot be switched off from a variable. So a deliberate
redeploy routes the disk through the base module for one apply:

1. Change `source` to `linode_instance_disk` (same ref), and run
   `terraform init`.
2. Run `terraform plan`. Every ignored attribute that has drifted shows
   again, with `# forces replacement`. Read it; this is the redeploy, and it
   erases the disk.
3. Apply it.
4. Change `source` back, run `terraform init`, and confirm `terraform plan`
   shows **0 to destroy**.

`terraform apply -replace=…`, `terraform destroy`, and a changed
`filesystem` are refused with `Error: Instance cannot be destroyed`. Deleting
the module call, a `removed` block with `destroy = true`, or changing
`source` to a copy without this `lifecycle` block all remove the guard, as for
[`../linode_instance_protected`](../linode_instance_protected) (its *What
removes the guard*). A Linode lock (`../linode_lock`) on the instance is the
guard that holds against every path.

## Checking the guard

`tests/protected.tftest.hcl` proves the ignored attributes keep their state
value and that `size` and `label` still plan. The mock provider does not model
`RequiresReplace`, so it cannot reach a replacement or `prevent_destroy`. To
see those, without touching an account, use the real provider against a
hand-written state, with `-refresh=false` so it reads no resource:

1. In a scratch directory, write a root module calling this module and the
   base module with the same inputs. Write a `terraform.tfstate` holding one
   `linode_instance_disk` at each module's address, matching the inputs.
   Timestamps must be RFC 3339 (`…Z`). `authorized_keys` and
   `stackscript_data` must be `[]` and `{}`, the modules' defaults, or the
   base module plans a replacement on them.
2. `terraform init`, then
   `LINODE_TOKEN=placeholder terraform plan -refresh=false`. That should show
   no destroy.
3. With `-var` changing `image`: only the **base** module's disk
   `must be replaced`; the protected one plans no replacement.
4. With `-var` changing `filesystem`: the plan fails with
   `Error: Instance cannot be destroyed`, against the protected disk.

Run on 2026-11-20 with Terraform 1.15.9 and `linode/linode` v4.10.0, both
results were as described.

<!-- BEGIN_TF_DOCS -->
<!-- markdownlint-capture -->
<!-- markdownlint-disable -->
## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 1.11 |
| <a name="requirement_linode"></a> [linode](#requirement\_linode) | ~> 4 |

## Providers

| Name | Version |
|------|---------|
| <a name="provider_linode"></a> [linode](#provider\_linode) | ~> 4 |

## Modules

No modules.

## Resources

| Name | Type |
|------|------|
| [linode_instance_disk.this](https://registry.terraform.io/providers/linode/linode/latest/docs/resources/instance_disk) | resource |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_label"></a> [label](#input\_label) | The Disk's label for display purposes only. | `string` | n/a | yes |
| <a name="input_linode_id"></a> [linode\_id](#input\_linode\_id) | The ID of the Linode to create this Disk under. | `number` | n/a | yes |
| <a name="input_size"></a> [size](#input\_size) | The size of the Disk in MB. | `number` | n/a | yes |
| <a name="input_authorized_keys"></a> [authorized\_keys](#input\_authorized\_keys) | A list of public SSH keys that will be automatically appended to the root user's ~/.ssh/authorized\_keys file when deploying from an Image. | `list(string)` | `[]` | no |
| <a name="input_authorized_users"></a> [authorized\_users](#input\_authorized\_users) | A list of usernames. If the usernames have associated SSH keys, the keys will be appended to the root user's ~/.ssh/authorized\_keys file. | `list(string)` | `[]` | no |
| <a name="input_filesystem"></a> [filesystem](#input\_filesystem) | The filesystem of this disk. (raw, swap, ext3, ext4, initrd) | `string` | `"ext4"` | no |
| <a name="input_image"></a> [image](#input\_image) | An Image ID to deploy the Linode Disk from. | `string` | `null` | no |
| <a name="input_root_pass"></a> [root\_pass](#input\_root\_pass) | The root user's password on a newly-created Linode Disk when deploying from an Image. | `string` | `null` | no |
| <a name="input_stackscript_data"></a> [stackscript\_data](#input\_stackscript\_data) | An object containing responses to any User Defined Fields present in the StackScript being deployed to this Disk. | `map(any)` | `{}` | no |
| <a name="input_stackscript_id"></a> [stackscript\_id](#input\_stackscript\_id) | A StackScript ID that will cause the referenced StackScript to be run during deployment of this Disk. | `number` | `null` | no |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_created"></a> [created](#output\_created) | When this disk was created. |
| <a name="output_disk_encryption"></a> [disk\_encryption](#output\_disk\_encryption) | The disk encryption policy for this disk's parent instance. |
| <a name="output_id"></a> [id](#output\_id) | The ID of the disk, as a config profile's device disk\_id expects it. |
| <a name="output_status"></a> [status](#output\_status) | A brief description of this Disk's current state. |
| <a name="output_updated"></a> [updated](#output\_updated) | When this disk was last updated. |
<!-- markdownlint-restore -->
<!-- END_TF_DOCS -->

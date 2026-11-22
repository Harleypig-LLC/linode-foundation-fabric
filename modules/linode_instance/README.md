# Linode Instance Terraform Module

This module creates and manages one Linode instance, wrapping the
`linode_instance` resource.

It has no `lifecycle` guard. A change to a create-time attribute such as
cloud-init `user_data` or `authorized_keys` replaces the instance, and a
module call cannot add `prevent_destroy` or `ignore_changes`. For a server
that must not be rebuilt by accident, use
[`../linode_instance_protected`](../linode_instance_protected).

## Create-time reserved IPv4 (`ipv4`)

`ipv4` passes the provider's `linode_instance.ipv4` argument through: "A set
of reserved IPv4 addresses to assign to this Linode on creation", with the
provider's note that "IP reservation is not currently available to all
users". Leave it unset (the default, `null`) and the argument is omitted, so
Linode assigns the instance's address exactly as before.

```hcl
module "reserved_ip" {
  source = "github.com/Harleypig-LLC/linode-foundation-fabric//modules/linode_reserved_ip_protected?ref=v2.2.0"

  region = "us-east"
}

module "instance" {
  source = "github.com/Harleypig-LLC/linode-foundation-fabric//modules/linode_instance?ref=v2.2.0"

  region = "us-east"
  type   = "g6-nanode-1"
  image  = "linode/ubuntu24.04"
  ipv4   = [module.reserved_ip.address]
}
```

The address must already be reserved, in the instance's region.

### What is known

- **Changing it forces replacement.** The provider schema marks `ipv4`
  `ForceNew`. That includes setting it on an instance that already exists:
  the plan replaces the instance. Set it when the instance is created, or
  accept the replacement.
- **The plan compares it against every IPv4 address on the instance.** On
  read, the provider fills `ipv4` with all of the instance's IPv4 addresses.
  If the instance holds any address you did not list (a private address from
  `private_ip = true`, or one added later), the set differs from your
  configuration and every plan proposes replacing the instance. List exactly
  the addresses the instance holds, or leave `ipv4` unset.
- **Unset is a no-op.** The argument is `Optional` and `Computed`, so an
  unset `ipv4` never produces a diff, on new or existing instances. The
  module sends an empty set (`ipv4 = []`) as unset too: passed to the
  provider as-is, `[]` reads as a change and replaces an existing instance.

### What is not known

- **Whether the reserved address replaces the auto-assigned one or is added
  beside it.** Linode's published API reference (OpenAPI 4.215.0) does not
  document `ipv4` on instance creation. The provider's own acceptance test
  (`TestAccResourceInstance_withReservedIP`, v4.7.0) creates an instance with
  one reserved address and asserts `ipv4` holds exactly one address, which
  points to **replaces**. That is the provider's test, not a documented API
  contract, and this library has not observed it on a real account. After
  the first apply, check that the instance has only the addresses you
  listed. If Linode also assigns its own address, the next plan proposes a
  replacement (see above).
- **Whether the address stays reserved when the instance is destroyed.** The
  provider's acceptance test `TestAccResourceInstance_deleteWithReservedIP`
  asserts that it does. Protect the reservation itself with
  `linode_reserved_ip_protected` regardless.

The `instance_ip_address` output is the first element of `ipv4`. With one
reserved address and no other IPv4, that is the reserved address.

## Linode Interfaces (`interface_generation`, `network_helper`)

`interface_generation` picks the interface model the instance is created on:
`"linode"` for Linode Interfaces, `"legacy_config"` for configuration profile
interfaces. Unset (the default, `null`), the argument is omitted and the
account's `interfaces_for_new_linodes` setting decides. `network_helper` sets
Network Helper at creation; the API applies it to Linodes on Linode
Interfaces only, and unset leaves it to the account's `network_helper`
setting.

Both are `ForceNew` in the provider (`linode/instance/schema_resource.go`,
v4.10.0). Setting `interface_generation` on an instance that already exists
replaces it, so it cannot move a running server onto Linode Interfaces; that
upgrade is a Linode API call outside Terraform, and cannot be undone.

On Linode Interfaces:

- **The public interface is its own resource.** Use
  [`../linode_interface`](../linode_interface). The provider also accepts
  interfaces inline on `linode_instance` (`linode_interfaces`), but that
  block conflicts with an explicit disk and config and is all `ForceNew`;
  this module does not expose it.
- **The firewall goes on the interface, not the instance.** The API
  reserves the instance's `firewall_id` for legacy configuration profile
  interfaces, and refuses a `linode` firewall device for a Linode on Linode
  Interfaces. Pass `firewall_id` to `linode_interface`, which creates the
  interface with the firewall attached. This module
  refuses `firewall_id` at plan time when `interface_generation = "linode"`.
  It cannot see the account default, so leaving `interface_generation`
  unset skips that check.
- **A GRUB 2 profile means an image-less instance.** The boot disk and the
  config profile are then their own resources
  ([`../linode_instance_disk`](../linode_instance_disk),
  [`../linode_instance_config`](../linode_instance_config)), and the profile
  sets `kernel = "linode/grub2"` and takes `interface_generation` from
  this module's `interface_generation` output, which reports what the API
  created even when the input was left to the account default.

[`examples/linode_interfaces`](examples/linode_interfaces/main.tf) composes
the whole shape: firewall, instance, public interface, boot disk and GRUB 2
profile. The tests plan it.

### Known provider issues

- [linode/terraform-provider-linode#2457][p2457] (open): an update to a
  `linode_instance` on Linode Interfaces, such as a label or alert change,
  fails with `[helpers.network] Option cannot be set on a Linode that is
  configured to use Linode Interfaces`. The reports are on instances whose
  config is managed by `linode_instance` itself, and the maintainers could
  not reproduce it with a simple config. Whether it reaches an instance
  whose profile is its own `linode_instance_config` is not known: after the
  first apply, plan a trivial instance change and check.
- [linode/terraform-provider-linode#2358][p2358] (open): configuration
  profile `interface` blocks do not work on Linode Interfaces. Declare
  interfaces with `linode_interface`; `linode_instance_config` refuses an
  `interface` entry when `interface_generation = "linode"`.

[p2457]: https://github.com/linode/terraform-provider-linode/issues/2457
[p2358]: https://github.com/linode/terraform-provider-linode/issues/2358

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
| [linode_instance.instance](https://registry.terraform.io/providers/linode/linode/latest/docs/resources/instance) | resource |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_region"></a> [region](#input\_region) | The location where the Linode is deployed. | `string` | n/a | yes |
| <a name="input_type"></a> [type](#input\_type) | The Linode type defines the pricing, CPU, disk, and RAM specs of the instance. | `string` | n/a | yes |
| <a name="input_alerts"></a> [alerts](#input\_alerts) | The alerts configuration for the Linode instance. | <pre>object({<br/>    cpu            = optional(number)<br/>    network_in     = optional(number)<br/>    network_out    = optional(number)<br/>    transfer_quota = optional(number)<br/>    io             = optional(number)<br/>  })</pre> | `null` | no |
| <a name="input_authorized_keys"></a> [authorized\_keys](#input\_authorized\_keys) | A list of SSH public keys to deploy for the root user. | `list(string)` | `[]` | no |
| <a name="input_authorized_users"></a> [authorized\_users](#input\_authorized\_users) | A list of Linode usernames. If the usernames have associated SSH keys, the keys will be appended to the root user's ~/.ssh/authorized\_keys file automatically. | `list(string)` | `[]` | no |
| <a name="input_backup_id"></a> [backup\_id](#input\_backup\_id) | A Backup ID from another Linode's available backups. | `string` | `null` | no |
| <a name="input_backups_enabled"></a> [backups\_enabled](#input\_backups\_enabled) | If true, the created Linode will automatically be enrolled in the Linode Backup service. | `bool` | `false` | no |
| <a name="input_booted"></a> [booted](#input\_booted) | If true, then the instance is kept or converted into a running state. | `bool` | `true` | no |
| <a name="input_disk_encryption"></a> [disk\_encryption](#input\_disk\_encryption) | The disk encryption policy for this instance. | `string` | `"enabled"` | no |
| <a name="input_firewall_id"></a> [firewall\_id](#input\_firewall\_id) | The ID of the Firewall to attach to the instance upon creation. | `string` | `null` | no |
| <a name="input_image"></a> [image](#input\_image) | An Image ID to deploy the Disk from. | `string` | `null` | no |
| <a name="input_interface_generation"></a> [interface\_generation](#input\_interface\_generation) | The interface model the Linode is created on: linode (Linode Interfaces) or legacy\_config (configuration profile interfaces). Null (the default) omits the argument and the account's interfaces\_for\_new\_linodes setting decides. Changing it forces replacement; see the README. | `string` | `null` | no |
| <a name="input_ipv4"></a> [ipv4](#input\_ipv4) | Reserved IPv4 addresses to assign to the Linode at creation. Null (the default) or an empty set omits the argument and Linode assigns an address as before. Changing it forces replacement; see the README. | `set(string)` | `null` | no |
| <a name="input_label"></a> [label](#input\_label) | The Linode's label for display purposes. | `string` | `null` | no |
| <a name="input_metadata"></a> [metadata](#input\_metadata) | The metadata configuration for the Linode instance. | <pre>object({<br/>    user_data = string<br/>  })</pre> | `null` | no |
| <a name="input_migration_type"></a> [migration\_type](#input\_migration\_type) | The type of migration to use when updating the type or region of a Linode. | `string` | `"cold"` | no |
| <a name="input_network_helper"></a> [network\_helper](#input\_network\_helper) | Whether Network Helper is enabled for the Linode, set at creation. Applies to Linodes on Linode Interfaces only. Null (the default) omits the argument and the account's network\_helper setting decides. Changing it forces replacement; see the README. | `bool` | `null` | no |
| <a name="input_placement_group_externally_managed"></a> [placement\_group\_externally\_managed](#input\_placement\_group\_externally\_managed) | If true, changes to the Linode's assigned Placement Group will be ignored. | `bool` | `false` | no |
| <a name="input_placement_group_id"></a> [placement\_group\_id](#input\_placement\_group\_id) | The ID of the Placement Group to assign this Linode to. | `string` | `null` | no |
| <a name="input_private_ip"></a> [private\_ip](#input\_private\_ip) | If true, the created Linode will have private networking enabled. | `bool` | `false` | no |
| <a name="input_resize_disk"></a> [resize\_disk](#input\_resize\_disk) | If true, changes in Linode type will attempt to upsize or downsize implicitly created disks. Null (the default) omits the field so it does not trip the provider's RequiredWith(image) constraint on image-less instances. | `bool` | `null` | no |
| <a name="input_root_pass"></a> [root\_pass](#input\_root\_pass) | The initial password for the root user account. | `string` | `null` | no |
| <a name="input_shared_ipv4"></a> [shared\_ipv4](#input\_shared\_ipv4) | A set of IPv4 addresses to be shared with the Instance. | `list(string)` | `[]` | no |
| <a name="input_stackscript_data"></a> [stackscript\_data](#input\_stackscript\_data) | An object containing responses to any User Defined Fields present in the StackScript being deployed to this Linode. Null (the default) omits the field; an empty map still trips the provider's RequiredWith(image) constraint, forcing image on every instance. | `map(any)` | `null` | no |
| <a name="input_stackscript_id"></a> [stackscript\_id](#input\_stackscript\_id) | The StackScript to deploy to the newly created Linode. | `string` | `null` | no |
| <a name="input_swap_size"></a> [swap\_size](#input\_swap\_size) | The swap disk size for the newly-created Linode. Null (the default) lets the provider apply its own default (512MB) when deploying from an image, and omits the field otherwise so it does not trip the provider's RequiredWith(image) constraint. | `number` | `null` | no |
| <a name="input_tags"></a> [tags](#input\_tags) | A list of tags applied to this object. | `list(string)` | `[]` | no |
| <a name="input_timeouts"></a> [timeouts](#input\_timeouts) | The timeouts configuration for the Linode instance. | <pre>object({<br/>    create = optional(string)<br/>    update = optional(string)<br/>    delete = optional(string)<br/>  })</pre> | `null` | no |
| <a name="input_watchdog_enabled"></a> [watchdog\_enabled](#input\_watchdog\_enabled) | The watchdog, named Lassie, is a Shutdown Watchdog that monitors your Linode. | `bool` | `false` | no |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_instance_id"></a> [instance\_id](#output\_instance\_id) | The ID of the Linode instance. |
| <a name="output_instance_ip_address"></a> [instance\_ip\_address](#output\_instance\_ip\_address) | The public IP address of the Linode instance. |
| <a name="output_instance_private_ip_address"></a> [instance\_private\_ip\_address](#output\_instance\_private\_ip\_address) | The private IP address of the Linode instance, if enabled. |
| <a name="output_instance_status"></a> [instance\_status](#output\_instance\_status) | The status of the Linode instance. |
| <a name="output_interface_generation"></a> [interface\_generation](#output\_interface\_generation) | The interface model the Linode runs on (linode or legacy\_config), as the API reports it. Pass it to linode\_instance\_config's interface\_generation, so a Linode the account put on Linode Interfaces by default is still treated as one. |
<!-- markdownlint-restore -->
<!-- END_TF_DOCS -->

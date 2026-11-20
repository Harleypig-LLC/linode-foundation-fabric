# Linode Instance Config Terraform Module

This module manages one configuration profile on a Linode, wrapping the
`linode_instance_config` resource.

## A GRUB 2 profile on Linode Interfaces

```hcl
module "boot_config" {
  source = "github.com/Harleypig-LLC/linode-foundation-fabric//modules/linode_instance_config?ref=v2.4.0"

  # The interface must exist before the profile boots the Linode.
  depends_on = [module.public_interface]

  linode_id            = module.instance.instance_id
  label                = "boot"
  kernel               = "linode/grub2"
  interface_generation = "linode"
  devices              = [{ device_name = "sda", disk_id = module.boot_disk.id }]
}
```

`kernel = "linode/grub2"` boots the distribution's own kernel from the
primary disk, per the API's kernel list. Pass the Linode's own
`interface_generation`; with `"linode"` the module changes two things:

- **`helpers.network` defaults to `false`.** The API documents the
  `network` helper as applying to legacy configuration profile interfaces
  only, and refuses it set to `true` on a Linode on Linode Interfaces
  (provider issue [#2457][p2457]). Leave `helpers` empty, as above, and no
  helpers block is sent at all, which is the provider's own documented
  Linode Interfaces example. Set any helper and the provider sends all five
  as booleans, so the module sends `network = false`. `helpers.network =
  true` is refused at plan time.
- **No `interface` entries.** A Linode on Linode Interfaces takes no
  configuration profile interfaces (provider issue [#2358][p2358]);
  declare them with `../linode_interface`. An entry is refused at plan time.

**Not verified:** that the API accepts an explicit `network = false` on a
Linode on Linode Interfaces. Its schema marks the field nullable and
inapplicable there, and the reported failures all sent `true`. If an apply
fails on `helpers.network`, drop the `helpers` input so no block is sent.

Unset (`null`) or `"legacy_config"`, nothing changes: an omitted helper
defaults to `true`, as before.

See [`../linode_instance`](../linode_instance) *Linode Interfaces* for the
whole composition.

[p2457]: https://github.com/linode/terraform-provider-linode/issues/2457
[p2358]: https://github.com/linode/terraform-provider-linode/issues/2358

<!-- BEGIN_TF_DOCS -->
<!-- markdownlint-capture -->
<!-- markdownlint-disable -->
## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 1.7 |
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
| [linode_instance_config.this](https://registry.terraform.io/providers/linode/linode/latest/docs/resources/instance_config) | resource |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_label"></a> [label](#input\_label) | The Config’s label for display purposes only. | `string` | n/a | yes |
| <a name="input_linode_id"></a> [linode\_id](#input\_linode\_id) | The ID of the Linode to create this configuration profile under. | `number` | n/a | yes |
| <a name="input_booted"></a> [booted](#input\_booted) | If true, the Linode will be booted into this config. | `bool` | `true` | no |
| <a name="input_comments"></a> [comments](#input\_comments) | Optional field for arbitrary User comments on this Config. | `string` | `null` | no |
| <a name="input_devices"></a> [devices](#input\_devices) | A list of device configurations for the Linode instance. | <pre>list(object({<br/>    device_name = string<br/>    disk_id     = optional(number)<br/>    volume_id   = optional(number)<br/>  }))</pre> | `[]` | no |
| <a name="input_helpers"></a> [helpers](#input\_helpers) | Helpers enabled when booting to this Linode Config. An empty map (the default) omits the block. When any helper is set, an omitted one defaults to true, except network on a Linode on Linode Interfaces (see interface\_generation). | `map(bool)` | `{}` | no |
| <a name="input_interface"></a> [interface](#input\_interface) | An array of Network Interfaces to use for this Configuration Profile. | <pre>list(object({<br/>    purpose      = string<br/>    ipam_address = optional(string)<br/>    label        = optional(string)<br/>    subnet_id    = optional(string)<br/>    primary      = optional(bool)<br/>    ipv4 = optional(object({<br/>      vpc     = optional(string)<br/>      nat_1_1 = optional(string)<br/>    }))<br/>  }))</pre> | `[]` | no |
| <a name="input_interface_generation"></a> [interface\_generation](#input\_interface\_generation) | The interface model of the Linode this profile belongs to: linode (Linode Interfaces) or legacy\_config. Pass the Linode's own value. With linode, an omitted helpers.network defaults to false rather than true, and helpers.network = true and any interface entry are refused. Null (the default) behaves as legacy\_config. | `string` | `null` | no |
| <a name="input_kernel"></a> [kernel](#input\_kernel) | A Kernel ID to boot a Linode with. Default is linode/latest-64bit. | `string` | `"linode/latest-64bit"` | no |
| <a name="input_memory_limit"></a> [memory\_limit](#input\_memory\_limit) | The memory limit of the Config. Defaults to the total ram of the Linode. | `number` | `null` | no |
| <a name="input_root_device"></a> [root\_device](#input\_root\_device) | The root device to boot. (default /dev/sda) | `string` | `"/dev/sda"` | no |
| <a name="input_run_level"></a> [run\_level](#input\_run\_level) | Defines the state of your Linode after booting. (default, single, binbash) | `string` | `"default"` | no |
| <a name="input_virt_mode"></a> [virt\_mode](#input\_virt\_mode) | Controls the virtualization mode. (paravirt, fullvirt) | `string` | `null` | no |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_id"></a> [id](#output\_id) | The unique ID of this Instance Config. |
<!-- markdownlint-restore -->
<!-- END_TF_DOCS -->

# Linode Interface Terraform Module

This module manages a single `linode_interface` — a network interface attached
to a Linode instance. An interface is exactly one of three kinds: `public`,
`vlan`, or `vpc`; supply the matching block and leave the others null.

## Usage

```hcl
module "interface" {
  source = "github.com/Harleypig-LLC/linode-foundation-fabric//modules/linode_interface?ref=vX.Y.Z"

  linode_id   = 12345
  firewall_id = module.firewall.id

  # A public interface with auto-assigned IPv4/IPv6 addresses.
  public = {}
}
```

<!-- BEGIN_TF_DOCS -->
<!-- markdownlint-capture -->
<!-- markdownlint-disable -->
## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 1.9 |
| <a name="requirement_linode"></a> [linode](#requirement\_linode) | ~> 4.10 |

## Providers

| Name | Version |
|------|---------|
| <a name="provider_linode"></a> [linode](#provider\_linode) | ~> 4.10 |

## Modules

No modules.

## Resources

| Name | Type |
|------|------|
| [linode_interface.this](https://registry.terraform.io/providers/linode/linode/latest/docs/resources/interface) | resource |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_linode_id"></a> [linode\_id](#input\_linode\_id) | The ID of the Linode to assign this interface to. | `number` | n/a | yes |
| <a name="input_default_route"></a> [default\_route](#input\_default\_route) | Indicates if the interface serves as the default route when multiple interfaces are eligible for this role. | <pre>object({<br/>    ipv4 = optional(bool)<br/>    ipv6 = optional(bool)<br/>  })</pre> | `null` | no |
| <a name="input_firewall_id"></a> [firewall\_id](#input\_firewall\_id) | ID of an enabled firewall to secure a VPC or public interface, attached when the interface is created. Required for a public or VPC interface; not allowed for VLAN interfaces. | `number` | `null` | no |
| <a name="input_public"></a> [public](#input\_public) | Linode public interface. Mutually exclusive with vlan and vpc. Pass an empty object ({}) for a public interface with auto-assigned addresses. | <pre>object({<br/>    ipv4 = optional(object({<br/>      addresses = optional(list(object({<br/>        address = optional(string)<br/>        primary = optional(bool)<br/>      })))<br/>    }))<br/>    ipv6 = optional(object({<br/>      ranges = optional(list(object({<br/>        range = string<br/>      })))<br/>    }))<br/>  })</pre> | `null` | no |
| <a name="input_vlan"></a> [vlan](#input\_vlan) | Linode VLAN interface. Mutually exclusive with public and vpc. | <pre>object({<br/>    vlan_label   = string<br/>    ipam_address = optional(string)<br/>  })</pre> | `null` | no |
| <a name="input_vpc"></a> [vpc](#input\_vpc) | Linode VPC interface. Mutually exclusive with public and vlan. | <pre>object({<br/>    subnet_id = number<br/>    ipv4 = optional(object({<br/>      addresses = optional(list(object({<br/>        address         = optional(string)<br/>        nat_1_1_address = optional(string)<br/>        primary         = optional(bool)<br/>      })))<br/>      ranges = optional(list(object({<br/>        range = string<br/>      })))<br/>    }))<br/>    ipv6 = optional(object({<br/>      is_public = optional(bool)<br/>      ranges = optional(list(object({<br/>        range = optional(string)<br/>      })))<br/>      slaac = optional(list(object({<br/>        range = optional(string)<br/>      })))<br/>    }))<br/>  })</pre> | `null` | no |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_default_route"></a> [default\_route](#output\_default\_route) | Whether the interface serves as the IPv4 and/or IPv6 default route. |
| <a name="output_firewall_id"></a> [firewall\_id](#output\_firewall\_id) | ID of the firewall the interface was created with (null for a VLAN interface). |
| <a name="output_id"></a> [id](#output\_id) | The unique ID for this interface. |
| <a name="output_linode_id"></a> [linode\_id](#output\_linode\_id) | The ID of the Linode this interface is assigned to. |
| <a name="output_public"></a> [public](#output\_public) | The resolved public interface configuration, including assigned addresses. |
| <a name="output_vlan"></a> [vlan](#output\_vlan) | The resolved VLAN interface configuration. |
| <a name="output_vpc"></a> [vpc](#output\_vpc) | The resolved VPC interface configuration, including assigned addresses and ranges. |
<!-- markdownlint-restore -->
<!-- END_TF_DOCS -->

## Notes

- `public`, `vlan`, and `vpc` are mutually exclusive — set exactly one. The
  Linode API rejects an interface that specifies more than one kind.
- A `public` or `vpc` interface must be created with a `firewall_id`; the
  module refuses one without. Unset, the Linode API falls back to the
  account's default firewall for that interface type, and refuses the create
  when there is none. The API's `-1` opt-out is refused too. `firewall_id` is
  refused on a `vlan` interface.
- **This module does not use the account default firewall.** A default set
  with [`linode_firewall_settings`](../linode_firewall_settings) still
  applies to interfaces created some other way, but an interface built here
  always names its firewall, so its protection is visible in the
  configuration that creates it.
- The provider replaces the interface when `firewall_id` changes, so moving a
  public interface to a different firewall recreates it. Changing the
  firewall's rules, policies or label does not change its ID.
- Leave the interface out of `linode_firewall`'s `interfaces` (null by
  default): that module then reads the attachment back without managing
  it, and listing it there too would be a dependency cycle.
- Pass `public = {}` for a public interface with auto-assigned addresses; the
  provider computes the resulting `ipv4`/`ipv6` assignments (surfaced via the
  `public` output).
- Computed results such as assigned addresses and ranges are exposed as
  outputs (`public`, `vpc`, `default_route`); they are not inputs.

## Upgrading from v2.x

v3.0.0 requires `firewall_id` on every public and VPC interface. **Adding
it to an interface that already exists replaces that interface**: the
provider marks `firewall_id` as forcing replacement and never reads it back
from the API, so it plans a destroy and create even when the interface
already carries that firewall through the account default or through
`linode_firewall`'s `interfaces`. The new interface's addresses can differ
from the old one's unless they are reserved.

So, for an interface created under v2.x without `firewall_id`, either:

- **replace it deliberately**: add `firewall_id`, then plan the
  replacement by name, `terraform plan -replace=<address> -out=<file>`, and
  apply that saved plan, so the replacement is the one you reviewed. Expect
  the public addresses to change unless they are reserved, and update
  anything that points at them; or
- **stay on v2.x** for that configuration until a replacement is
  acceptable.

An interface that was attached through `linode_firewall`'s `interfaces`
should also come out of that list once it carries `firewall_id`, or the two
form a dependency cycle.

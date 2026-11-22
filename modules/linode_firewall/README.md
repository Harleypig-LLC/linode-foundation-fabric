# Linode Firewall Terraform Module

This module creates and manages a Linode Cloud Firewall: inbound/outbound
rules, default policies, and optional attachment to Linodes, NodeBalancers
and Linode Interfaces. It follows the repo's Cloud Foundation Fabric style
(single-resource, validated inputs, plan-only tests).

The default policies are **least-privilege**: `inbound_policy = "DROP"` (deny
inbound unless a rule allows it) and `outbound_policy = "ACCEPT"`.

## Usage

```hcl
module "web_firewall" {
  source = "github.com/Harleypig-LLC/linode-foundation-fabric//modules/linode_firewall?ref=v2.0.0"

  label   = "harleypig-com-web"
  linodes = [12345] # the instance(s) to govern

  inbound = [
    {
      label    = "allow-https"
      action   = "ACCEPT"
      protocol = "TCP"
      ports    = "443"
      ipv4     = ["0.0.0.0/0"]
      ipv6     = ["::/0"]
    },
    {
      label    = "allow-http"
      action   = "ACCEPT"
      protocol = "TCP"
      ports    = "80"
      ipv4     = ["0.0.0.0/0"]
      ipv6     = ["::/0"]
    },
  ]

  # inbound_policy defaults to DROP; outbound_policy defaults to ACCEPT.
  tags = ["web", "production"]
}
```

An empty `inbound` with the default `inbound_policy = "DROP"` blocks all
inbound traffic — add one rule per class of traffic you want to allow.

## Linodes on Linode Interfaces

A Linode on Linode Interfaces is governed through its interfaces: the API
refuses a `linode` device for it. Attach the firewall when the interface is
created, through `linode_interface`'s `firewall_id`, and leave `interfaces`
unset here:

```hcl
module "web_firewall" {
  source = "github.com/Harleypig-LLC/linode-foundation-fabric//modules/linode_firewall?ref=vX.Y.Z"

  label   = "web-public"
  inbound = [] # rules as above
}

module "public_interface" {
  source = "github.com/Harleypig-LLC/linode-foundation-fabric//modules/linode_interface?ref=vX.Y.Z"

  linode_id   = module.instance.instance_id
  firewall_id = module.web_firewall.id
  public      = {}
}
```

This is the order the API needs. An interface created without a
`firewall_id` gets the account's default firewall for its type, and the
create fails when the account has none, so a firewall attached afterwards
through `interfaces` never gets the chance. `linode_interface` therefore
requires `firewall_id`, and does not rely on an account default set with
[`linode_firewall_settings`](../linode_firewall_settings).

`interfaces` is only for interfaces made outside this library. Listing an
interface made by `linode_interface` there as well is a dependency cycle.

Public and VPC interfaces only; a VLAN interface takes no firewall.

## Device lists: null versus `[]`

`linodes`, `nodebalancers` and `interfaces` default to null. The provider
reads every attached device back into these attributes, so:

- **null** leaves the attachments unmanaged. Whatever is attached, through an
  interface's own `firewall_id` or a `linode_firewall_device`, is read back
  into the matching output and the plan changes nothing.
- **a list, `[]` included,** is enforced exactly. Anything attached that is
  not in it is detached on the next apply.

### Upgrading from v2.x

In v2.x all three defaulted to `[]`, so a firewall with none of them set
detached every device it found. A caller that relied on that to keep a
firewall free of attachments must now pass `[]` explicitly for each list it
wants enforced. A caller that sets the lists sees no change.

<!-- BEGIN_TF_DOCS -->
<!-- markdownlint-capture -->
<!-- markdownlint-disable -->
## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 1.11 |
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
| [linode_firewall.this](https://registry.terraform.io/providers/linode/linode/latest/docs/resources/firewall) | resource |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_label"></a> [label](#input\_label) | This Firewall's unique label. | `string` | n/a | yes |
| <a name="input_disabled"></a> [disabled](#input\_disabled) | If true, the Firewall's rules are not enforced. | `bool` | `false` | no |
| <a name="input_inbound"></a> [inbound](#input\_inbound) | Inbound firewall rules. With the default inbound\_policy of DROP, an empty list blocks all inbound traffic; add one rule per class of traffic to allow. | <pre>list(object({<br/>    label    = string<br/>    action   = string<br/>    protocol = string<br/>    ports    = optional(string)<br/>    ipv4     = optional(list(string))<br/>    ipv6     = optional(list(string))<br/>  }))</pre> | `[]` | no |
| <a name="input_inbound_policy"></a> [inbound\_policy](#input\_inbound\_policy) | Default behavior for inbound traffic not matched by a rule. Defaults to DROP for a least-privilege posture. | `string` | `"DROP"` | no |
| <a name="input_interfaces"></a> [interfaces](#input\_interfaces) | IDs of Linode Interfaces made outside this library that this Firewall governs. An interface made by linode\_interface attaches through its own firewall\_id; leave this null for it. null leaves attachments unmanaged (read back, not changed); a list, [] included, is enforced exactly. Public and VPC interfaces only. | `list(number)` | `null` | no |
| <a name="input_linodes"></a> [linodes](#input\_linodes) | IDs of Linodes this Firewall governs network traffic for. null leaves attachments unmanaged (read back, not changed); a list, [] included, is enforced exactly. | `list(number)` | `null` | no |
| <a name="input_nodebalancers"></a> [nodebalancers](#input\_nodebalancers) | IDs of NodeBalancers this Firewall governs network traffic for. null leaves attachments unmanaged (read back, not changed); a list, [] included, is enforced exactly. | `list(number)` | `null` | no |
| <a name="input_outbound"></a> [outbound](#input\_outbound) | Outbound firewall rules. With the default outbound\_policy of ACCEPT, an empty list permits all outbound traffic; add rules only to constrain it. | <pre>list(object({<br/>    label    = string<br/>    action   = string<br/>    protocol = string<br/>    ports    = optional(string)<br/>    ipv4     = optional(list(string))<br/>    ipv6     = optional(list(string))<br/>  }))</pre> | `[]` | no |
| <a name="input_outbound_policy"></a> [outbound\_policy](#input\_outbound\_policy) | Default behavior for outbound traffic not matched by a rule. | `string` | `"ACCEPT"` | no |
| <a name="input_tags"></a> [tags](#input\_tags) | An array of tags applied to this object. | `list(string)` | `[]` | no |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_devices"></a> [devices](#output\_devices) | The devices (Linodes, NodeBalancers, Linode Interfaces) governed by the Firewall. |
| <a name="output_disabled"></a> [disabled](#output\_disabled) | Whether the Firewall's rules are currently not enforced. |
| <a name="output_id"></a> [id](#output\_id) | The unique ID of this Firewall. |
| <a name="output_inbound_policy"></a> [inbound\_policy](#output\_inbound\_policy) | The default behavior for inbound traffic. |
| <a name="output_interfaces"></a> [interfaces](#output\_interfaces) | IDs of Linode Interfaces this Firewall governs. |
| <a name="output_label"></a> [label](#output\_label) | This Firewall's unique label. |
| <a name="output_linodes"></a> [linodes](#output\_linodes) | IDs of Linodes this Firewall governs. |
| <a name="output_nodebalancers"></a> [nodebalancers](#output\_nodebalancers) | IDs of NodeBalancers this Firewall governs. |
| <a name="output_outbound_policy"></a> [outbound\_policy](#output\_outbound\_policy) | The default behavior for outbound traffic. |
| <a name="output_status"></a> [status](#output\_status) | The status of the Firewall (e.g. enabled, disabled). |
| <a name="output_tags"></a> [tags](#output\_tags) | An array of tags applied to this object. |
<!-- markdownlint-restore -->
<!-- END_TF_DOCS -->

## Notes

- The reference tables above are generated by `terraform-docs` (run
  `bin/build-docs`); edit the inputs/outputs in the `.tf` files, not here.
- Each rule's `protocol` is one of `TCP`, `UDP`, `ICMP`; `ICMP` rules must not
  specify `ports` (the Linode API rejects them — the module validates this).
- A firewall governs devices via the inline `linodes` / `nodebalancers` /
  `interfaces` attributes, each null by default (see *Device lists*). For independent device lifecycle management, Linode also offers a
  separate `linode_firewall_device` resource; this module manages devices
  inline (one resource per module, per the repo convention).
- Tests are plan-only (`tests/validations.tftest.hcl`, `mock_provider`): they
  need no Linode token and create no infrastructure.

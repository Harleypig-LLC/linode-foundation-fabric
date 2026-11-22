# Basic usage of the linode_interface module. This example doubles as a
# plan-only test fixture: tests/validations.tftest.hcl plans it under a mock
# provider to prove the documented usage stays valid.

terraform {
  required_version = ">= 1.9"
}

module "interface" {
  source = "../.."

  linode_id   = 12345
  firewall_id = 1001

  # A public interface with auto-assigned IPv4/IPv6 addresses, created with
  # its firewall attached.
  public = {}
}

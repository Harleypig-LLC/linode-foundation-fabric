# A server on Linode Interfaces with a firewall on its public interface and a
# GRUB 2 profile, composed from this library's modules. This example doubles
# as a plan-only test fixture: tests/interfaces.tftest.hcl plans it under a
# mock provider to prove the composition stays valid.
#
# The instance is created without an image, so its boot disk and config
# profile are their own resources; that is what lets the profile boot
# linode/grub2. The firewall is attached through the interface's firewall_id
# at creation; the firewall leaves interfaces unset, so it reads that
# attachment back rather than managing it. Listing the interface there as well
# is a dependency cycle.

terraform {
  required_version = ">= 1.11"
}

module "firewall" {
  source = "../../../linode_firewall"

  label = "web-public"

  inbound = [{
    label    = "allow-https"
    action   = "ACCEPT"
    protocol = "TCP"
    ports    = "443"
    ipv4     = ["0.0.0.0/0"]
    ipv6     = ["::/0"]
  }]
}

module "instance" {
  source = "../.."

  label                = "web-1"
  region               = "us-east"
  type                 = "g6-standard-1"
  interface_generation = "linode"
  network_helper       = false
  booted               = false # the config profile below boots it
}

module "public_interface" {
  source = "../../../linode_interface"

  linode_id   = module.instance.instance_id
  firewall_id = module.firewall.id
  public      = {}
}

module "boot_disk" {
  source = "../../../linode_instance_disk"

  linode_id       = module.instance.instance_id
  label           = "boot"
  size            = 25000
  image           = "linode/ubuntu24.04"
  authorized_keys = ["ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIExampleKeyOnly example"]
}

module "boot_config" {
  source = "../../../linode_instance_config"

  # The interface must exist before the profile boots the Linode.
  depends_on = [module.public_interface]

  linode_id            = module.instance.instance_id
  label                = "boot"
  kernel               = "linode/grub2"
  interface_generation = module.instance.interface_generation
  devices              = [{ device_name = "sda", disk_id = module.boot_disk.id }]
}

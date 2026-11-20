locals {
  # helpers.network applies to legacy configuration profile interfaces only.
  # The provider sends every helper as a plain bool whenever a helpers block
  # exists, and the API refuses network = true on a Linode on Linode
  # Interfaces (provider issue #2457), so its default flips with the model.
  # A null value counts as omitted; sent as-is it would reach the provider's
  # own default of true.
  linode_interfaces       = var.interface_generation == "linode"
  helpers_network_default = !local.linode_interfaces
}

resource "linode_instance_config" "this" {
  linode_id    = var.linode_id
  label        = var.label
  booted       = var.booted
  comments     = var.comments
  kernel       = var.kernel
  memory_limit = var.memory_limit
  root_device  = var.root_device
  run_level    = var.run_level
  virt_mode    = var.virt_mode

  dynamic "helpers" {
    for_each = var.helpers != {} ? [var.helpers] : []
    content {
      devtmpfs_automount = lookup(helpers.value, "devtmpfs_automount", true)
      distro             = lookup(helpers.value, "distro", true)
      modules_dep        = lookup(helpers.value, "modules_dep", true)
      network            = coalesce(lookup(helpers.value, "network", null), local.helpers_network_default)
      updatedb_disabled  = lookup(helpers.value, "updatedb_disabled", true)
    }
  }

  dynamic "device" {
    for_each = var.devices
    content {
      device_name = device.value.device_name
      disk_id     = lookup(device.value, "disk_id", null)
      volume_id   = lookup(device.value, "volume_id", null)
    }
  }

  dynamic "interface" {
    for_each = var.interface
    content {
      purpose      = interface.value.purpose
      ipam_address = lookup(interface.value, "ipam_address", null)
      label        = lookup(interface.value, "label", null)
      subnet_id    = lookup(interface.value, "subnet_id", null)
      primary      = lookup(interface.value, "primary", null)

      dynamic "ipv4" {
        for_each = lookup(interface.value, "ipv4", null) != null ? [interface.value.ipv4] : []
        content {
          vpc     = lookup(ipv4.value, "vpc", null)
          nat_1_1 = lookup(ipv4.value, "nat_1_1", null)
        }
      }
    }
  }

  lifecycle {
    precondition {
      condition     = !(local.linode_interfaces && coalesce(lookup(var.helpers, "network", null), false))
      error_message = "helpers.network = true cannot be set on a Linode on Linode Interfaces; the API refuses it. Omit it or set it to false."
    }

    precondition {
      condition     = !(local.linode_interfaces && length(var.interface) > 0)
      error_message = "A Linode on Linode Interfaces takes no configuration profile interfaces; declare its interfaces with linode_interface instead."
    }
  }
}

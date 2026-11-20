# Plan-only tests for the create-time interface_generation and network_helper
# inputs. command = plan never creates real infrastructure; mock_provider
# satisfies provider config so no Linode token is needed. Run:
# terraform -chdir=modules/linode_instance_protected test
#
# interface_generation is Optional + Computed on the provider side. The mock
# supplies a computed value at plan time (override_during = plan), so the
# planned value tells the two paths apart: unset, the provider's value stands
# (the module sent nothing); set, the configured value wins.

mock_provider "linode" {
  override_during = plan

  mock_resource "linode_instance" {
    defaults = {
      interface_generation = "legacy_config"
      ipv4                 = ["198.51.100.10"]
    }
  }
}

variables {
  region = "us-central"
  type   = "g6-standard-1"
}

run "interface_generation_unset_leaves_choice_to_account" {
  command = plan

  assert {
    condition     = linode_instance.instance.interface_generation == "legacy_config"
    error_message = "with interface_generation unset the module must not send it; the provider-computed value should stand"
  }

  assert {
    condition     = linode_instance.instance.network_helper == null
    error_message = "network_helper should be omitted when unset"
  }
}

# The shape the Linode Interfaces servers are created with: an image-less
# instance (the boot disk and a GRUB 2 config profile are their own
# resources), Network Helper off, and no instance-level firewall_id, which
# the API reserves for legacy configuration profile interfaces.
run "linode_interfaces_instance_plans" {
  command = plan

  variables {
    interface_generation = "linode"
    network_helper       = false
  }

  assert {
    condition     = linode_instance.instance.interface_generation == "linode"
    error_message = "interface_generation = linode should pass through to the instance"
  }

  assert {
    condition     = linode_instance.instance.network_helper == false
    error_message = "network_helper = false should pass through to the instance"
  }

  assert {
    condition     = linode_instance.instance.firewall_id == null
    error_message = "no instance-level firewall_id should be planned"
  }
}

run "legacy_config_passes_through" {
  command = plan

  variables {
    interface_generation = "legacy_config"
  }

  assert {
    condition     = linode_instance.instance.interface_generation == "legacy_config"
    error_message = "interface_generation = legacy_config should pass through"
  }
}

run "rejects_unknown_interface_generation" {
  command = plan

  variables {
    interface_generation = "linode_interfaces" # the API value is "linode"
  }

  expect_failures = [var.interface_generation]
}

run "rejects_empty_interface_generation" {
  command = plan

  variables {
    interface_generation = ""
  }

  expect_failures = [var.interface_generation]
}

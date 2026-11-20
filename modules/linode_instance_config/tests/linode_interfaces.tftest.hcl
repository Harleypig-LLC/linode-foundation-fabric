# Plan-only tests for a GRUB 2 profile on a Linode on Linode Interfaces.
# command = plan never creates real infrastructure; mock_provider satisfies
# provider config so no Linode token is needed. Run:
# terraform -chdir=modules/linode_instance_config test

mock_provider "linode" {}

variables {
  linode_id            = 123
  label                = "boot"
  kernel               = "linode/grub2"
  interface_generation = "linode"
  devices              = [{ device_name = "sda", disk_id = 456 }]
}

# The provider's documented Linode Interfaces profile: no helpers block at
# all, so nothing about Network Helper is sent.
run "grub2_profile_without_helpers_plans" {
  command = plan

  assert {
    condition     = linode_instance_config.this.kernel == "linode/grub2"
    error_message = "the GRUB 2 kernel should pass through"
  }

  assert {
    condition     = length(linode_instance_config.this.interface) == 0
    error_message = "no configuration profile interface should be planned"
  }
}

# Setting any other helper sends the whole block; network must then go out
# as false, not the provider's default of true.
run "omitted_network_helper_defaults_to_false" {
  command = plan

  variables {
    helpers = { updatedb_disabled = false }
  }

  assert {
    condition     = linode_instance_config.this.helpers[0].network == false
    error_message = "on Linode Interfaces an omitted helpers.network must be sent as false"
  }

  assert {
    condition     = linode_instance_config.this.helpers[0].updatedb_disabled == false
    error_message = "the helper that was set should pass through"
  }

  assert {
    condition     = linode_instance_config.this.helpers[0].distro == true
    error_message = "the other omitted helpers keep their default of true"
  }
}

run "explicit_network_false_plans" {
  command = plan

  variables {
    helpers = { network = false }
  }

  assert {
    condition     = linode_instance_config.this.helpers[0].network == false
    error_message = "helpers.network = false should pass through"
  }
}

# Control: on a legacy profile the default is unchanged.
run "legacy_profile_keeps_network_default_true" {
  command = plan

  variables {
    interface_generation = null
    helpers              = { updatedb_disabled = false }
  }

  assert {
    condition     = linode_instance_config.this.helpers[0].network == true
    error_message = "a legacy profile must keep helpers.network defaulting to true"
  }
}

run "rejects_network_helper_on_linode_interfaces" {
  command = plan

  variables {
    helpers = { network = true }
  }

  expect_failures = [linode_instance_config.this]
}

run "rejects_config_interface_on_linode_interfaces" {
  command = plan

  variables {
    interface = [{ purpose = "public" }]
  }

  expect_failures = [linode_instance_config.this]
}

run "allows_config_interface_on_legacy_profile" {
  command = plan

  variables {
    interface_generation = "legacy_config"
    interface            = [{ purpose = "public" }]
  }

  assert {
    condition     = length(linode_instance_config.this.interface) == 1
    error_message = "a legacy profile may still declare configuration profile interfaces"
  }
}

run "rejects_unknown_interface_generation" {
  command = plan

  variables {
    interface_generation = "linode_interfaces" # the API value is "linode"
  }

  expect_failures = [var.interface_generation]
}

# A null helper value is the same as leaving it out: on Linode Interfaces,
# network must still go out as false, and the guard must still evaluate.
run "null_network_helper_is_treated_as_omitted" {
  command = plan

  variables {
    helpers = { network = null, updatedb_disabled = false }
  }

  assert {
    condition     = linode_instance_config.this.helpers[0].network == false
    error_message = "a null helpers.network must be sent as false on Linode Interfaces, not left to the provider's default of true"
  }
}

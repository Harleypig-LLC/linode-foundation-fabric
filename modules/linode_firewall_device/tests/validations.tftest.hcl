# Plan-only tests for the linode_firewall_device module. command = plan never
# creates real infrastructure; mock_provider satisfies provider config so no
# Linode token is needed. Run: terraform -chdir=modules/linode_firewall_device test

mock_provider "linode" {}

variables {
  firewall_id = 123456
  entity_id   = 654321
}

run "valid_firewall_device_plans" {
  command = plan

  assert {
    condition     = linode_firewall_device.this.entity_id == 654321
    error_message = "planned firewall device entity_id should match the input"
  }
}

run "rejects_non_positive_firewall_id" {
  command = plan

  variables {
    firewall_id = 0 # must be a positive integer
  }

  expect_failures = [var.firewall_id]
}

run "rejects_non_positive_entity_id" {
  command = plan

  variables {
    entity_id = -1 # must be a positive integer
  }

  expect_failures = [var.entity_id]
}

run "accepts_linode_interface_entity_type" {
  command = plan

  variables {
    entity_type = "linode_interface" # a Linode on Linode Interfaces
  }

  assert {
    condition     = linode_firewall_device.this.entity_type == "linode_interface"
    error_message = "entity_type linode_interface should pass through"
  }
}

run "accepts_nodebalancer_entity_type" {
  command = plan

  variables {
    entity_type = "nodebalancer"
  }

  assert {
    condition     = linode_firewall_device.this.entity_type == "nodebalancer"
    error_message = "entity_type nodebalancer should pass through"
  }
}

run "rejects_invalid_entity_type" {
  command = plan

  variables {
    entity_type = "bogus" # not linode, nodebalancer, or linode_interface
  }

  expect_failures = [var.entity_type]
}

run "rejects_interface_spelling" {
  command = plan

  variables {
    entity_type = "interface" # the API value is linode_interface
  }

  expect_failures = [var.entity_type]
}

run "example_basic_plans" {
  command = plan

  module {
    source = "./examples/basic"
  }
}

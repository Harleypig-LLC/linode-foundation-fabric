# Plan-only tests for the linode_interface module. command = plan never
# creates real infrastructure; mock_provider satisfies provider config so no
# Linode token is needed. Run: terraform -chdir=modules/linode_interface test

mock_provider "linode" {}

variables {
  linode_id   = 12345
  firewall_id = 1001
  public      = {}
}

run "valid_interface_plans" {
  command = plan

  assert {
    condition     = linode_interface.this.linode_id == 12345
    error_message = "planned interface linode_id should match the input"
  }

  assert {
    condition     = linode_interface.this.firewall_id == 1001
    error_message = "the interface should be created with the given firewall_id"
  }
}

# An interface sent with no firewall_id takes the account's default firewall,
# or fails to create when there is none; neither is this configuration's.
run "rejects_public_interface_without_firewall" {
  command = plan

  variables {
    firewall_id = null
  }

  expect_failures = [var.firewall_id]
}

run "rejects_vpc_interface_without_firewall" {
  command = plan

  variables {
    firewall_id = null
    public      = null
    vpc = {
      subnet_id = 42
    }
  }

  expect_failures = [var.firewall_id]
}

# The API's explicit opt-out: no firewall at all.
run "rejects_firewall_opt_out" {
  command = plan

  variables {
    firewall_id = -1
  }

  expect_failures = [var.firewall_id]
}

run "vlan_interface_needs_no_firewall" {
  command = plan

  variables {
    firewall_id = null
    public      = null
    vlan = {
      vlan_label = "backplane"
    }
  }

  assert {
    condition     = linode_interface.this.firewall_id == null
    error_message = "a VLAN interface takes no firewall_id"
  }
}

run "rejects_negative_linode_id" {
  command = plan

  variables {
    linode_id = -1 # must be positive
  }

  expect_failures = [var.linode_id]
}

run "rejects_negative_firewall_id" {
  command = plan

  variables {
    firewall_id = -5 # must be positive when set
  }

  expect_failures = [var.firewall_id]
}

run "rejects_vlan_label_bad_start" {
  command = plan

  variables {
    firewall_id = null
    public      = null
    vlan = {
      vlan_label = "-bad" # must start with an alphanumeric character
    }
  }

  expect_failures = [var.vlan]
}

run "rejects_vlan_label_too_long" {
  command = plan

  variables {
    firewall_id = null
    public      = null
    vlan = {
      # 65 characters, exceeding the 64-character maximum
      vlan_label = "aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa"
    }
  }

  expect_failures = [var.vlan]
}

run "rejects_nonpositive_vpc_subnet_id" {
  command = plan

  variables {
    public = null
    vpc = {
      subnet_id = 0 # must be a positive integer
    }
  }

  expect_failures = [var.vpc]
}

run "example_basic_plans" {
  command = plan

  module {
    source = "./examples/basic"
  }
}

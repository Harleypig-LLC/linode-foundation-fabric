# The protected module's own behaviour: once the disk exists, a change to a
# deploy-time attribute plans no change to it. The first run applies against
# the mock provider, which records a disk in the test's in-memory state and
# creates nothing real (no token, no API). Each later run is a plan against
# that state with one input changed. Run:
# terraform -chdir=modules/linode_instance_disk_protected test
#
# The mock does not model the provider's RequiresReplace, so it never plans
# a replacement and prevent_destroy never fires here. What it does show is
# the planned value: an ignored attribute keeps the value in state, an
# attribute that is not ignored takes the new input. The replacement and its
# refusal are checked against the real provider by the README's manual
# procedure.

mock_provider "linode" {
  mock_resource "linode_instance_disk" {
    defaults = {
      id = "4004"
    }
  }
}

variables {
  linode_id        = 123
  label            = "boot"
  size             = 1024
  image            = "linode/ubuntu24.04"
  authorized_keys  = ["ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIBootstrapKeyOne bootstrap"]
  authorized_users = ["alice"]
  stackscript_id   = 2002
  stackscript_data = { role = "web" }
}

run "create" {
  command = apply
}

run "image_change_plans_no_change" {
  command = plan

  variables {
    image = "linode/ubuntu26.04"
  }

  assert {
    condition     = linode_instance_disk.this.image == "linode/ubuntu24.04"
    error_message = "a changed image must not reach the plan; the value in state should stand"
  }
}

run "authorized_keys_change_plans_no_change" {
  command = plan

  variables {
    authorized_keys = ["ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIBootstrapKeyTwo rotated"]
  }

  assert {
    condition     = linode_instance_disk.this.authorized_keys == toset(["ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIBootstrapKeyOne bootstrap"])
    error_message = "changed authorized_keys must not reach the plan"
  }
}

run "authorized_users_change_plans_no_change" {
  command = plan

  variables {
    authorized_users = ["bob"]
  }

  assert {
    condition     = linode_instance_disk.this.authorized_users == toset(["alice"])
    error_message = "changed authorized_users must not reach the plan"
  }
}

run "stackscript_change_plans_no_change" {
  command = plan

  variables {
    stackscript_id   = 3003
    stackscript_data = { role = "db" }
  }

  assert {
    condition     = linode_instance_disk.this.stackscript_id == 2002 && linode_instance_disk.this.stackscript_data == tomap({ role = "web" })
    error_message = "a changed StackScript must not reach the plan"
  }
}

# Not ignored: a resize and a relabel are applied in place.
run "size_and_label_changes_still_plan" {
  command = plan

  variables {
    size  = 2048
    label = "boot-2"
  }

  assert {
    condition     = linode_instance_disk.this.size == 2048 && linode_instance_disk.this.label == "boot-2"
    error_message = "size and label are updated in place and must not be ignored"
  }
}

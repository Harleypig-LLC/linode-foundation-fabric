# Plan-only test for the id output, which a config profile's device disk_id
# consumes. The mock supplies the computed id at plan time
# (override_during = plan), so the output's conversion is exercised.
# Run: terraform -chdir=modules/linode_instance_disk_protected test

mock_provider "linode" {
  override_during = plan

  mock_resource "linode_instance_disk" {
    defaults = {
      id = "789"
    }
  }
}

variables {
  linode_id = 123
  label     = "boot"
  size      = 1024
  image     = "linode/ubuntu22.04"
}

run "id_output_is_numeric" {
  command = plan

  assert {
    condition     = output.id == 789
    error_message = "the id output should be the disk ID as a number"
  }
}

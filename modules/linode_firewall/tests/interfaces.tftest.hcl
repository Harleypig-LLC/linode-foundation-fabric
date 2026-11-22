# Plan-only tests for how the firewall treats interface attachments.
# command = plan never creates real infrastructure; mock_provider satisfies
# provider config so no Linode token is needed. Run:
# terraform -chdir=modules/linode_firewall test
#
# interfaces is Optional + Computed on the provider side, and the provider
# reads every attached interface back into it. The mock supplies a computed
# value at plan time (override_during = plan) standing for an interface that
# was created with this firewall's ID, so the planned value tells the two
# paths apart: unset, that attachment stands; set, the configured list is
# enforced and the attachment would be removed.

mock_provider "linode" {
  override_during = plan

  mock_resource "linode_firewall" {
    defaults = {
      interfaces = [777]
    }
  }
}

variables {
  label = "test-firewall"
}

run "interfaces_unset_leaves_attachments_unmanaged" {
  command = plan

  assert {
    condition     = linode_firewall.this.interfaces == toset([777])
    error_message = "with interfaces unset the module must not send it, or it would detach an interface attached by its own firewall_id"
  }
}

run "interfaces_set_is_enforced" {
  command = plan

  variables {
    interfaces = [42]
  }

  assert {
    condition     = linode_firewall.this.interfaces == toset([42])
    error_message = "a configured interfaces list should pass through"
  }
}

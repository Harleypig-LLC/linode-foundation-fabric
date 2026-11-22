# Plan-only tests for how the firewall treats device attachments. command =
# plan never creates real infrastructure; mock_provider satisfies provider
# config so no Linode token is needed. Run:
# terraform -chdir=modules/linode_firewall test
#
# linodes, nodebalancers and interfaces are Optional + Computed on the
# provider side (verified at linode/linode v4.10.0), and the provider reads
# every attached device back into them. The mock supplies a computed value at
# plan time (override_during = plan) standing for a device attached outside
# this module, such as an interface created with this firewall's ID, so the
# planned value tells the paths apart: unset, that attachment stands; set,
# [] included, the configured list is enforced and the attachment would be
# removed.

mock_provider "linode" {
  override_during = plan

  mock_resource "linode_firewall" {
    defaults = {
      linodes       = [555]
      nodebalancers = [666]
      interfaces    = [777]
    }
  }
}

variables {
  label = "test-firewall"
}

run "linodes_unset_leaves_attachments_unmanaged" {
  command = plan

  assert {
    condition     = linode_firewall.this.linodes == toset([555])
    error_message = "with linodes unset the module must not send it, or it would detach what is attached"
  }
}

run "linodes_empty_is_enforced" {
  command = plan

  variables {
    linodes = []
  }

  assert {
    condition     = length(linode_firewall.this.linodes) == 0
    error_message = "an explicit linodes = [] must be enforced, detaching what is attached"
  }
}

run "linodes_set_is_enforced" {
  command = plan

  variables {
    linodes = [42]
  }

  assert {
    condition     = linode_firewall.this.linodes == toset([42])
    error_message = "a configured linodes list should pass through"
  }
}

run "nodebalancers_unset_leaves_attachments_unmanaged" {
  command = plan

  assert {
    condition     = linode_firewall.this.nodebalancers == toset([666])
    error_message = "with nodebalancers unset the module must not send it, or it would detach what is attached"
  }
}

run "nodebalancers_empty_is_enforced" {
  command = plan

  variables {
    nodebalancers = []
  }

  assert {
    condition     = length(linode_firewall.this.nodebalancers) == 0
    error_message = "an explicit nodebalancers = [] must be enforced, detaching what is attached"
  }
}

run "nodebalancers_set_is_enforced" {
  command = plan

  variables {
    nodebalancers = [42]
  }

  assert {
    condition     = linode_firewall.this.nodebalancers == toset([42])
    error_message = "a configured nodebalancers list should pass through"
  }
}

run "interfaces_unset_leaves_attachments_unmanaged" {
  command = plan

  assert {
    condition     = linode_firewall.this.interfaces == toset([777])
    error_message = "with interfaces unset the module must not send it, or it would detach what is attached"
  }
}

run "interfaces_empty_is_enforced" {
  command = plan

  variables {
    interfaces = []
  }

  assert {
    condition     = length(linode_firewall.this.interfaces) == 0
    error_message = "an explicit interfaces = [] must be enforced, detaching what is attached"
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

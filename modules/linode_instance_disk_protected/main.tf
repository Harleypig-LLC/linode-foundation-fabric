# Protected variant of ../linode_instance_disk: identical in every way except
# the `lifecycle` block. It is a separate module because `prevent_destroy`
# and `ignore_changes` must be literals in the resource block; a variable
# cannot drive them and a module call cannot carry them.
#
# Keep variables.tf / outputs.tf / provider.tf in sync with
# ../linode_instance_disk; only this file (the lifecycle block) is meant to
# differ.
resource "linode_instance_disk" "this" {
  linode_id        = var.linode_id
  label            = var.label
  size             = var.size
  authorized_keys  = var.authorized_keys
  authorized_users = var.authorized_users
  filesystem       = var.filesystem
  image            = var.image
  root_pass        = var.root_pass
  stackscript_data = var.stackscript_data
  stackscript_id   = var.stackscript_id

  lifecycle {
    prevent_destroy = true

    # Read once, when the disk is deployed, and RequiresReplace in the
    # provider (linode/instancedisk/framework_resource_schema.go, v4.10.0).
    # A later change is never applied to the disk -- the provider's only
    # response is to replace it, and with it everything on it -- so it is
    # ignored here instead of letting prevent_destroy fail the plan. A
    # deliberate rebuild is in the README.
    #
    # Left out on purpose: label and size (updated in place; size is a
    # resize), and filesystem and linode_id (RequiresReplace and read back,
    # so ignoring either would leave config claiming a disk that is not
    # there; the plan is left to fail on prevent_destroy instead).
    ignore_changes = [
      image,            # the source image, used at deploy
      authorized_keys,  # written to root's authorized_keys at deploy
      authorized_users, # same, from the users' Linode profile keys
      root_pass,        # the initial root password, set at deploy
      stackscript_id,   # run once, at deploy
      stackscript_data, # that StackScript's inputs
    ]
  }
}

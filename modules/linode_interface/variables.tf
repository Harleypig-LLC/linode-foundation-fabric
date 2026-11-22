variable "linode_id" {
  description = "The ID of the Linode to assign this interface to."
  type        = number

  validation {
    condition     = var.linode_id > 0
    error_message = "linode_id must be a positive integer."
  }
}

variable "firewall_id" {
  description = "ID of an enabled firewall to secure a VPC or public interface, attached when the interface is created. Required for a public or VPC interface; not allowed for VLAN interfaces."
  type        = number
  default     = null

  validation {
    condition     = var.firewall_id == null || var.firewall_id > 0
    error_message = "firewall_id must be a positive integer when specified."
  }

  # Unset, the API falls back to the account's default firewall for the
  # interface type (linode_firewall_settings), and refuses the create when
  # there is none. Either way the interface's firewall is not this
  # configuration's to see, so it is required here, and the account default
  # is deliberately not used. The API's -1 opt-out is refused by the check
  # above.
  validation {
    condition     = var.firewall_id != null || (var.public == null && var.vpc == null)
    error_message = "A public or VPC interface must be created with a firewall_id."
  }

  validation {
    condition     = var.vlan == null || var.firewall_id == null
    error_message = "A VLAN interface takes no firewall_id."
  }
}

variable "default_route" {
  description = "Indicates if the interface serves as the default route when multiple interfaces are eligible for this role."
  type = object({
    ipv4 = optional(bool)
    ipv6 = optional(bool)
  })
  default = null
}

variable "public" {
  description = "Linode public interface. Mutually exclusive with vlan and vpc. Pass an empty object ({}) for a public interface with auto-assigned addresses."
  type = object({
    ipv4 = optional(object({
      addresses = optional(list(object({
        address = optional(string)
        primary = optional(bool)
      })))
    }))
    ipv6 = optional(object({
      ranges = optional(list(object({
        range = string
      })))
    }))
  })
  default = null
}

variable "vlan" {
  description = "Linode VLAN interface. Mutually exclusive with public and vpc."
  type = object({
    vlan_label   = string
    ipam_address = optional(string)
  })
  default = null

  validation {
    condition     = var.vlan == null || can(regex("^[a-zA-Z0-9][a-zA-Z0-9_-]*$", var.vlan.vlan_label))
    error_message = "vlan.vlan_label must start with an alphanumeric character and contain only alphanumerics, hyphens, and underscores."
  }

  validation {
    condition     = var.vlan == null || (length(var.vlan.vlan_label) >= 1 && length(var.vlan.vlan_label) <= 64)
    error_message = "vlan.vlan_label must be between 1 and 64 characters long."
  }
}

variable "vpc" {
  description = "Linode VPC interface. Mutually exclusive with public and vlan."
  type = object({
    subnet_id = number
    ipv4 = optional(object({
      addresses = optional(list(object({
        address         = optional(string)
        nat_1_1_address = optional(string)
        primary         = optional(bool)
      })))
      ranges = optional(list(object({
        range = string
      })))
    }))
    ipv6 = optional(object({
      is_public = optional(bool)
      ranges = optional(list(object({
        range = optional(string)
      })))
      slaac = optional(list(object({
        range = optional(string)
      })))
    }))
  })
  default = null

  validation {
    condition     = var.vpc == null || var.vpc.subnet_id > 0
    error_message = "vpc.subnet_id must be a positive integer."
  }
}

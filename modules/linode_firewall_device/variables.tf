variable "firewall_id" {
  description = "The ID of the Firewall to access."
  type        = number

  validation {
    condition     = var.firewall_id > 0
    error_message = "Firewall ID must be a positive integer."
  }
}

variable "entity_id" {
  description = "The ID of the entity to create a Firewall device for."
  type        = number

  validation {
    condition     = var.entity_id > 0
    error_message = "Entity ID must be a positive integer."
  }
}

variable "entity_type" {
  description = "The type of the entity to create a Firewall device for: linode, nodebalancer, or linode_interface. Null (the default) lets the provider default it to linode. A Linode on Linode Interfaces takes linode_interface, with entity_id the interface's ID; the API refuses linode for it."
  type        = string
  default     = null

  validation {
    condition     = var.entity_type == null || contains(["linode", "nodebalancer", "linode_interface"], var.entity_type)
    error_message = "Entity type must be linode, nodebalancer, or linode_interface."
  }
}

output "instance_id" {
  description = "The ID of the Linode instance."
  value       = linode_instance.instance.id
}

output "instance_ip_address" {
  description = "The public IP address of the Linode instance."
  value       = tolist(linode_instance.instance.ipv4)[0]
}

output "instance_private_ip_address" {
  description = "The private IP address of the Linode instance, if enabled."
  value       = linode_instance.instance.private_ip_address
}

output "instance_status" {
  description = "The status of the Linode instance."
  value       = linode_instance.instance.status
}

output "interface_generation" {
  description = "The interface model the Linode runs on (linode or legacy_config), as the API reports it. Pass it to linode_instance_config's interface_generation, so a Linode the account put on Linode Interfaces by default is still treated as one."
  value       = linode_instance.instance.interface_generation
}

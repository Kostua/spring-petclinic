output "public_instance_ip" {
  description = "Instance public IP"
  value       = module.vpcinstance.public_instance_ip
}

output "public_elasticip" {
  description = "Elastic IP address"
  value       = module.elasticip.elasticip_eip
}
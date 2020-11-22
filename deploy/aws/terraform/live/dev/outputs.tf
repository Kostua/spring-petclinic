output "public_instance_ip" {
  description = "Public instance IP"
  value       = module.vpcinstance.public_instance_ip
}

output "public_dns_name" {
  description = "Public DNS name"
  value       = module.vpcinstance.public_instance_dns
}
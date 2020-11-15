output "public_instance_ip" {
  value = module.vpcinstance.public_instance_ip
}

output "public_dns_name" {
  value = module.vpcinstance.public_instance_dns
}
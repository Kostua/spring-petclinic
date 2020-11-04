output "public_instance_ip" {
  value = module.vpcinstance.public_instance_ip
}

output "name" {
  value = module.elasticip.elasticip_eip
}
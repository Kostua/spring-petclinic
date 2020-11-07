output "public_instance_ip" {
  value = module.vpcinstance.public_instance_ip
}

output "public_elasticip" {
  value = module.elasticip.elasticip_eip
}
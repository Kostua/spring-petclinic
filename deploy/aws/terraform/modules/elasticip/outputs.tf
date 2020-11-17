
output "elasticip_eip" {
  value = aws_eip.elasticip.public_ip
}

output "elasticip_eip_alloc_id" {
  value = aws_eip.elasticip.id
}
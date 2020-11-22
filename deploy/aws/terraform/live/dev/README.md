## Requirements

| Name | Version |
|------|---------|
| terraform | >= 0.12 |
| aws | >= 3.16.0 |

## Providers

| Name | Version |
|------|---------|
| local | n/a |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| availability\_zone | availability zone to create subnet | `string` | `"us-east-2a"` | no |
| cidr\_subnet | CIDR block for the subnet | `string` | `"10.1.0.0/24"` | no |
| cidr\_vpc | CIDR block for the VPC | `string` | `"10.1.0.0/16"` | no |
| environment | Name of environment | `string` | `"dev"` | no |
| instance\_ami | AMI for aws EC2 instance | `string` | `"ami-03657b56516ab7912"` | no |
| instance\_type | type for aws EC2 instance | `string` | `"t2.micro"` | no |
| region | Variables | `string` | `"us-east-2"` | no |
| vpc\_name | Name of VPC | `string` | `"dev"` | no |
| vpc\_tags | Tags to apply to resources created by VPC module | `map(string)` | <pre>{<br>  "Environment": "dev",<br>  "Terraform": "true"<br>}</pre> | no |

## Outputs

| Name | Description |
|------|-------------|
| public\_dns\_name | Public DNS name |
| public\_instance\_ip | Public instance IP |

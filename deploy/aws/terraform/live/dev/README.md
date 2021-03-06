## Requirements

| Name | Version |
|------|---------|
| terraform | >= 0.12 |

## Providers

| Name | Version |
|------|---------|
| aws | n/a |
| null | n/a |
| random | n/a |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| enable\_vpn\_gateway | Enable a VPN gateway in your VPC. | `bool` | `false` | no |
| environment | Variables | `string` | `"dev"` | no |
| instance\_type | type for aws EC2 instance | `string` | `"t2.micro"` | no |
| ports | Port for load balancer listener | `map(number)` | <pre>{<br>  "http": 80<br>}</pre> | no |
| private\_subnet\_cidr\_blocks | Available cidr blocks for private subnets | `list(string)` | <pre>[<br>  "10.0.101.0/24",<br>  "10.0.102.0/24",<br>  "10.0.103.0/24",<br>  "10.0.104.0/24",<br>  "10.0.105.0/24",<br>  "10.0.106.0/24",<br>  "10.0.107.0/24",<br>  "10.0.108.0/24"<br>]</pre> | no |
| private\_subnet\_count | Number of private subnets. | `number` | `2` | no |
| public\_subnet\_cidr\_blocks | Available cidr blocks for public subnets | `list(string)` | <pre>[<br>  "10.0.1.0/24",<br>  "10.0.2.0/24",<br>  "10.0.3.0/24",<br>  "10.0.4.0/24",<br>  "10.0.5.0/24",<br>  "10.0.6.0/24",<br>  "10.0.7.0/24",<br>  "10.0.8.0/24"<br>]</pre> | no |
| public\_subnet\_count | Number of public subnets. | `number` | `2` | no |
| region | The region Terraform deploys your instances | `string` | `"us-east-1"` | no |
| tags | Tags to apply to resources | `map(string)` | <pre>{<br>  "Environment": "dev",<br>  "Terraform": "true"<br>}</pre> | no |
| vpc\_cidr\_block | CIDR block for VPC | `string` | `"10.0.0.0/16"` | no |

## Outputs

| Name | Description |
|------|-------------|
| lb\_dns\_name | n/a |

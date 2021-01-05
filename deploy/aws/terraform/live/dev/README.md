## Requirements

| Name | Version |
|------|---------|
| terraform | >= 0.12 |
| aws | >= 3.16.0 |

## Providers

| Name | Version |
|------|---------|
| aws | >= 3.16.0 |
| null | n/a |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| environment | Variables | `string` | `"dev"` | no |
| region | n/a | `string` | `"us-east-2"` | no |
| vpc\_tags | Tags to apply to resources created by VPC module | `map(string)` | <pre>{<br>  "Environment": "dev",<br>  "Terraform": "true"<br>}</pre> | no |

## Outputs

No output.

variable "aws_access_key" { }
variable "aws_secret_key" { }
variable "name"           { default = "dynamic-aws-creds-vault-admin" }

terraform {
  backend "s3" {
    bucket = "terraform-us2ua-state"
    key = "global/s3/admin/terraform.tfstate"
    region = "us-east-2"
    dynamodb_table = "terraform.locks"
  }
}

provider "vault" {}

resource "vault_aws_secret_backend" "aws" {
  access_key = var.aws_access_key
  secret_key = var.aws_secret_key
  path       = "${var.name}-path"

  default_lease_ttl_seconds = "120"
  max_lease_ttl_seconds     = "240"
}

resource "vault_aws_secret_backend_role" "admin" {
  backend = vault_aws_secret_backend.aws.path
  name    = "${var.name}-role"
  credential_type = "iam_user"

  policy_document = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "iam:*", "ec2:*"
      ],
      "Resource": "*"
    }
  ]
}
EOF
}

output "backend" {
  value = vault_aws_secret_backend.aws.path
}

output "role" {
  value = vault_aws_secret_backend_role.admin.name
}

terraform {
  # Allow any 0.13.x version of Terraform
  required_version = ">= 0.12"
}


terraform {
  # Partial backend configuration
  # The other setting will be passed from backend.hcl from
  # command $terraform init -backend-config=backend.hcl
  backend "s3" {
    key = "global/s3/petclinic/dev/terraform.tfstate"
  }
}

provider "aws" {
  # Allow any 3.11.x version of the AWS provider
  version = ">= 3.16.0"
  region  = var.region
}

resource "null_resource" "packer_runner" {
  triggers = {
    always_run = timestamp()
  }

  provisioner "local-exec" {
    command = "packer build -var 'environment=${var.environment}' ./packer/dev.json"
  }
}

data "aws_ami" "app-ami" {
  most_recent = true
  owners      = ["self"]

  filter {
    name   = "name"
    values = ["packer-${var.environment}"]
  }

  filter {
    name   = "root-device-type"
    values = ["ebs"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}







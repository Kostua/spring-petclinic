variable "name" { default = "dynamic-aws-creds-operator" }
variable "region" { default = "us-east-2" }
variable "path" { default = "global/s3/terraform.tfstate" }
variable "ttl" { default = "1" }

terraform {
  required_version = ">= 0.12"

  backend "s3" {
    bucket = "terraform-us2ua-state"
    key = "global/s3/operator/terraform.tfstate"
    region = "us-east-2"
    dynamodb_table = "terraform.locks"
  }
  
}

provider "aws" {
  region     = var.region
}

data "aws_ami" "ubuntu" {
  most_recent = true

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-focal-20.04-amd64-server-*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }

  owners = ["099720109477"] # Canonical
}

# Create AWS EC2 Instance
resource "aws_instance" "main" {
  ami           = data.aws_ami.ubuntu.id
  instance_type = "t2.nano"

  tags = {
    Name  = var.name
    TTL   = var.ttl
    owner = "${var.name}-guide"
  }
}

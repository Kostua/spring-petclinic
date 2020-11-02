terraform {
  # Allow any 0.13.x version of Terraform
  required_version = "~> 0.13"
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
  version = "~> 3.11"
  region  = var.region
}

module "vpcinstance" {
  region = var.region
  source = "../../modules/vpcinstance"
  vpc_name = var.vpc_name
  cidr_vpc = var.cidr_vpc
  cidr_subnet = var.cidr_subnet
  availability_zone = var.availability_zone
  instance_ami = var.instance_ami
  instance_type = var.instance_type

}







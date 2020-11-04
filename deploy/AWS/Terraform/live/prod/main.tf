terraform {
  # Allow any 0.13.x version of Terraform
  required_version = "~> 0.13"
}


terraform {
  # Partial backend configuration
  # The other setting will be passed from backend.hcl from
  # command $terraform init -backend-config=backend.hcl
  backend "s3" {
    key = "global/s3/petclinic/prod/terraform.tfstate"
  }
}

provider "aws" {
  # Allow any 3.11.x version of the AWS provider
  version = "~> 3.11"
  region  = var.region
}

module "elasticip" {
  region = var.region
  source = "../../modules/elasticip"  
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

resource "aws_eip_association" "eip_assoc" {
instance_id   = module.vpcinstance.instance_id
allocation_id = module.elasticip.elasticip_eip_alloc_id
}









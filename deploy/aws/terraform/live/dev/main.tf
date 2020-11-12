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
  version = "~> 3.11"
  region  = var.region
}

module "vpcinstance" {
  region = var.region
  environment = var.environment
  source = "../../modules/vpcinstance"
  vpc_name = var.environment
  cidr_vpc = var.cidr_vpc
  cidr_subnet = var.cidr_subnet
  availability_zone = var.availability_zone
  instance_ami = var.instance_ami
  instance_type = var.instance_type
  vpc_tags = var.vpc_tags

}

resource "local_file" "privatekey" {
    filename = "./ansible/deploy.pem"
    sensitive_content = module.vpcinstance.private_key_pem 
    provisioner "local-exec" {
        command = "chmod 600 ${self.filename}"
    }
}


module "provisioner" {
  source = "../../modules/provisioner"
  username = "ec2-user"
  private_key_pem = module.vpcinstance.private_key_pem
  public_ip = module.vpcinstance.public_instance_ip
  trigger_public_ip = module.vpcinstance.public_instance_ip
  
}






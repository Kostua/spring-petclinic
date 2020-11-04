# Variables
variable "region" {
    default = "us-east-2"
}

variable "vpc_name" {
  description = "Name of VPC"
  default     = "petclinic"
}

variable "cidr_vpc" {
    description = "CIDR block for the VPC"
    default = "10.1.0.0/16"
}

variable "cidr_subnet" {
    description = "CIDR block for the subnet"
    default = "10.1.0.0/24"
}

variable "availability_zone" {
  description = "availability zone to create subnet"
  default     = "us-east-2a"
}

variable "instance_ami" {
  description = "AMI for aws EC2 instance"
  default     = "ami-03657b56516ab7912"
}

variable "instance_type" {
  description = "type for aws EC2 instance"
  default     = "t2.micro"
}

variable "vpc_tags" {
  description = "Tags to apply to resources created by VPC module"
  type        = map(string)
  default     = {
    Terraform   = "true"
    Environment = "prod"
  }
}
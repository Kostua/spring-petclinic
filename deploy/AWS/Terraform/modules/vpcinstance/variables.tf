# Variables
variable "region" {
  type = string
}

variable "vpc_name" {
  description = "Name of VPC"
  type        = string
}

variable "cidr_vpc" {
  description = "CIDR block for the VPC"
  type = string
}

variable "cidr_subnet" {
  description = "CIDR block for the subnet"
  type = string
}

variable "availability_zone" {
  description = "availability zone to create subnet"
  type = string
}

# variable "public_key_path" {
#  description = "Public key path"
#  type = string
#  default     = "~/.ssh/id_rsa.pub"
# }

variable "instance_ami" {
  description = "AMI for aws EC2 instance"
  type = string
}

variable "instance_type" {
  description = "type for aws EC2 instance"
  type = string
}

variable "vpc_tags" {
  description = "Tags to apply to resources created by VPC module"
  type        = map(string)
  default = {
    Terraform   = "true"
    Environment = "dev"
  }
}
# variable "ssh_key_private" {
#  description = "Public key path"
#  default     = "~/.ssh/id_rsa"
# }

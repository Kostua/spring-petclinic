# Variables
variable "environment" {
  type    = string
  default = "dev"
}

variable "region" {
  default = "us-east-2"
}


variable "vpc_tags" {
  description = "Tags to apply to resources created by VPC module"
  type        = map(string)
  default = {
    Terraform   = "true"
    Environment = "dev"
  }
}
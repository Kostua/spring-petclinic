provider "aws" {
region = var.region
}

resource "aws_eip" "elasticip" {
vpc = true
tags = var.eip_tags
}
terraform {
  # Allow any 0.12 and higer version of Terraform
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
  region = var.region
}

resource "aws_eip" "petclinic_pp_ua" {
  vpc  = true
  tags = var.tags
}


resource "null_resource" "packer_runner" {
  triggers = {
    always_run = timestamp()
  }

  provisioner "local-exec" {
    command = "packer build -var 'environment=${var.environment}' ./packer/dev.json"
  }
}

data "aws_ami" "app_ami" {
  most_recent = true
  owners      = ["self"]

  filter {
    name   = "name"
    values = ["packer-${var.environment}"]
  }

  depends_on = [
    null_resource.packer_runner
  ]

}

data "aws_availability_zones" "available" {
  state = "available"
}

resource "aws_vpc" "my_vpc" {
  cidr_block           = var.vpc_cidr_block
  enable_dns_hostnames = true

  tags = merge(
    var.tags,
    {
      Name = var.environment
    },
  )
}

resource "aws_subnet" "primary" {
  vpc_id            = aws_vpc.my_vpc.id
  cidr_block        = var.public_subnet_cidr_blocks[0]
  availability_zone = data.aws_availability_zones.available.names[0]


  tags = {
    Name = "Public Subnet primary"
  }
}

resource "aws_subnet" "secondary" {
  vpc_id            = aws_vpc.my_vpc.id
  cidr_block        = var.public_subnet_cidr_blocks[1]
  availability_zone = data.aws_availability_zones.available.names[1]

  tags = {
    Name = "Public Subnet secondary"
  }
}

resource "aws_internet_gateway" "my_vpc_igw" {
  vpc_id = aws_vpc.my_vpc.id

  tags = {
    Name = "My VPC - Internet Gateway"
  }
}

resource "aws_route_table" "my_vpc_public" {
  vpc_id = aws_vpc.my_vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.my_vpc_igw.id
  }

  tags = {
    Name = "Public Subnets Route Table for My VPC"
  }
}

resource "aws_route_table_association" "primary_public" {
  subnet_id      = aws_subnet.primary.id
  route_table_id = aws_route_table.my_vpc_public.id
}

resource "aws_route_table_association" "secondary_public" {
  subnet_id      = aws_subnet.secondary.id
  route_table_id = aws_route_table.my_vpc_public.id
}

resource "aws_security_group" "allow_http" {
  description = "Allow connection between NLB and target"
  vpc_id      = aws_vpc.my_vpc.id
}

resource "aws_security_group_rule" "ingress" {
  for_each = var.ports

  security_group_id = aws_security_group.allow_http.id
  from_port         = each.value
  to_port           = each.value
  protocol          = "TCP"
  type              = "ingress"
  cidr_blocks       = ["0.0.0.0/0"]
}


resource "aws_launch_configuration" "as_conf" {
  image_id                    = data.aws_ami.app_ami.id
  instance_type               = var.instance_type
  security_groups             = [aws_security_group.allow_http.id]
  associate_public_ip_address = true
  # Required when using a launch configuration with an auto scaling group.
  # https://www.terraform.io/docs/providers/aws/r/launch_configuration.html
  lifecycle {
    create_before_destroy = true
  }
}


resource "random_pet" "app" {
  length    = 2
  separator = "-"
}

resource "aws_lb" "app" {
  name                             = "main-app-${random_pet.app.id}-lb"
  internal                         = false
  load_balancer_type               = "network"
  enable_cross_zone_load_balancing = false
  #  security_groups = [
  #    aws_security_group.elb_http.id
  #  ]
  # subnets = [
  #   aws_subnet.primary.id
  #   aws_subnet.secondary.id
  # ]

  subnet_mapping {
    subnet_id     = aws_subnet.primary.id
    allocation_id = aws_eip.petclinic_pp_ua.id
  }


}


resource "aws_lb_listener" "app" {
  for_each          = var.ports
  load_balancer_arn = aws_lb.app.arn
  port              = each.value
  protocol          = "TCP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.blue[each.key].arn

  }
}


resource "aws_lb_target_group" "blue" {
  for_each = var.ports
  port     = each.value
  protocol = "TCP"
  vpc_id   = aws_vpc.my_vpc.id

  depends_on = [
    aws_lb.app
  ]

  lifecycle {
    create_before_destroy = true
  }


}

resource "aws_autoscaling_attachment" "target" {
  for_each = var.ports

  autoscaling_group_name = aws_autoscaling_group.app.id
  alb_target_group_arn   = aws_lb_target_group.blue[each.key].arn
}

resource "aws_autoscaling_group" "app" {
  name                      = "terraform-asg-example"
  launch_configuration      = aws_launch_configuration.as_conf.name
  health_check_type         = "ELB"
  health_check_grace_period = 300
  min_size                  = 1
  max_size                  = 4
  desired_capacity          = 1
  vpc_zone_identifier = [
    aws_subnet.primary.id,
    # aws_subnet.secondary.id
  ]
  lifecycle {
    create_before_destroy = true
  }
}


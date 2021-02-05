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
  # Allow any 3.20.x version of the AWS provider
  version = ">= 3.20.0"
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

data "aws_ami" "app_ami" {
  most_recent = true
  owners      = ["self"]

  filter {
    name   = "name"
    values = ["packer-${var.environment}"]
  }

}

resource "aws_vpc" "my_vpc" {
  cidr_block           = "10.0.0.0/16"
  enable_dns_hostnames = true

  tags = merge(
    var.tags,
    {
      Name = var.environment
    },
  )
}

resource "aws_subnet" "public_us_east_2a" {
  vpc_id            = aws_vpc.my_vpc.id
  cidr_block        = "10.0.0.0/24"
  availability_zone = "us-east-2a"

  tags = {
    Name = "Public Subnet us-east-2a"
  }
}

resource "aws_subnet" "public_us_east_2b" {
  vpc_id            = aws_vpc.my_vpc.id
  cidr_block        = "10.0.1.0/24"
  availability_zone = "us-east-2b"

  tags = {
    Name = "Public Subnet us-east-2b"
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

resource "aws_route_table_association" "my_vpc_us_east_2a_public" {
  subnet_id      = aws_subnet.public_us_east_2a.id
  route_table_id = aws_route_table.my_vpc_public.id
}

resource "aws_route_table_association" "my_vpc_us_east_2b_public" {
  subnet_id      = aws_subnet.public_us_east_2b.id
  route_table_id = aws_route_table.my_vpc_public.id
}

resource "aws_security_group" "allow_http" {
  name        = "allow_http"
  description = "Allow HTTP inbound connections"
  vpc_id      = aws_vpc.my_vpc.id

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "Allow HTTP Security Group"
  }
}

resource "aws_security_group" "elb_http" {
  name        = "elb_http"
  description = "Allow HTTP traffic to instances through Elastic Load Balancer"
  vpc_id      = aws_vpc.my_vpc.id

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "Allow HTTP through ELB Security Group"
  }
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
  load_balancer_type               = "application"
  enable_cross_zone_load_balancing = true
  security_groups = [
    aws_security_group.elb_http.id
  ]
  subnets = [
    aws_subnet.public_us_east_2a.id,
    aws_subnet.public_us_east_2b.id
  ]

}


resource "aws_lb_listener" "app" {
  load_balancer_arn = aws_lb.app.arn
  port              = "80"
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.blue.arn

  }
}


resource "aws_lb_target_group" "blue" {
  name     = "blue-tg-${random_pet.app.id}-lb"
  port     = 80
  protocol = "HTTP"
  vpc_id   = aws_vpc.my_vpc.id

  depends_on = [
    aws_lb.app
  ]


  health_check {
    port     = 80
    protocol = "HTTP"
    timeout  = 5
    interval = 10
  }
  lifecycle {
    create_before_destroy = true
  }

}

resource "aws_autoscaling_group" "bar" {
  name                      = "terraform-asg-example"
  launch_configuration      = aws_launch_configuration.as_conf.name
  target_group_arns         = [aws_lb_target_group.blue.arn]
  health_check_type         = "ELB"
  health_check_grace_period = 300
  min_size                  = 1
  max_size                  = 4
  desired_capacity          = 1
  vpc_zone_identifier = [
    aws_subnet.public_us_east_2a.id,
    aws_subnet.public_us_east_2b.id
  ]
  lifecycle {
    create_before_destroy = true
  }
}


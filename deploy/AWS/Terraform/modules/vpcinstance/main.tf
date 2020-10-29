terraform {
  required_version = "~> 0.13"
}


#resources
resource "aws_vpc" "vpc" {
  cidr_block           = var.cidr_vpc
  enable_dns_support   = true
  enable_dns_hostnames = true
  tags                 = var.vpc_tags
}

resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.vpc.id
  tags   = var.vpc_tags
}

resource "aws_subnet" "subnet_public" {
  vpc_id                  = aws_vpc.vpc.id
  cidr_block              = var.cidr_subnet
  map_public_ip_on_launch = "true"
  availability_zone       = var.availability_zone
  tags                    = var.vpc_tags
}

resource "aws_route_table" "rtb_public" {
  vpc_id = aws_vpc.vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }
  tags = var.vpc_tags
}

resource "aws_route_table_association" "rta_subnet_public" {
  subnet_id      = aws_subnet.subnet_public.id
  route_table_id = aws_route_table.rtb_public.id
}

resource "aws_security_group" "sg_22" {
  name   = "sg_22"
  vpc_id = aws_vpc.vpc.id

  # SSH access from the VPC
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = var.vpc_tags

}

resource "aws_security_group" "sg_80" {
  name   = "sg_80"
  vpc_id = aws_vpc.vpc.id

  # Test web access from the VPC
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

  tags = var.vpc_tags

}

resource "tls_private_key" "keypair" {
  algorithm   = "RSA"
}

resource "local_file" "privatekey" {
    filename = "deploy.pem"
    sensitive_content = tls_private_key.keypair.private_key_pem
     provisioner "local-exec" {
        command = "chmod 600 ${self.filename}"
  }
}


resource "aws_key_pair" "ec2key" {
  key_name   = "publicKey"
#  public_key = file(var.public_key_path)
  public_key = tls_private_key.keypair.public_key_openssh
}

resource "aws_instance" "webInstance" {
  ami                    = var.instance_ami
  instance_type          = var.instance_type
  subnet_id              = aws_subnet.subnet_public.id
  vpc_security_group_ids = [aws_security_group.sg_22.id, aws_security_group.sg_80.id]
  key_name               = aws_key_pair.ec2key.key_name
  tags                   = var.vpc_tags
}
#---------------------------------------------------------------------------------------------------------------------
# Provision the server using remote-exec
# ---------------------------------------------------------------------------------------------------------------------

resource "null_resource" "example_provisioner" {
  triggers = {
    public_ip = aws_instance.webInstance.public_ip
  }

  connection {
    type        = "ssh"
    host        = aws_instance.webInstance.public_ip
    user        = "ec2-user"
#    private_key = file(var.ssh_key_private)
    private_key = tls_private_key.keypair.private_key_pem
  }

  // change permissions to executable and pipe its output into a new file
  provisioner "remote-exec" {
    #  Install Python for Ansible
    inline = [
      "sudo yum install -y python3 pip3 docker-py libselinux-python"
    ]
  }

  provisioner "local-exec" {
    command = "ansible-playbook -u ec2-user -i '${aws_instance.webInstance.public_ip},' -T 300 provision.yml" 
  }
}




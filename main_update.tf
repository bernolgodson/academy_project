#----# Provider

provider "aws" {
  region                  = var.aws_region
  shared_credentials_file = var.aws_credentials
  profile                 = var.aws_profile
  version                 = "~> 2.61.0"
}

#----#VPC default data retrieved

data "aws_vpc" "default" {
  default = true
}

resource "aws_subnet" "default" {
  vpc_id     = data.aws_vpc.default.id
  cidr_block = cidrsubnet(data.aws_vpc.default.cidr_block, 4, 1)
}

#----#Availability Zones

#data "aws_availability_zones" "available" {}


#----#internet gateway

resource "aws_internet_gateway" "wp_internet_gateway" {
  vpc_id = data.aws_vpc.default.id
}

#----#Route tables Internet access to VPC

resource "aws_route_table" "public" {
  vpc_id = data.aws_vpc.default.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.wp_internet_gateway.id
  }
}

#----#Security groups

resource "aws_security_group" "employee_sg" {
  name        = "employee_sg"
  description = "Used for access to aws instances"
  vpc_id      = data.aws_vpc.default.id

  #SSH

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = [var.localip]
  }

  #HTTP

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  #Outbound internet access

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_security_group" "customer_sg" {
  name        = "customer_sg"
  description = "Used for public to get a web access to dev and prod instances"
  vpc_id      = data.aws_vpc.default.id

  #HTTP

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  #Outbound internet access

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}
#----#VPC Security Group

resource "aws_security_group" "vpc_sg" {
  name        = "vpc_sg"
  description = "Used for internal instances"
  vpc_id      = data.aws_vpc.default.id

  # Access from other security groups

  ingress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = [aws_subnet.default.id]
  }
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

#----# key pair

resource "aws_key_pair" "auth" {
  key_name   = var.key_name
  public_key = file(var.public_key_path)
}

#----# dev machine

resource "aws_instance" "dev" {
  instance_type = var.all_instance_type
  ami           = var.all_ami

  tags = {
    Name = "dev instance"
  }

  key_name               = aws_key_pair.auth.id
  vpc_security_group_ids = [aws_security_group.vpc_sg.id]
  subnet_id              = aws_subnet.default.id

  provisioner "local-exec" {
    command = <<EOD
cat <<EOF > aws_hosts
[dev]
${aws_instance.dev.subnet_id}
EOF
EOD
  }

  provisioner "local-exec" {
    command = "aws ec2 wait instance-status-ok --instance-ids ${aws_instance.dev.id} && ansible-playbook -i aws_hosts apache.yml"
  }
}
#----# prod machine

resource "aws_instance" "prod" {
  instance_type = var.all_instance_type
  ami           = var.all_ami

  tags = {
    Name = "prod instance"
  }

  key_name               = aws_key_pair.auth.id
  vpc_security_group_ids = [aws_security_group.vpc_sg.id]
  subnet_id              = aws_subnet.default.id

  provisioner "local-exec" {
    command = <<EOD
cat <<EOF > aws_hosts
[prod]
${aws_instance.prod.subnet_id}
EOF
EOD
  }

  provisioner "local-exec" {
    command = "aws ec2 wait instance-status-ok --instance-ids ${aws_instance.prod.id} && ansible-playbook -i aws_hosts apache.yml"
  }
}
#----# jump machine

resource "aws_instance" "jump" {
  instance_type = var.all_instance_type
  ami           = var.all_ami

  tags = {
    Name = "jump instance"
  }

  key_name               = aws_key_pair.auth.id
  vpc_security_group_ids = [aws_security_group.vpc_sg.id]
  subnet_id              = aws_subnet.default.id

}

#----# machine dns outputs

output "dev_instance_public_dns" {
  value = aws_instance.dev.public_dns
}
output "jump_instance_public_dns" {
  value = aws_instance.jump.public_dns
}
output "prod_instance_public_dns" {
  value = aws_instance.prod.public_dns
}


output "instance_subnet_id" {
  value = aws_instance.jump.subnet_id
}

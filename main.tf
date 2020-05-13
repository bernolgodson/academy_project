provider "aws" {
  region                  = var.aws_region
  shared_credentials_file = var.aws_credentials
  profile                 = var.aws_profile
}

data "aws_availability_zones" "available" {}

# VPC

resource "aws_vpc" "wp_vpc" {
  cidr_block           = var.vpc_cidr
  enable_dns_hostnames = true
  enable_dns_support   = true

  #  tags {
  #    Name = "wp_vpc"
  #  }
}


#internet gateway

resource "aws_internet_gateway" "wp_internet_gateway" {
  vpc_id = aws_vpc.wp_vpc.id

  #  tags {
  #    Name = "wp_igw"
  #  }
}

#Security groups

resource "aws_security_group" "employee_sg" {
  name        = "employee_sg"
  description = "Used for access to aws instances"
  vpc_id      = aws_vpc.wp_vpc.id

  #SSH

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = var.localip
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
  vpc_id      = aws_vpc.wp_vpc.id

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
#VPC Security Group

resource "aws_security_group" "vpc_sg" {
  name        = "vpc_sg"
  description = "Used for internal instances"
  vpc_id      = aws_vpc.wp_vpc.id

  # Access from other security groups

  ingress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["10.0.0.0/16"]
  }
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# key pair

resource "aws_key_pair" "auth" {
  key_name   = var.key_name
  public_key = file(var.public_key_path)
}

# dev machine

resource "aws_instance" "dev" {
  instance_type = var.all_instance_type
  ami           = var.all_ami

  # tags {
  #   Name = "dev instance"
  # }

  key_name               = aws_key_pair.auth.id
  vpc_security_group_ids = [aws_security_group.vpc_sg.id]
  subnet_id              = aws_vpc.wp_vpc.id

  provisioner "local-exec" {
    command = <<EOD
cat <<EOF > aws_hosts
[dev]
${aws_instance.dev.public_ip}
EOF
EOD
  }

  provisioner "local-exec" {
    command = "aws ec2 wait instance-status-ok --instance-ids ${aws_instance.dev.id} && ansible-playbook -i aws_hosts apache.yml"
  }
}
# prod machine

resource "aws_instance" "prod" {
  instance_type = var.all_instance_type
  ami           = var.all_ami

  #  tags {
  #   Name = "prod instance"
  #  }

  key_name               = aws_key_pair.auth.id
  vpc_security_group_ids = [aws_security_group.vpc_sg.id]
  subnet_id              = aws_vpc.wp_vpc.id

  provisioner "local-exec" {
    command = <<EOD
cat <<EOF > aws_hosts
[prod]
${aws_instance.prod.public_ip}
EOF
EOD
  }

  provisioner "local-exec" {
    command = "aws ec2 wait instance-status-ok --instance-ids ${aws_instance.prod.id} && ansible-playbook -i aws_hosts apache.yml"
  }
}
# jump machine

resource "aws_instance" "jump" {
  instance_type = var.all_instance_type
  ami           = var.all_ami

  # tags {
  #    Name = "jump instance"
  # }

  key_name               = aws_key_pair.auth.id
  vpc_security_group_ids = [aws_security_group.vpc_sg.id]
  subnet_id              = aws_vpc.wp_vpc.id

}

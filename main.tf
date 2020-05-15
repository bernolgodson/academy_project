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

#----#Security groups

resource "aws_security_group" "employee_sg" {
  name        = "employee_sg"
  description = "Used for access to aws instances"
  # vpc_id      = data.aws_vpc.default.id

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
  ingress {
    from_port   = 8080
    to_port     = 8080
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

#----#access from other Security Group

resource "aws_security_group" "vpc_sg" {
  name        = "vpc_sg"
  description = "Used for internal instances"
  vpc_id      = data.aws_vpc.default.id

  # Access from other security groups

  ingress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = [data.aws_vpc.default.cidr_block]
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

  key_name        = aws_key_pair.auth.id
  security_groups = [aws_security_group.employee_sg.name]

  provisioner "local-exec" {
    command = <<EOD
cat <<EOF >> aws_hosts
[dev]
${aws_instance.dev.public_ip}
EOF
EOD
  }

  provisioner "local-exec" {
    command = "sleep 300 && ansible-playbook -i aws_hosts apache.yml"
  }
}
#----# prod machine

resource "aws_instance" "prod" {
  instance_type = var.all_instance_type
  ami           = var.all_ami

  tags = {
    Name = "prod instance"
  }

  key_name        = aws_key_pair.auth.id
  security_groups = [aws_security_group.employee_sg.name]

  provisioner "local-exec" {
    command = <<EOD
cat <<EOF >> aws_hosts
[prod]
${aws_instance.prod.public_ip}
EOF
EOD
  }

  provisioner "local-exec" {
    command = "sleep 300 && ansible-playbook -i aws_hosts apache.yml"
  }
}
#----# jump machine

resource "aws_instance" "jump" {
  instance_type = var.all_instance_type
  ami           = var.all_ami

  tags = {
    Name = "jump instance"
  }

  key_name        = aws_key_pair.auth.id
  security_groups = [aws_security_group.employee_sg.name]

}

#----# CI machine

resource "aws_instance" "jenkins" {
  instance_type = var.all_instance_type
  ami           = var.all_ami

  tags = {
    Name = "jenkins instance"
  }

  key_name        = aws_key_pair.auth.id
  security_groups = [aws_security_group.employee_sg.name]


  provisioner "local-exec" {
    command = <<EOD
cat <<EOF >> aws_hosts
[jenkins]
${aws_instance.jenkins.public_ip}
EOF
EOD
  }

  provisioner "local-exec" {
    command = " sleep 300 && ansible-playbook -i aws_hosts jenkins.yml"
  }


  lifecycle {
    create_before_destroy = true
  }

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
output "jenkins_instance_public_dns" {
  value = aws_instance.jenkins.public_dns
}

output "jump_instance_public_ip" {
  value = aws_instance.jump.public_ip
}

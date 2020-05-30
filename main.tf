#----- Provider

provider "aws" {
  region                  = var.aws_region
  shared_credentials_file = var.aws_credentials
  profile                 = var.aws_profile
  version                 = "~> 2.61.0"
}

#----- VPC default data retrieved

data "aws_vpc" "default" {
  default = true
}

#----- eip associated to my jenkins

#resource "aws_eip" "default" {
#  instance = aws_instance.jenkins.id
#  vpc      = true
#}

#----- Security groups

resource "aws_security_group" "employee_sg" {
  name        = "employee_sg"
  description = "Used for access to aws instances"
  vpc_id      = data.aws_vpc.default.id

  #SSH

  ingress {
    from_port       = 22
    to_port         = 22
    protocol        = "tcp"
    security_groups = [aws_security_group.jump_sg.id]
  }
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = [data.aws_vpc.default.cidr_block]
  }


  #HTTP

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = [var.localip]
  }
  ingress {
    from_port   = 8080
    to_port     = 8080
    protocol    = "tcp"
    cidr_blocks = [var.localip]
  }

  #Outbound internet access

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
  egress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }


}

#----- Customer SG

resource "aws_security_group" "customer_sg" {
  name        = "customer_sg"
  description = "Used to allow customers to access prod and dev http"
  vpc_id      = data.aws_vpc.default.id

  #HTTP

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = [var.localip]
  }
}

#----- Jump SG

resource "aws_security_group" "jump_sg" {
  name        = "jump_sg"
  description = "sg for jumpBox"
  vpc_id      = data.aws_vpc.default.id
  # SSH

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = [var.localip]
  }


  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }




}

#----- key pair

resource "aws_key_pair" "auth" {
  key_name   = var.key_name
  public_key = file(var.public_key_path)
}

#----- dev machine

resource "aws_instance" "dev" {
  instance_type = var.all_instance_type
  ami           = var.all_ami

  tags = {
    Name = "dev instance"
  }

  key_name        = aws_key_pair.auth.id
  security_groups = [aws_security_group.employee_sg.name, aws_security_group.customer_sg.name]

  provisioner "local-exec" {
    command = <<EOD
cat <<EOF >> aws_hosts
[dev]
${aws_instance.dev.private_ip}
EOF
EOD
  }


}
#----- prod machine

resource "aws_instance" "prod" {
  instance_type = var.all_instance_type
  ami           = var.all_ami

  tags = {
    Name = "prod instance"
  }

  key_name        = aws_key_pair.auth.id
  security_groups = [aws_security_group.employee_sg.name, aws_security_group.customer_sg.name]


  provisioner "local-exec" {
    command = <<EOD
cat <<EOF >> aws_hosts
[prod]
${aws_instance.prod.private_ip}
EOF
EOD
  }

}
#----- jump machine

resource "aws_instance" "jump" {
  instance_type = var.all_instance_type
  ami           = var.all_ami

  tags = {
    Name = "jump instance"
  }

  key_name        = aws_key_pair.auth.id
  security_groups = [aws_security_group.jump_sg.name]
  #  provisioner "local-exec"{

  #	command = "sleep 300 && scp -i /root/.ssh/kryptonite /root/.ssh/kryptonite ec2-user@${aws_instance.jump.public_ip}:/home/ec2-user"

  #}

}


#----- CI machine

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
${aws_instance.jenkins.private_ip}
EOF
EOD
  }


  provisioner "local-exec" {
    command = " sleep 300 && ansible-playbook -i aws_hosts jenkins.yml"
  }
  lifecycle {
    prevent_destroy = true
  }

}



#----- machine dns outputs

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

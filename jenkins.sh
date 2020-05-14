#!/bin/bash
sudo yum -y update
#---- install http
sudo yum install -y httpd
sudo service httpd start
sudo service httpd enable
echo " Hello world " | sudo tee /var/www/html/index.html
#---- install jenkins 
yum install java-1.8.0-openjdk -y
curl --silent --location http://pkg.jenkins-ci.org/redhat-stable/jenkins.repo
sudo rpm --import https://jenkins-ci.org/redhat/jenkins-ci.org.key 
yum install jenkins -y
systemctl start jenkins
systemctl status jenkins
systemctl enable jenkins

#----- install ansible
sudo yum install epel_release -y
sudo yum install ansible -y
#---- install terraform
wget -O https://releases.hashicorp.com/terraform/0.12.25/terraform_0.12.25_linux_amd64.zip
sudo mkdir -p /bin/terraform 
sudo unzip terraform_0.12.25_linux_amd64.zip -d /bin/terraform



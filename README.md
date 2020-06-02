# Project Title

CI/CD pipeline - AWS - Jenkins - GitHub

Purpose: automate the provisioning, configuring, and deploying of an HTML web application

## Getting Started

This project is set 3 steps:

- Deployment: involving the deployment of resources (instances and security groups) on AWS using Terraform and the configuration of web servers machines and jenkins machine with Ansible

- Operations: involving the configuration of a jump host to allow ssh into other instances from employee pc or mac

- CD: involving the configuration of jekins pipelines for CD to dev and prod web servers based on code updates
    
### Prerequisites

Terraform (Deployment), Ansible (Configuration), Java jdk (jenkins requirement), Jenkins(CI), AWS account (Cloud Provider), Github account(Source Control Mgmt.)

## Deployment & Operations

- terraform uses main.tf to deploy all the resources needed to AWS. Resources such as: instances, security groups. We also called default data from AWS such as default VPC and eip. 

- terraform to be apply successfully also needs variables.tf for variables initialisation in main.tf and terraform.tfvars to provision values to these variables.

- ansible uses aws_hosts file as inventory hosts file and apache.yml, jenkins.yml playbooks to set up different instances environments on AWS.

- config file is used as agent forwading ssh on the employee machine to redirect ssh request through the jump host.\

## important commands
    #terraform init
    #terraform fmt
    #terraform validate 
    #terraform plan -lock=false
    #terraform apply -lock=false
    #terraform destroy -target aws_instance.<instance name> 
    
## Jenkins configuration

    On Jenkins, go to Manage Plugins and make sure or add the two plugins "SSH plugin" and "GitHub plugin".
    Go to Configure System and under SSH remote hosts, add in your SSH sites that your project will connect to.
    Go to credentials and set up credential username + ssh key path
    Add a new item and select the "pipeline".
    Under Source Code Management, add the Git repository and specify your branch.
    Under Build Triggers, select the GitHub hook trigger for GITScm polling.
    Under Build, add a build step and select Execute shell script on remote host using ssh, then select your SSH site and 
Save your job and go over to your GitHub repository and in settings add a webhook.
Make changes to the code and commit the changes to notify Jenkins to automatically run a build.


## Built With

* [Terraform](https://www.terraform.io/downloads.html)
* [Ansible](https://docs.ansible.com/ansible/latest/index.html)
* [jenkins](https://www.jenkins.io/)


# Project Title

CI/CD pipeline - AWS - Jenkins - GitHub

## Getting Started

This project is set 3 steps:

- Deployment: involving the deployment of resources (instances and security groups) on AWS using Terraform and the configuration of web servers machines and jenkins machine with Ansible

- Operations: involving the configuration of a jump host to allow ssh into other instances from employee pc or mac

- CD: involving the configuration of jekins pipelines for CD to dev and prod web servers based on code updates
    
### Prerequisites

Terraform (Deployment), Ansible (Configuration), Java jdk (jenkins required), Jenkins(CI), AWS account (Cloud Provider), Github account(Source Control Mgmt.), ~ 1 pc or mac (simulation) ~

## Deployment & Operations

- terraform uses main.tf to deploy all the resources needed to AWS. Resources such as: instances, security groups. We also called default data from AWS such as default VPC and eip. 

- terraform to be apply successfully also needs for variables initialisation in main.tf and terraform.tfvars to provision values to these variables.

- ansible uses aws_hosts file as inventory hosts file and apache.yml, jenkins.yml playbooks to set up different instances environments on AWS.

- config file is used as agent forwading ssh on the employee machine to redirect ssh request through the jump host.

## Built With

* [Terraform](https://www.terraform.io/downloads.html)
* [Ansible](https://docs.ansible.com/ansible/latest/index.html)
* [jenkins](https://www.jenkins.io/)


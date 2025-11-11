# CI-CD Pipeline for AWS Infrastructure Setup with Terraform and AWS EKS

This repository contains Terraform code to set up a Continuous Integration and Continuous Deployment (CI-CD) pipeline for AWS infrastructure, specifically focusing on deploying an Amazon EKS (Elastic Kubernetes Service) cluster. The pipeline automates the provisioning of necessary AWS resources, including EC2 instances, IAM roles, and EKS clusters, enabling efficient and repeatable deployments.

Technologies Used:

- Terraform: Infrastructure as Code (IaC) tool used to define and provision AWS resources.
- AWS EC2: Virtual servers in the cloud for running applications.
- AWS EKS: Managed Kubernetes service for running containerized applications.
- IAM Roles and Policies: For managing permissions and access to AWS resources.
- Jenkins: Automation server for building, deploying, and automating projects.
- Argo CD: Declarative GitOps continuous delivery tool for Kubernetes.
- Helm: Package manager for Kubernetes applications.
- DevSecOps Tools:
  - Trivy: Vulnerability scanner for containers and other artifacts.
  - SonarQube: Continuous inspection tool for code quality and security.
  - OWASP Dependency-Check: Tool for identifying project dependencies and checking if there are any known, publicly disclosed vulnerabilities.
  - Gmail API: For sending notifications and alerts.
- Prometheus and Grafana: Monitoring and visualization tools for Kubernetes clusters.

## Features- Automated provisioning of AWS infrastructure using Terraform.

- Firstly, created and IAM user and configured aws cli with access key and secret key.

```
aws configure
```

- Firstly created a VPC with public subnets.

```
resource "aws_vpc" "main" {
  cidr_block = var.vpc_cidr
  tags = {
    Name = "main-vpc"
  }
}

data "aws_availability_zones" "available" {}

resource "aws_subnet" "main" {
  count                   = 3
  vpc_id                  = aws_vpc.main.id
  cidr_block              = element(var.subnet_cidrs, count.index)
  availability_zone       = data.aws_availability_zones.available.names[count.index]
  map_public_ip_on_launch = true

  tags = {
    Name = "main-subnet-${count.index}"
  }
}
```

- Created an internet gateway for internet access to the instances in the public subnet.

```
resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name = "main-igw"
  }
}
```

- Created a route table and associated it with the public subnets to direct internet-bound traffic to the internet gateway.

```
resource "aws_route_table" "main" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }
  tags = {
    Name = "main-route-table"
  }
}

resource "aws_route_table_association" "a" {
  count          = length(aws_subnet.main)
  subnet_id      = aws_subnet.main[count.index].id
  route_table_id = aws_route_table.main.id
}
```

to be continued...

---

curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
sudo apt install unzip -y
unzip awscliv2.zip
sudo ./aws/install


curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl.sha256"
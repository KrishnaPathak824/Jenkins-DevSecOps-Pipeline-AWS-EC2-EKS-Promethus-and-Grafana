resource "aws_security_group" "jenkins-sg" {
  name        = "jenkins-sg"
  description = "Security group for Jenkins Master"
  vpc_id      = var.vpc_id

    ingress {
    from_port   = 8080
    to_port     = 8080
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    description = "Allow Jenkins web interface"
    }     
    ingress {
        from_port   = 22
        to_port     = 22
        protocol    = "tcp"
        cidr_blocks = ["0.0.0.0/0"]
        description = "Allow SSH access"
    }

    ingress {
        from_port   = 80
        to_port     = 80
        protocol    = "tcp"
        cidr_blocks = ["0.0.0.0/0"]
        description = "Allow HTTP access"
    }

    ingress {
        from_port   = 443
        to_port     = 443
        protocol    = "tcp"
        cidr_blocks = ["0.0.0.0/0"]
        description = "Allow HTTPS access"
    }

    ingress {
      from_port   = 30000
      to_port     = 32767
      protocol    = "tcp"
      cidr_blocks = ["0.0.0.0/0"]
      description = "Allow NodePort access"
    }

    ingress {
        from_port = 5432
        to_port   = 5432
        protocol  = "tcp"
        cidr_blocks = ["0.0.0.0/0"] 
        description = "Allow PostgreSQL access"
    }

    ingress {
        from_port = 465
        to_port   = 465
        protocol  = "tcp"
        cidr_blocks = ["0.0.0.0/0"]
        description = "Allow SMTP access"
    }

    ingress {
        from_port = 25
        to_port   = 25
        protocol  = "tcp"
        cidr_blocks = ["0.0.0.0/0"] 
        description = "Allow SMTP access"
    }

    ingress {
      from_port   = 3000
      to_port     = 3001
      protocol    = "tcp"
      cidr_blocks = ["0.0.0.0/0"]
      description = "Application specific port"
    }

    ingress {
      from_port   = 6443
      to_port     = 6443
      protocol    = "tcp"
      cidr_blocks = ["0.0.0.0/0"]
      description = "Kubernetes API server"
    }
    ingress{
      from_port   = 9000
      to_port     = 9000
      protocol    = "tcp"
      cidr_blocks = ["0.0.0.0/0"]
      description = "SonarQube"
    }

    egress {
        from_port   = 0
        to_port     = 0
        protocol    = "-1"
        cidr_blocks = ["0.0.0.0/0"]  
        description = "Allow all outbound traffic"
    }
}

resource "aws_key_pair" "jenkins-key" {
  key_name   = var.key_name
  public_key = file(var.public_key_path)
}

resource "aws_instance" "jenkins-master" {
  ami                         = var.ami_id
  instance_type               = var.instance_type
  key_name                    = var.key_name
  subnet_id                   = var.subnet_id
  vpc_security_group_ids      = [aws_security_group.jenkins-sg.id]
  associate_public_ip_address = true
  iam_instance_profile        = aws_iam_instance_profile.ec2_eks_access_instance_profile.name

  root_block_device {
    volume_size = 30
    volume_type = "gp3"
  }

  tags = {
    Name = "Jenkins-Master"
  }

  user_data = <<-EOF
              #!/bin/bash
              sudo apt update -y

              # Install Docker
              sudo apt install docker.io docker-compose -y
              sudo systemctl start docker
              sudo systemctl enable docker

              # Add ubuntu user to docker group
              sudo usermod -aG docker ubuntu
              newgrp docker

              # Install Jenkins
              sudo apt update -y
              sudo apt install fontconfig openjdk-21-jre -y

              # Add Jenkins repository and key
              sudo wget -O /etc/apt/keyrings/jenkins-keyring.asc \
                https://pkg.jenkins.io/debian-stable/jenkins.io-2023.key
              echo "deb [signed-by=/etc/apt/keyrings/jenkins-keyring.asc]" \
                https://pkg.jenkins.io/debian-stable binary/ | sudo tee \
                /etc/apt/sources.list.d/jenkins.list > /dev/null
              sudo apt update -y
              sudo apt install jenkins -y
              sudo systemctl enable jenkins
              sudo systemctl start jenkins

              # Install Trivy (security scanner)
              sudo apt-get install wget apt-transport-https gnupg lsb-release -y
              curl -fsSL https://aquasecurity.github.io/trivy-repo/deb/public.key | sudo tee /etc/apt/trusted.gpg.d/trivy.asc
              echo "deb https://aquasecurity.github.io/trivy-repo/deb $(lsb_release -sc) main" | sudo tee -a /etc/apt/sources.list.d/trivy.list

              # Update and install Trivy
              sudo apt-get update -y
              sudo apt-get install trivy -y

              # Run SonarQube container (for testing purposes)
              docker run -d --name sonar-test -p 9000:9000 sonarqube

              EOF
}

resource "aws_iam_role" "ec2_eks_access_role" {
    name = "ec2-eks-access-role"

    assume_role_policy = jsonencode({
        Version = "2012-10-17"
        Statement = [
            {
                Effect = "Allow"
                Principal = {
                    Service = "ec2.amazonaws.com"
                }
                Action = "sts:AssumeRole"
            },
        ]
    })
}

resource "aws_iam_policy" "ec2_eks_access_policy" {
    name        = "ec2-eks-access-policy"
    description = "Policy to allow EC2 instances to manage EKS cluster"

    policy = jsonencode({
        Version = "2012-10-17"
        Statement = [
            {
                Effect = "Allow"
                Action = [
                    "eks:DescribeCluster",
                    "eks:ListClusters",
                    "eks:AccessKubernetesApi"
                ]
                Resource = var.cluster_arn
            },
            {
                Effect = "Allow"
                Action = [
                    "sts:GetCallerIdentity"
                ]
                Resource = "*"
            }
        ]
    })
}

resource "aws_iam_role_policy_attachment" "ec2_eks_access_role_attachment" {
    role       = aws_iam_role.ec2_eks_access_role.name
    policy_arn = aws_iam_policy.ec2_eks_access_policy.arn
}

resource "aws_iam_instance_profile" "ec2_eks_access_instance_profile" {
    name = "ec2-eks-access-instance-profile"
    role = aws_iam_role.ec2_eks_access_role.name
}

resource "aws_eks_access_entry" "jenkins" {
  cluster_name      = var.cluster_name
  principal_arn     = aws_iam_role.ec2_eks_access_role.arn
  type              = "STANDARD"
}

resource "aws_eks_access_policy_association" "jenkins" {
  cluster_name       = var.cluster_name
  policy_arn         = "arn:aws:eks::aws:cluster-access-policy/AmazonEKSClusterAdminPolicy" 
  principal_arn      = aws_eks_access_entry.jenkins.principal_arn
  access_scope {
    type = "cluster"
  }
}
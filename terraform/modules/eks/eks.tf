resource "aws_iam_role" "eks_cluster_role" {
    name               = "eks-cluster-role"
    assume_role_policy = jsonencode({
        Version = "2012-10-17"
        Statement = [
            {
            Action = "sts:AssumeRole"
            Effect = "Allow"
            Principal = {
                Service = "eks.amazonaws.com"
            }
            },
        ]
    })
}

resource "aws_iam_role_policy_attachment" "eks_cluster_policy_attachment" {
    policy_arn = "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy"
    role       = aws_iam_role.eks_cluster_role.name
}

resource "aws_eks_cluster" "eks_cluster" {
    name     = var.cluster_name
    role_arn = aws_iam_role.eks_cluster_role.arn

    vpc_config {
        subnet_ids = var.subnet_ids
        endpoint_private_access = true
        endpoint_public_access  = true
    }

    access_config {
    authentication_mode = "API"
    }

    depends_on = [
        aws_iam_role_policy_attachment.eks_cluster_policy_attachment
    ]
}

resource "aws_iam_role" "eks_node_group_role" {
    name               = "eks-node-group-role"
    assume_role_policy = jsonencode({
        Version = "2012-10-17"
        Statement = [
            {
            Action = "sts:AssumeRole"
            Effect = "Allow"
            Principal = {
                Service = "ec2.amazonaws.com"
            }
            },
        ]
    })
}

resource "aws_iam_role_policy_attachment" "eks_worker_node_policy_attachment" {
    policy_arn = "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy"
    role       = aws_iam_role.eks_node_group_role.name
}

resource "aws_iam_role_policy_attachment" "eks_cni_policy_attachment" {
    policy_arn = "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy"
    role       = aws_iam_role.eks_node_group_role.name
}

resource "aws_iam_role_policy_attachment" "eks_ecr_readonly_attachment" {
  role       = aws_iam_role.eks_node_group_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
}

resource "aws_iam_role_policy_attachment" "eks_ebs_policy_attachment" {
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonEBSCSIDriverPolicy"
  role       = aws_iam_role.eks_node_group_role.name
}

resource "aws_eks_node_group" "eks_node_group" {
    cluster_name    = aws_eks_cluster.eks_cluster.name
    node_group_name = "${var.cluster_name}-node-group"
    node_role_arn   = aws_iam_role.eks_node_group_role.arn
    subnet_ids      = var.subnet_ids

    capacity_type = "ON_DEMAND"
    instance_types = [var.node_group_instance_type]

    remote_access {
        ec2_ssh_key = aws_key_pair.eks_key_pair.key_name
    }

    scaling_config {
        desired_size = var.node_group_desired_size
        max_size     = var.node_group_max_size
        min_size     = var.node_group_min_size
    }

    disk_size = var.node_group_disk_size

    depends_on = [
        aws_iam_role_policy_attachment.eks_worker_node_policy_attachment,
        aws_iam_role_policy_attachment.eks_cni_policy_attachment,
        aws_iam_role_policy_attachment.eks_ecr_readonly_attachment,
    ]
}

resource "aws_key_pair" "eks_key_pair" {
    key_name   = var.key_name_eks
    public_key = file(var.public_key_path_eks)
}

resource "aws_security_group" "eks_node_group_sg" {
    name        = "${var.cluster_name}-node-group-sg"
    description = "Security group for EKS worker nodes"
    vpc_id      = var.vpc_id

    ingress {
        from_port   = 22
        to_port     = 22
        protocol    = "tcp"
        cidr_blocks = ["0.0.0.0/0"]
        description = "Allow SSH access"
    }

    ingress {
        from_port   = 0
        to_port     = 65535
        protocol    = "tcp"
        self        = true
        description = "Allow node-to-node communication"
    }

    ingress {
        from_port       = 443
        to_port         = 443
        protocol        = "tcp"
        security_groups = [aws_eks_cluster.eks_cluster.vpc_config[0].cluster_security_group_id]
        description     = "Allow pods to communicate with cluster API"
    }

    ingress {
        from_port       = 1025
        to_port         = 65535
        protocol        = "tcp"
        security_groups = [aws_eks_cluster.eks_cluster.vpc_config[0].cluster_security_group_id]
        description     = "Allow worker Kubelets and pods to receive communication from the cluster control plane"
    }

    egress {
        from_port   = 0
        to_port     = 0
        protocol    = "-1"
        cidr_blocks = ["0.0.0.0/0"]
        description = "Allow all outbound traffic"
    }
}

resource "aws_eks_access_entry" "krishna_terraform" {
  cluster_name      = aws_eks_cluster.eks_cluster.name
  principal_arn     = "arn:aws:iam::713881821939:user/krishna-terraform"
  type              = "STANDARD"
}

resource "aws_eks_access_policy_association" "krishna_terraform" {
  cluster_name       = aws_eks_cluster.eks_cluster.name
  policy_arn         = "arn:aws:eks::aws:cluster-access-policy/AmazonEKSClusterAdminPolicy"
  principal_arn      = aws_eks_access_entry.krishna_terraform.principal_arn
  access_scope {
    type = "cluster"
  }
}

# Create OIDC provider for the cluster (if not exists)
resource "aws_iam_openid_connect_provider" "eks" {
  client_id_list  = ["sts.amazonaws.com"]
  thumbprint_list = [data.tls_certificate.eks.certificates[0].sha1_fingerprint]
  url             = aws_eks_cluster.eks_cluster.identity[0].oidc[0].issuer

  tags = {
    Name = "${var.cluster_name}-eks-oidc"
  }
}

# Get the TLS certificate from the EKS OIDC issuer
data "tls_certificate" "eks" {
  url = aws_eks_cluster.eks_cluster.identity[0].oidc[0].issuer
}

# IAM role for EBS CSI Driver with IRSA
resource "aws_iam_role" "ebs_csi_driver" {
  name = "${var.cluster_name}-ebs-csi-driver-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action = "sts:AssumeRoleWithWebIdentity"
      Effect = "Allow"
      Principal = {
        Federated = aws_iam_openid_connect_provider.eks.arn
      }
      Condition = {
        StringEquals = {
          "${replace(aws_iam_openid_connect_provider.eks.url, "https://", "")}:sub" = "system:serviceaccount:kube-system:ebs-csi-controller-sa"
          "${replace(aws_iam_openid_connect_provider.eks.url, "https://", "")}:aud" = "sts.amazonaws.com"
        }
      }
    }]
  })

  tags = {
    Name = "${var.cluster_name}-ebs-csi-driver-role"
  }
}

# Attach EBS CSI Driver policy to the IRSA role
resource "aws_iam_role_policy_attachment" "ebs_csi_driver" {
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonEBSCSIDriverPolicy"
  role       = aws_iam_role.ebs_csi_driver.name
}

# Install EBS CSI Driver as EKS addon
resource "aws_eks_addon" "ebs_csi_driver" {
  cluster_name             = aws_eks_cluster.eks_cluster.name
  addon_name               = "aws-ebs-csi-driver"
  addon_version            = "v1.37.0-eksbuild.1"
  service_account_role_arn = aws_iam_role.ebs_csi_driver.arn
  
  resolve_conflicts_on_create = "OVERWRITE"
  resolve_conflicts_on_update = "OVERWRITE"

  tags = {
    Name = "${var.cluster_name}-ebs-csi-driver"
  }

  depends_on = [
    aws_iam_role_policy_attachment.ebs_csi_driver,
    aws_iam_openid_connect_provider.eks
  ]
}

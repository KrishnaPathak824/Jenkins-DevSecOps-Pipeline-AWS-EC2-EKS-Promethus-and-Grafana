output "cluster_resource_arn" {
  value       = aws_eks_cluster.eks_cluster.arn
    description = "The ARN of the EKS cluster"
    sensitive   = true
}

output "cluster_name" {
  value       = aws_eks_cluster.eks_cluster.name
    description = "The name of the EKS cluster"
}

output "cluster_endpoint" {
  value       = aws_eks_cluster.eks_cluster.endpoint
    description = "The endpoint for the EKS cluster"
    sensitive   = true
}

output "cluster_certificate_authority" {
  value       = aws_eks_cluster.eks_cluster.certificate_authority[0].data
    description = "The base64 encoded certificate data required to communicate with the cluster"
    sensitive   = true
}
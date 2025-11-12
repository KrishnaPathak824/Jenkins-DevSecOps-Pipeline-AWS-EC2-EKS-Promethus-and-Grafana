output eks_cluster_endpoint {
  description = "The endpoint for the EKS cluster"
  value       = module.eks.cluster_endpoint
  depends_on  = [module.eks]
}

output eks_cluster_name {
  description = "The name of the EKS cluster"
  value       = module.eks.cluster_name
  depends_on  = [module.eks]
}

output ec2_instance_id {
  description = "The ID of the EC2 instance"
  value       = module.ec2.instance_id
  depends_on  = [module.ec2]
}



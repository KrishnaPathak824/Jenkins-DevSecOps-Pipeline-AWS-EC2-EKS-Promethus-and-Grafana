variable "cluster_name" {
    description = "The name of the EKS cluster"
    type        = string
    default     = "my-eks-cluster"
}

variable "subnet_ids" {
    description = "List of subnet IDs for the EKS cluster"
    type        = list(string)
}

variable "node_group_instance_type" {
    description = "The instance type for the EKS worker nodes"
    type        = string
    default     = "m7i-flex.large"
}

variable "node_group_desired_size" {
    description = "The desired number of worker nodes in the EKS node group"
    type        = number
    default     = 2
}

variable "node_group_min_size" {
    description = "The minimum number of worker nodes in the EKS node group"
    type        = number
    default     = 2
}

variable "node_group_max_size" {
    description = "The maximum number of worker nodes in the EKS node group"
    type        = number
    default     = 2
}

variable "vpc_id" {
    description = "The VPC ID where the EKS cluster will be deployed"
    type        = string
}

variable "key_name_eks" {
    description = "The name of the key pair to use for the EKS worker nodes"
    type        = string
    default     = "terraform-key"
}

variable "public_key_path_eks" {
    description = "The file path to the public key for the EKS worker nodes key pair"
    type        = string
    default     = "C:/Users/hp/Documents/CI-CD pipeline for AWS EKS Cluster/terraform-key.pub"
}

variable "node_group_disk_size" {
    description = "The disk size (in GB) for the EKS worker nodes"
    type        = number
    default     = 20
}

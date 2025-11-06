variable "ami_id" {
    description = "The AMI ID for the Jenkins Master instance"
    type        = string
    default = "ami-0360c520857e3138f"
}

variable "instance_type" {
    description = "The instance type for the Jenkins Master"
    type        = string
    default     = "c7i-flex.large"
}

variable "key_name" {
    description = "The name of the key pair to use for the Jenkins Master instance"
    type        = string
    default     = "my-key-pair"
}

variable "public_key_path" {
    description = "The file path to the public key for the key pair"
    type        = string
    default     = "C:/Users/hp/Documents/CI-CD pipeline for AWS EKS Cluster/terraform-key.pub"
}

variable "vpc_id" {
    description = "The VPC ID where the Jenkins Master will be deployed"
    type        = string
}

variable "subnet_id" {
    description = "The Subnet ID where the Jenkins Master will be deployed"
    type        = string
}



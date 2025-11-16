output "jenkins_ec2_role_arn" {
  value       = aws_iam_role.ec2_eks_access_role.arn
  sensitive   = true
  description = "ARN of the IAM role for Jenkins EC2 access"
}

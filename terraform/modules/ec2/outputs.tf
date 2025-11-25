output "jenkins_ec2_role_arn" {
  value       = aws_iam_role.ec2_eks_access_role.arn
  sensitive   = true
  description = "ARN of the IAM role for Jenkins EC2 access"
}

output "jenkins_ec2_instance_public_ip" {
  value       = aws_instance.jenkins-master.public_ip
  description = "Public IP address of the Jenkins EC2 instance"
}
output "jenkins_ec2_instance_public_ip" {
    value = module.ec2.jenkins_ec2_instance_public_ip
    description = "Public IP address of the Jenkins EC2 instance"
}
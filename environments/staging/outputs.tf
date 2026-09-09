output "vpc_id" {
  description = "ID of the Staging VPC"
  value       = module.vpc.vpc_id
}

output "public_subnet_id" {
  description = "ID of the Staging public subnet"
  value       = module.vpc.public_subnet_id
}

output "security_group_id" {
  description = "ID of the Staging security group"
  value       = module.security_group.security_group_id
}

output "instance_id" {
  description = "ID of the Staging EC2 instance"
  value       = module.ec2.instance_id
}

output "public_ip" {
  description = "Public IP of the Staging EC2 instance"
  value       = module.ec2.public_ip
}

output "public_dns" {
  description = "Public DNS of the Staging EC2 instance"
  value       = module.ec2.public_dns
}
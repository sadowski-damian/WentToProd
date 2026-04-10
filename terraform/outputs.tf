output "alb_dns_name" {
  description = "ALB dns name"
  value       = aws_lb.main_alb.dns_name
}

output "vpc_id" {
  description = "ID of our VPC"
  value       = aws_vpc.main.id
}

output "monitoring_private_ip" {
  description = "Monitoring instance - private IP"
  value       = aws_instance.ec2_monitoring_instance.private_ip
}


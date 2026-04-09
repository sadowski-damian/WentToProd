output "alb_dns_name" {
  description = "ALB dns name"
  value       = aws_lb.main_alb.dns_name
}

output "vpc_id" {
  description = "ID of our VPC"
  value       = aws_vpc.main.id
}

output "prometheus_private_ip" {
  description = "Prometheus instance - private IP"
  value       = aws_instance.ec2_prometheus_instance.private_ip
}


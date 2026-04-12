output "first_private_subnet_id" {
  description = "ID of our first private subnet"
  value       = aws_subnet.private_subnet[data.aws_availability_zones.available.names[0]].id
}

output "second_private_subnet_id" {
  description = "ID of our second private subnet"
  value       = aws_subnet.private_subnet[data.aws_availability_zones.available.names[1]].id
}

output "vpc_id" {
  description = "ID of our VPC"
  value       = aws_vpc.main.id
}
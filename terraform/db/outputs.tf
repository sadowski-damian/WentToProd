output "rds_address" {
  description = "Address of our RDS db"
  value       = aws_db_instance.rds_db_instance.address
}
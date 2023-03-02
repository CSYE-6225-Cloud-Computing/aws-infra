output "public_ip" {
  value = aws_instance.webapp.public_ip
}

output "rds_address" {
  value = aws_db_instance.csye6225.address
}
output "vpc_id" {
  description = "ID da VPC criada."
  value       = aws_vpc.main.id
}

output "public_subnets" {
  description = "IDs das subnets públicas."
  value       = aws_subnet.public[*].id
}

output "private_subnets" {
  description = "IDs das subnets privadas."
  value       = aws_subnet.private[*].id
}

output "public_instance_public_ips" {
  description = "IPs públicos das instâncias públicas (frontend/proxy)."
  value       = aws_instance.public[*].public_ip
}

output "public_instance_private_ips" {
  description = "IPs privados das instâncias públicas."
  value       = aws_instance.public[*].private_ip
}

output "private_instance_private_ips" {
  description = "IPs privados das instâncias privadas (backend)."
  value       = aws_instance.private[*].private_ip
}

output "db_endpoint" {
  description = "Endpoint do banco de dados RDS (MySQL)."
  value       = aws_db_instance.db.address
}

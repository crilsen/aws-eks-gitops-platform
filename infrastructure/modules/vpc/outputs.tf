output "vpc_id" {
  description = "Id of the created or adopted VPC."
  value       = local.vpc_id
}

output "vpc_cidr" {
  description = "CIDR block of the created VPC (null when adopting an existing VPC)."
  value       = var.create_vpc ? aws_vpc.this[0].cidr_block : null
}

output "public_subnet_ids" {
  description = "Ids of the public subnets, in the order of the provided CIDRs."
  value       = [for idx in sort(keys(aws_subnet.public)) : aws_subnet.public[idx].id]
}

output "private_subnet_ids" {
  description = "Ids of the private subnets, in the order of the provided CIDRs."
  value       = [for idx in sort(keys(aws_subnet.private)) : aws_subnet.private[idx].id]
}

output "internet_gateway_id" {
  description = "Id of the reused or created Internet Gateway."
  value       = local.igw_id
}

output "nat_gateway_id" {
  description = "Id of the reused or created NAT Gateway (null when none)."
  value       = local.nat_id
}

output "public_route_table_id" {
  description = "Id of the always-created public route table."
  value       = aws_route_table.public.id
}

output "private_route_table_id" {
  description = "Id of the always-created private route table."
  value       = aws_route_table.private.id
}

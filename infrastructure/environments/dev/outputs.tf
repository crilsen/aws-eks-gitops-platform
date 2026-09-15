output "vpc_id" {
  description = "Adopted VPC id."
  value       = module.vpc.vpc_id
}

output "public_subnet_ids" {
  description = "Ids of the created public subnets."
  value       = module.vpc.public_subnet_ids
}

output "private_subnet_ids" {
  description = "Ids of the created private subnets."
  value       = module.vpc.private_subnet_ids
}

output "internet_gateway_id" {
  description = "Reused Internet Gateway id."
  value       = module.vpc.internet_gateway_id
}

output "nat_gateway_id" {
  description = "Reused NAT Gateway id."
  value       = module.vpc.nat_gateway_id
}

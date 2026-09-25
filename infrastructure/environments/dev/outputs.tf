output "vpc_id" {
  description = "Created VPC id."
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

output "cluster_name" {
  description = "Shared EKS cluster name."
  value       = module.eks.cluster_name
}

output "cluster_endpoint" {
  description = "Shared EKS cluster API endpoint."
  value       = module.eks.cluster_endpoint
}

output "cluster_version" {
  description = "Shared EKS cluster Kubernetes version."
  value       = module.eks.cluster_version
}

output "node_role_arn" {
  description = "IAM role ARN assumed by the managed nodes."
  value       = module.eks.node_role_arn
}

output "alb_controller_role_arn" {
  description = "IAM role ARN used by the AWS Load Balancer Controller (IRSA)."
  value       = module.iam.alb_controller_role_arn
}

output "acm_certificate_arn" {
  description = "ARN of the imported application TLS certificate in ACM (null when disabled)."
  value       = try(aws_acm_certificate.app[0].arn, null)
}

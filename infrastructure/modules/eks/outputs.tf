output "cluster_name" {
  description = "Name of the EKS cluster."
  value       = aws_eks_cluster.this.name
}

output "cluster_version" {
  description = "Kubernetes version of the cluster."
  value       = aws_eks_cluster.this.version
}

output "cluster_endpoint" {
  description = "API server endpoint."
  value       = aws_eks_cluster.this.endpoint
}

output "cluster_certificate_authority_data" {
  description = "Base64 certificate authority data for the cluster."
  value       = aws_eks_cluster.this.certificate_authority[0].data
}

output "cluster_iam_role_arn" {
  description = "IAM role ARN of the cluster."
  value       = aws_iam_role.cluster.arn
}

output "cluster_security_group_id" {
  description = "Security group id of the EKS cluster."
  value       = aws_security_group.cluster.id
}

output "node_role_arn" {
  description = "IAM role ARN assumed by the managed nodes."
  value       = aws_iam_role.node.arn
}

output "node_security_group_id" {
  description = "Security group id of the managed nodes."
  value       = aws_security_group.node.id
}

output "node_group_name" {
  description = "Name of the managed node group."
  value       = aws_eks_node_group.this.node_group_name
}

output "alb_security_group_id" {
  description = "Security group id for the application ALB."
  value       = aws_security_group.alb.id
}

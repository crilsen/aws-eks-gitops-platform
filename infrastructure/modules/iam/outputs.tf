output "alb_controller_role_arn" {
  description = "ARN of the AWS Load Balancer Controller role."
  value       = aws_iam_role.alb_controller.arn
}

output "alb_controller_policy_arn" {
  description = "ARN of the AWS Load Balancer Controller policy."
  value       = aws_iam_policy.alb_controller.arn
}

output "alb_controller_pod_identity_association_id" {
  description = "Id of the Pod Identity association (null when disabled)."
  value       = try(aws_eks_pod_identity_association.alb_controller[0].association_id, null)
}

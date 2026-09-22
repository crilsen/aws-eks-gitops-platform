variable "name" {
  description = "Name prefix for the IAM role and policy."
  type        = string
}

variable "tags" {
  description = "Tags applied to the created resources."
  type        = map(string)
  default     = {}
}

variable "cluster_name" {
  description = "EKS cluster name (used in Pod Identity association if enabled)."
  type        = string
  default     = ""
}

variable "namespace" {
  description = "Namespace of the AWS Load Balancer Controller service account."
  type        = string
  default     = "kube-system"
}

variable "service_account" {
  description = "Service account used by the AWS Load Balancer Controller."
  type        = string
  default     = "aws-load-balancer-controller"
}

variable "oidc_provider_arn" {
  description = "ARN of the OIDC provider for the EKS cluster (IRSA)."
  type        = string
  default     = ""
}

variable "oidc_provider_url" {
  description = "URL of the OIDC issuer (without https:// prefix) for IRSA trust."
  type        = string
  default     = ""
}

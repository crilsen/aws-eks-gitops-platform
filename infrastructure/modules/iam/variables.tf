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
  description = "EKS cluster name for the Pod Identity association."
  type        = string
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

variable "create_pod_identity_association" {
  description = "Create the EKS Pod Identity association for the controller service account."
  type        = bool
  default     = true
}

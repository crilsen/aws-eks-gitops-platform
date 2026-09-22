variable "name" {
  description = "EKS cluster name (shared across environments)."
  type        = string
}

variable "tags" {
  description = "Tags applied to every taggable resource."
  type        = map(string)
  default     = {}
}

variable "cluster_version" {
  description = "Kubernetes version for the EKS cluster."
  type        = string
  default     = "1.36"
}

variable "vpc_id" {
  description = "VPC id where the cluster is created."
  type        = string
}

variable "subnet_ids" {
  description = "Subnet ids for the EKS control plane (at least two AZs)."
  type        = list(string)

  validation {
    condition     = length(var.subnet_ids) >= 2
    error_message = "EKS requires at least two subnets in different availability zones."
  }
}

variable "node_subnet_ids" {
  description = "Subnet ids for the managed node group. Defaults to subnet_ids."
  type        = list(string)
  default     = []
}

variable "endpoint_private_access" {
  description = "Enable private access to the cluster API endpoint."
  type        = bool
  default     = true
}

variable "endpoint_public_access" {
  description = "Enable public access to the cluster API endpoint."
  type        = bool
  default     = true
}

variable "public_access_cidrs" {
  description = "CIDRs allowed to reach the public endpoint. Restrict to trusted addresses."
  type        = list(string)
  default     = ["0.0.0.0/0"]
}

variable "node_instance_types" {
  description = "Instance types for the managed node group."
  type        = list(string)
  default     = ["t3.small"]
}

variable "node_capacity_type" {
  description = "Capacity type for the node group (ON_DEMAND or SPOT)."
  type        = string
  default     = "ON_DEMAND"
}

variable "node_desired_size" {
  description = "Desired node count."
  type        = number
  default     = 1
}

variable "node_min_size" {
  description = "Minimum node count."
  type        = number
  default     = 1
}

variable "node_max_size" {
  description = "Maximum node count."
  type        = number
  default     = 2
}

variable "cluster_enabled_log_types" {
  description = "Control-plane log types to enable. Keep empty to avoid CloudWatch cost."
  type        = list(string)
  default     = []
}

variable "addons" {
  description = "Managed add-ons to install with the latest compatible version. vpc-cni, kube-proxy, and coredns are bootstrapped automatically."
  type        = list(string)
  default     = ["eks-pod-identity-agent"]
}

variable "app_port" {
  description = "Port exposed by the application and targeted by the ALB."
  type        = number
  default     = 8000
}

variable "aws_region" {
  description = "AWS region for the environment."
  type        = string
  default     = "us-east-1"
}

variable "owner" {
  description = "Value of the Owner tag."
  type        = string
  default     = "Cristiano"
}

# Adopted network — supplied privately (terraform.tfvars), never versioned.

variable "vpc_id" {
  description = "Existing VPC id to adopt."
  type        = string
}

variable "internet_gateway_id" {
  description = "Existing Internet Gateway id to reuse."
  type        = string
}

variable "nat_gateway_id" {
  description = "Existing NAT Gateway id to reuse for private egress."
  type        = string
}

variable "azs" {
  description = "Availability zones used for the subnets."
  type        = list(string)
  default     = ["us-east-1a", "us-east-1b"]
}

variable "public_subnet_cidrs" {
  description = "CIDR blocks for the public subnets (one per AZ)."
  type        = list(string)
  default     = ["10.11.21.0/24", "10.11.22.0/24"]
}

variable "private_subnet_cidrs" {
  description = "CIDR blocks for the private subnets (one per AZ)."
  type        = list(string)
  default     = ["10.11.23.0/24", "10.11.24.0/24"]
}

variable "cluster_version" {
  description = "EKS Kubernetes version."
  type        = string
  default     = "1.36"
}

variable "public_access_cidrs" {
  description = "CIDRs allowed to reach the Kubernetes API public endpoint. Restrict to trusted addresses where possible."
  type        = list(string)
  default     = ["0.0.0.0/0"]
}

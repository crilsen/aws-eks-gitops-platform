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

# VPC — create or adopt.

variable "create_vpc" {
  description = "Create a new VPC. When false, vpc_id must be provided."
  type        = bool
  default     = true
}

variable "vpc_id" {
  description = "Existing VPC id to adopt when create_vpc is false."
  type        = string
  default     = null
}

variable "vpc_cidr" {
  description = "CIDR block for the VPC when create_vpc is true."
  type        = string
  default     = "10.12.0.0/16"
}

variable "azs" {
  description = "Availability zones used for the subnets."
  type        = list(string)
  default     = ["us-east-1a", "us-east-1b"]
}

variable "public_subnet_cidrs" {
  description = "CIDR blocks for the public subnets (one per AZ)."
  type        = list(string)
  default     = ["10.12.21.0/24", "10.12.22.0/24"]
}

variable "private_subnet_cidrs" {
  description = "CIDR blocks for the private subnets (one per AZ)."
  type        = list(string)
  default     = ["10.12.23.0/24", "10.12.24.0/24"]
}

# Internet Gateway — create or adopt.

variable "create_igw" {
  description = "Create an Internet Gateway when no internet_gateway_id is supplied."
  type        = bool
  default     = true
}

variable "internet_gateway_id" {
  description = "Existing Internet Gateway id to reuse."
  type        = string
  default     = null
}

# NAT Gateway — create or adopt.

variable "enable_nat_gateway" {
  description = "Create a NAT Gateway when no nat_gateway_id is supplied."
  type        = bool
  default     = true
}

variable "nat_gateway_id" {
  description = "Existing NAT Gateway id to reuse."
  type        = string
  default     = null
}

# EKS — shared cluster.

variable "cluster_version" {
  description = "EKS Kubernetes version."
  type        = string
  default     = "1.36"
}

variable "public_access_cidrs" {
  description = "CIDRs allowed to reach the Kubernetes API public endpoint. Required; set your own IPs in terraform.tfvars (e.g. [\"203.0.113.10/32\"])."
  type        = list(string)

  validation {
    condition     = length(var.public_access_cidrs) > 0 && !contains(var.public_access_cidrs, "0.0.0.0/0")
    error_message = "Set at least one specific CIDR; do not use 0.0.0.0/0 for the public API endpoint."
  }
}

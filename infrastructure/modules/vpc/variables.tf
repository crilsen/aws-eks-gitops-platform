variable "name" {
  description = "Name prefix applied to every created resource."
  type        = string
}

variable "tags" {
  description = "Tags applied to every taggable resource."
  type        = map(string)
  default     = {}
}

variable "create_vpc" {
  description = "Create a new VPC. When false, an existing vpc_id must be provided."
  type        = bool
  default     = false
}

variable "vpc_id" {
  description = "Existing VPC id to adopt when create_vpc is false."
  type        = string
  default     = null
}

variable "vpc_cidr" {
  description = "CIDR block for the VPC when create_vpc is true."
  type        = string
  default     = "10.11.0.0/16"
}

variable "azs" {
  description = "Availability zones used to spread the subnets. EKS and the ALB need at least two."
  type        = list(string)

  validation {
    condition     = length(var.azs) >= 2
    error_message = "At least two availability zones are required for EKS and the ALB."
  }
}

variable "public_subnet_cidrs" {
  description = "CIDR blocks for the public subnets, one per availability zone (in order)."
  type        = list(string)
  default     = []
}

variable "private_subnet_cidrs" {
  description = "CIDR blocks for the private subnets, one per availability zone (in order)."
  type        = list(string)
  default     = []
}

variable "map_public_ip_on_launch" {
  description = "Assign public IPs to instances launched in the public subnets."
  type        = bool
  default     = true
}

variable "create_igw" {
  description = "Create an Internet Gateway when no internet_gateway_id is supplied."
  type        = bool
  default     = true
}

variable "internet_gateway_id" {
  description = "Existing Internet Gateway id to reuse instead of creating one."
  type        = string
  default     = null
}

variable "enable_nat_gateway" {
  description = "Create a NAT Gateway when no nat_gateway_id is supplied. Disabled by default to avoid cost."
  type        = bool
  default     = false
}

variable "nat_gateway_id" {
  description = "Existing NAT Gateway id to reuse for private-subnet egress."
  type        = string
  default     = null
}

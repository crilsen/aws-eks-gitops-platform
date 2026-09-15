locals {
  environment = "dev"

  tags = {
    Project     = "aws-eks-gitops-platform"
    Environment = local.environment
    Owner       = var.owner
    ManagedBy   = "Terraform"
    AutoDelete  = "true"
  }
}

module "vpc" {
  source = "../../modules/vpc"

  name = "aws-eks-gitops-platform-${local.environment}"
  tags = local.tags

  create_vpc = false
  vpc_id     = var.vpc_id

  azs                  = var.azs
  public_subnet_cidrs  = var.public_subnet_cidrs
  private_subnet_cidrs = var.private_subnet_cidrs

  internet_gateway_id = var.internet_gateway_id
  nat_gateway_id      = var.nat_gateway_id
}

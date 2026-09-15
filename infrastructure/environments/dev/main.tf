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

# Shared EKS cluster (ADR-022): one cluster, `dev` and `prd` are namespaces.
module "eks" {
  source = "../../modules/eks"

  name = "aws-eks-gitops-platform"
  tags = local.tags

  cluster_version = var.cluster_version

  vpc_id     = module.vpc.vpc_id
  subnet_ids = module.vpc.private_subnet_ids

  node_subnet_ids = module.vpc.private_subnet_ids

  node_instance_types = ["t3.small"]
  node_desired_size   = 1
  node_min_size       = 1
  node_max_size       = 2

  public_access_cidrs = var.public_access_cidrs
}

# AWS Load Balancer Controller identity via EKS Pod Identity (ADR-011).
module "iam" {
  source = "../../modules/iam"

  name = "aws-eks-gitops-platform"
  tags = local.tags

  cluster_name = module.eks.cluster_name
}

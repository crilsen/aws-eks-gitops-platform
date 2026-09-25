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

  create_vpc = var.create_vpc
  vpc_id     = var.vpc_id
  vpc_cidr   = var.vpc_cidr

  create_igw = var.create_igw

  enable_nat_gateway = var.enable_nat_gateway

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
  node_desired_size   = 2
  node_min_size       = 1
  node_max_size       = 3

  public_access_cidrs = var.public_access_cidrs
}

# OIDC provider for IRSA (ADR-011).
data "tls_certificate" "cluster" {
  url = module.eks.cluster_oidc_issuer_url
}

resource "aws_iam_openid_connect_provider" "cluster" {
  client_id_list  = ["sts.amazonaws.com"]
  thumbprint_list = [data.tls_certificate.cluster.certificates[0].sha1_fingerprint]
  url             = module.eks.cluster_oidc_issuer_url

  tags = local.tags
}

# AWS Load Balancer Controller identity via IRSA (ADR-011).
module "iam" {
  source = "../../modules/iam"

  name = "aws-eks-gitops-platform"
  tags = local.tags

  oidc_provider_arn = aws_iam_openid_connect_provider.cluster.arn
  oidc_provider_url = module.eks.cluster_oidc_issuer_url
}

# Application TLS certificate imported into ACM (ADR-024).
# The ALB discovers it automatically by hostname (certificate discovery),
# so no certificate ARN is committed in the GitOps values.
locals {
  acm_fullchain_raw = try(file(var.acm_fullchain_path), "")
  acm_pem_blocks    = [for b in split("-----END CERTIFICATE-----", trimspace(local.acm_fullchain_raw)) : trimspace(b) if trimspace(b) != ""]
  acm_pem_certs     = [for b in local.acm_pem_blocks : "${b}\n-----END CERTIFICATE-----\n"]
}

resource "terraform_data" "acm_inputs" {
  count = var.enable_acm_certificate ? 1 : 0

  lifecycle {
    precondition {
      condition     = fileexists(var.acm_fullchain_path)
      error_message = "ACM full-chain file not found. Place fullchain.pem in cert/ (gitignored) or set acm_fullchain_path."
    }
    precondition {
      condition     = fileexists(var.acm_private_key_path)
      error_message = "ACM private key file not found. Place privkey.pem in cert/ (gitignored) or set acm_private_key_path."
    }
    precondition {
      condition     = length(local.acm_pem_certs) >= 1
      error_message = "ACM full-chain file contains no PEM certificates."
    }
  }
}

resource "aws_acm_certificate" "app" {
  count             = var.enable_acm_certificate ? 1 : 0
  private_key       = try(file(var.acm_private_key_path), null)
  certificate_body  = try(local.acm_pem_certs[0], null)
  certificate_chain = length(local.acm_pem_certs) > 1 ? join("", slice(local.acm_pem_certs, 1, length(local.acm_pem_certs))) : null

  lifecycle {
    create_before_destroy = true
  }

  tags = merge(local.tags, { Name = "aws-eks-gitops-platform-${local.environment}-app" })
}

# Render the ALB controller ArgoCD Application with the role ARN (IaC-managed).
resource "local_file" "alb_controller_app" {
  filename = abspath("${path.module}/../../../gitops/applications/platform/aws-load-balancer-controller.yaml")
  content = templatefile("${path.module}/templates/alb-controller-app.yaml.tftpl", {
    role_arn = module.iam.alb_controller_role_arn
  })

  file_permission = "0644"
}

# Pin each environment's ALB to the dedicated security group (ADR-025).
# Separate override files so CI-owned image.tag values are never touched.
resource "local_file" "alb_sg_values" {
  for_each = toset(["dev", "prd"])

  filename = abspath("${path.module}/../../../gitops/environments/${each.value}/alb-sg.yaml")
  content = templatefile("${path.module}/templates/alb-sg-values.yaml.tftpl", {
    alb_security_group_id = module.eks.alb_security_group_id
  })

  file_permission = "0644"
}

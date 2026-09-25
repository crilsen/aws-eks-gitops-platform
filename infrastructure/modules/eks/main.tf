locals {
  node_subnet_ids = length(var.node_subnet_ids) > 0 ? var.node_subnet_ids : var.subnet_ids
  addons          = toset(var.addons)
}

data "aws_eks_addon_version" "this" {
  for_each           = local.addons
  addon_name         = each.value
  kubernetes_version = aws_eks_cluster.this.version
  most_recent        = true
}

# --- Cluster IAM role ---

resource "aws_iam_role" "cluster" {
  name = "${var.name}-eks-cluster"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect    = "Allow"
      Principal = { Service = "eks.amazonaws.com" }
      Action    = "sts:AssumeRole"
    }]
  })
  tags = merge(var.tags, { Name = "${var.name}-eks-cluster-role" })
}

resource "aws_iam_role_policy_attachment" "cluster" {
  role       = aws_iam_role.cluster.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy"
}

# --- EKS cluster (EKS manages its own SGs) ---

resource "aws_eks_cluster" "this" {
  name                          = var.name
  version                       = var.cluster_version
  role_arn                      = aws_iam_role.cluster.arn
  bootstrap_self_managed_addons = true

  vpc_config {
    subnet_ids              = var.subnet_ids
    endpoint_private_access = var.endpoint_private_access
    endpoint_public_access  = var.endpoint_public_access
    public_access_cidrs     = var.endpoint_public_access ? var.public_access_cidrs : null
    security_group_ids      = [aws_security_group.cluster.id]
  }

  access_config {
    authentication_mode = "API_AND_CONFIG_MAP"
  }

  enabled_cluster_log_types = var.cluster_enabled_log_types
  tags                      = merge(var.tags, { Name = "${var.name}-eks-cluster" })

  depends_on = [aws_iam_role_policy_attachment.cluster]
}

# --- Node IAM role ---

resource "aws_iam_role" "node" {
  name = "${var.name}-eks-node"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect    = "Allow"
      Principal = { Service = "ec2.amazonaws.com" }
      Action    = "sts:AssumeRole"
    }]
  })
  tags = merge(var.tags, { Name = "${var.name}-eks-node-role" })
}

resource "aws_iam_role_policy_attachment" "node" {
  for_each = toset([
    "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy",
    "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy",
    "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly",
  ])
  role       = aws_iam_role.node.name
  policy_arn = each.value
}

# --- Dedicated security groups (ADR-025) ---
# Least-privilege and additive: the EKS-managed SG keeps owning cluster/node
# traffic, so these SGs only open what each resource strictly needs.

resource "aws_security_group" "alb" {
  name        = "${var.name}-alb"
  description = "Dedicated SG for the application ALB (internet-facing)."
  vpc_id      = var.vpc_id

  tags = merge(var.tags, { Name = "${var.name}-alb-sg" })
}

resource "aws_security_group_rule" "alb_ingress_http" {
  type              = "ingress"
  from_port         = 80
  to_port           = 80
  protocol          = "tcp"
  security_group_id = aws_security_group.alb.id
  cidr_blocks       = ["0.0.0.0/0"]
  description       = "Allow HTTP from the internet."
}

resource "aws_security_group_rule" "alb_ingress_https" {
  type              = "ingress"
  from_port         = 443
  to_port           = 443
  protocol          = "tcp"
  security_group_id = aws_security_group.alb.id
  cidr_blocks       = ["0.0.0.0/0"]
  description       = "Allow HTTPS from the internet."
}

resource "aws_security_group_rule" "alb_egress_app" {
  type                     = "egress"
  from_port                = var.app_port
  to_port                  = var.app_port
  protocol                 = "tcp"
  security_group_id        = aws_security_group.alb.id
  source_security_group_id = aws_security_group.node.id
  description              = "Allow app traffic and health checks to the nodes."
}

resource "aws_security_group" "node" {
  name        = "${var.name}-node"
  description = "Dedicated SG for the EKS managed nodes (additive to the EKS-managed SG)."
  vpc_id      = var.vpc_id

  tags = merge(var.tags, { Name = "${var.name}-node-sg" })
}

resource "aws_security_group_rule" "node_ingress_app" {
  type                     = "ingress"
  from_port                = var.app_port
  to_port                  = var.app_port
  protocol                 = "tcp"
  security_group_id        = aws_security_group.node.id
  source_security_group_id = aws_security_group.alb.id
  description              = "Allow app traffic from the ALB only."
}

resource "aws_security_group_rule" "node_ingress_api" {
  type                     = "ingress"
  from_port                = 443
  to_port                  = 443
  protocol                 = "tcp"
  security_group_id        = aws_security_group.node.id
  source_security_group_id = aws_eks_cluster.this.vpc_config[0].cluster_security_group_id
  description              = "Allow control-plane HTTPS to the nodes."
}

# No egress rules here on purpose: outbound is covered by the EKS-managed SG
# attached to the same instances. This SG only restricts ingress.

resource "aws_security_group" "cluster" {
  name        = "${var.name}-cluster"
  description = "Dedicated SG for the EKS control plane (additive to the EKS-managed SG)."
  vpc_id      = var.vpc_id

  tags = merge(var.tags, { Name = "${var.name}-cluster-sg" })
}

resource "aws_security_group_rule" "cluster_ingress_api" {
  type                     = "ingress"
  from_port                = 443
  to_port                  = 443
  protocol                 = "tcp"
  security_group_id        = aws_security_group.cluster.id
  source_security_group_id = aws_eks_cluster.this.vpc_config[0].cluster_security_group_id
  description              = "Allow API traffic from cluster workloads."
}

resource "aws_security_group_rule" "cluster_egress_kubelet" {
  type                     = "egress"
  from_port                = 10250
  to_port                  = 10250
  protocol                 = "tcp"
  security_group_id        = aws_security_group.cluster.id
  source_security_group_id = aws_eks_cluster.this.vpc_config[0].cluster_security_group_id
  description              = "Allow control-plane to kubelet."
}

resource "aws_security_group_rule" "cluster_egress_api" {
  type                     = "egress"
  from_port                = 443
  to_port                  = 443
  protocol                 = "tcp"
  security_group_id        = aws_security_group.cluster.id
  source_security_group_id = aws_eks_cluster.this.vpc_config[0].cluster_security_group_id
  description              = "Allow control-plane HTTPS to workloads."
}

# --- Launch template (IMDS hop limit 2 for IRSA + tags) ---

resource "aws_launch_template" "node" {
  name_prefix = "${var.name}-node-"

  # Both SGs explicit: EKS does not reliably re-attach its managed SG when a
  # custom launch template sets its own list, and without it new nodes get no
  # egress and never join (NodeCreationFailure).
  vpc_security_group_ids = [
    aws_security_group.node.id,
    aws_eks_cluster.this.vpc_config[0].cluster_security_group_id,
  ]

  metadata_options {
    http_endpoint               = "enabled"
    http_tokens                 = "required"
    http_put_response_hop_limit = 2
  }

  tag_specifications {
    resource_type = "instance"
    tags          = merge(var.tags, { Name = "${var.name}-node" })
  }

  tag_specifications {
    resource_type = "volume"
    tags          = merge(var.tags, { Name = "${var.name}-node-volume" })
  }

  tags = merge(var.tags, { Name = "${var.name}-node-lt" })

  lifecycle { create_before_destroy = true }
}

# --- Node group ---

resource "aws_eks_node_group" "this" {
  cluster_name    = aws_eks_cluster.this.name
  node_group_name = "${var.name}-default"
  node_role_arn   = aws_iam_role.node.arn
  subnet_ids      = local.node_subnet_ids
  capacity_type   = var.node_capacity_type
  instance_types  = var.node_instance_types

  launch_template {
    id      = aws_launch_template.node.id
    version = aws_launch_template.node.latest_version
  }

  scaling_config {
    desired_size = var.node_desired_size
    min_size     = var.node_min_size
    max_size     = var.node_max_size
  }

  update_config { max_unavailable = 1 }
  tags       = merge(var.tags, { Name = "${var.name}-node-group" })
  depends_on = [aws_iam_role_policy_attachment.node]
}

# --- Add-ons ---

resource "aws_eks_addon" "this" {
  for_each                    = local.addons
  cluster_name                = aws_eks_cluster.this.name
  addon_name                  = each.value
  addon_version               = data.aws_eks_addon_version.this[each.key].version
  resolve_conflicts_on_create = "OVERWRITE"
  resolve_conflicts_on_update = "PRESERVE"
  tags                        = merge(var.tags, { Name = "${var.name}-addon-${each.value}" })
  depends_on                  = [aws_eks_node_group.this]
}

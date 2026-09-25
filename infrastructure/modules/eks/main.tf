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

# --- Launch template (IMDS hop limit 2 for IRSA + tags) ---

resource "aws_launch_template" "node" {
  name_prefix = "${var.name}-node-"

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

locals {
  node_subnet_ids = length(var.node_subnet_ids) > 0 ? var.node_subnet_ids : var.subnet_ids
  addons          = toset(var.addons)
}

data "aws_eks_addon_version" "this" {
  for_each = local.addons

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

# --- Cluster security group ---

resource "aws_security_group" "cluster" {
  name        = "${var.name}-eks-cluster"
  description = "Security group for EKS cluster control plane"
  vpc_id      = var.vpc_id

  tags = merge(var.tags, {
    Name = "${var.name}-eks-cluster-sg"
  })
}

resource "aws_security_group_rule" "cluster_ingress_from_nodes" {
  type                     = "ingress"
  from_port                = 443
  to_port                  = 443
  protocol                 = "tcp"
  security_group_id        = aws_security_group.cluster.id
  source_security_group_id = aws_security_group.node.id
  description              = "Allow HTTPS from nodes to control plane (kubelet)"
}

resource "aws_security_group_rule" "cluster_egress_all" {
  type              = "egress"
  from_port         = 0
  to_port           = 0
  protocol          = "-1"
  security_group_id = aws_security_group.cluster.id
  cidr_blocks       = ["0.0.0.0/0"]
  description       = "Allow all outbound from control plane"
}

# --- Node security group ---

resource "aws_security_group" "node" {
  name        = "${var.name}-eks-node"
  description = "Security group for EKS managed nodes"
  vpc_id      = var.vpc_id

  tags = merge(var.tags, {
    Name = "${var.name}-eks-node-sg"
  })
}

resource "aws_security_group_rule" "node_ingress_self" {
  type              = "ingress"
  from_port         = 0
  to_port           = 0
  protocol          = "-1"
  security_group_id = aws_security_group.node.id
  source_security_group_id = aws_security_group.node.id
  description       = "Allow all traffic between nodes"
}

resource "aws_security_group_rule" "node_ingress_from_cluster" {
  type                     = "ingress"
  from_port                = 443
  to_port                  = 443
  protocol                 = "tcp"
  security_group_id        = aws_security_group.node.id
  source_security_group_id = aws_security_group.cluster.id
  description              = "Allow HTTPS from control plane to nodes (kubelet)"
}

resource "aws_security_group_rule" "node_ingress_from_alb" {
  type                     = "ingress"
  from_port                = var.app_port
  to_port                  = var.app_port
  protocol                 = "tcp"
  security_group_id        = aws_security_group.node.id
  source_security_group_id = aws_security_group.alb.id
  description              = "Allow application traffic from ALB"
}

resource "aws_security_group_rule" "node_egress_all" {
  type              = "egress"
  from_port         = 0
  to_port           = 0
  protocol          = "-1"
  security_group_id = aws_security_group.node.id
  cidr_blocks       = ["0.0.0.0/0"]
  description       = "Allow all outbound (image pulls, GitHub, GHCR)"
}

# --- ALB security group ---

resource "aws_security_group" "alb" {
  name        = "${var.name}-alb"
  description = "Security group for the application ALB"
  vpc_id      = var.vpc_id

  tags = merge(var.tags, {
    Name = "${var.name}-alb-sg"
  })
}

resource "aws_security_group_rule" "alb_ingress_http" {
  type              = "ingress"
  from_port         = 80
  to_port           = 80
  protocol          = "tcp"
  security_group_id = aws_security_group.alb.id
  cidr_blocks       = ["0.0.0.0/0"]
  description       = "Allow HTTP from internet"
}

resource "aws_security_group_rule" "alb_ingress_https" {
  type              = "ingress"
  from_port         = 443
  to_port           = 443
  protocol          = "tcp"
  security_group_id = aws_security_group.alb.id
  cidr_blocks       = ["0.0.0.0/0"]
  description       = "Allow HTTPS from internet"
}

resource "aws_security_group_rule" "alb_egress_to_nodes" {
  type                     = "egress"
  from_port                = var.app_port
  to_port                  = var.app_port
  protocol                 = "tcp"
  security_group_id        = aws_security_group.alb.id
  source_security_group_id = aws_security_group.node.id
  description              = "Allow application traffic to nodes"
}

# --- EKS cluster ---

resource "aws_eks_cluster" "this" {
  name                          = var.name
  version                       = var.cluster_version
  role_arn                      = aws_iam_role.cluster.arn
  bootstrap_self_managed_addons = false

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

  tags = merge(var.tags, { Name = "${var.name}-eks-cluster" })

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

# --- Node launch template (tags instances and EBS volumes) ---

resource "aws_launch_template" "node" {
  name_prefix = "${var.name}-node-"

  vpc_security_group_ids = [aws_security_group.node.id]

  tag_specifications {
    resource_type = "instance"
    tags = merge(var.tags, {
      Name = "${var.name}-node"
    })
  }

  tag_specifications {
    resource_type = "volume"
    tags = merge(var.tags, {
      Name = "${var.name}-node-volume"
    })
  }

  tags = merge(var.tags, { Name = "${var.name}-node-lt" })

  lifecycle {
    create_before_destroy = true
  }
}

# --- Managed node group ---

resource "aws_eks_node_group" "this" {
  cluster_name    = aws_eks_cluster.this.name
  node_group_name = "${var.name}-default"
  node_role_arn   = aws_iam_role.node.arn
  subnet_ids      = local.node_subnet_ids

  capacity_type  = var.node_capacity_type
  instance_types = var.node_instance_types

  launch_template {
    id      = aws_launch_template.node.id
    version = aws_launch_template.node.latest_version
  }

  scaling_config {
    desired_size = var.node_desired_size
    min_size     = var.node_min_size
    max_size     = var.node_max_size
  }

  update_config {
    max_unavailable = 1
  }

  tags = merge(var.tags, { Name = "${var.name}-node-group" })

  depends_on = [aws_iam_role_policy_attachment.node]
}

# --- Managed add-ons ---

resource "aws_eks_addon" "this" {
  for_each = local.addons

  cluster_name  = aws_eks_cluster.this.name
  addon_name    = each.value
  addon_version = data.aws_eks_addon_version.this[each.key].version

  resolve_conflicts_on_create = "OVERWRITE"
  resolve_conflicts_on_update = "PRESERVE"

  tags = merge(var.tags, { Name = "${var.name}-addon-${each.value}" })

  depends_on = [aws_eks_node_group.this]
}

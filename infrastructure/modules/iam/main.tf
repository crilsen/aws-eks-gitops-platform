resource "aws_iam_policy" "alb_controller" {
  name        = "${var.name}-alb-controller"
  description = "Permissions for the AWS Load Balancer Controller (EKS Pod Identity)."
  policy      = file("${path.module}/files/alb_controller_iam_policy.json")

  tags = var.tags
}

resource "aws_iam_role" "alb_controller" {
  name = "${var.name}-alb-controller"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect    = "Allow"
      Principal = { Service = "pods.eks.amazonaws.com" }
      Action    = ["sts:AssumeRole", "sts:TagSession"]
    }]
  })

  tags = var.tags
}

resource "aws_iam_role_policy_attachment" "alb_controller" {
  role       = aws_iam_role.alb_controller.name
  policy_arn = aws_iam_policy.alb_controller.arn
}

resource "aws_eks_pod_identity_association" "alb_controller" {
  count = var.create_pod_identity_association ? 1 : 0

  cluster_name    = var.cluster_name
  namespace       = var.namespace
  service_account = var.service_account
  role_arn        = aws_iam_role.alb_controller.arn
}

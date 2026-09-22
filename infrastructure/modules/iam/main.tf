locals {
  oidc_provider = var.oidc_provider_url != "" ? replace(var.oidc_provider_url, "https://", "") : ""
  oidc_subject  = "system:serviceaccount:${var.namespace}:${var.service_account}"
}

resource "aws_iam_policy" "alb_controller" {
  name        = "${var.name}-alb-controller"
  description = "Permissions for the AWS Load Balancer Controller."
  policy      = file("${path.module}/files/alb_controller_iam_policy.json")

  tags = var.tags
}

resource "aws_iam_role" "alb_controller" {
  name = "${var.name}-alb-controller"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect    = "Allow"
      Principal = { Federated = var.oidc_provider_arn }
      Action    = "sts:AssumeRoleWithWebIdentity"
      Condition = {
        StringEquals = {
          "${local.oidc_provider}:sub" = local.oidc_subject
          "${local.oidc_provider}:aud" = "sts.amazonaws.com"
        }
      }
    }]
  })

  tags = var.tags
}

resource "aws_iam_role_policy_attachment" "alb_controller" {
  role       = aws_iam_role.alb_controller.name
  policy_arn = aws_iam_policy.alb_controller.arn
}

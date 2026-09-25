# IAM module

Provides the AWS Load Balancer Controller identity using **IRSA** (ADR-026; supersedes ADR-011).

## Behavior

- Creates the IAM policy from the official AWS Load Balancer Controller policy (`files/alb_controller_iam_policy.json`).
- Creates the controller IAM role trusting the cluster OIDC provider for the controller service account.
- Takes `oidc_provider_arn`/`oidc_provider_url` from the environment root (the provider itself lives in `environments/dev`).

## Inputs

| Name | Type | Default | Description |
| --- | --- | --- | --- |
| `name` | `string` | — | Name prefix for the role and policy. |
| `tags` | `map(string)` | `{}` | Tags for created resources. |
| `cluster_name` | `string` | — | EKS cluster name (reserved, currently unused). |
| `namespace` | `string` | `kube-system` | Controller namespace. |
| `service_account` | `string` | `aws-load-balancer-controller` | Controller service account. |
| `oidc_provider_arn` | `string` | — | Cluster OIDC provider ARN for the IRSA trust policy. |
| `oidc_provider_url` | `string` | — | Cluster OIDC issuer URL for the IRSA trust policy. |

## Outputs

`alb_controller_role_arn`, `alb_controller_policy_arn`.

## Notes

- The policy file mirrors the upstream AWS Load Balancer Controller `iam_policy.json`; update it when upgrading the controller.
- The controller's service account must match `namespace`/`service_account` for IRSA to work; the ARN is rendered into the ArgoCD Application by Terraform.

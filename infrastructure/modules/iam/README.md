# IAM module

Provides the AWS Load Balancer Controller identity using **EKS Pod Identity** (ADR-011).

## Behavior

- Creates the IAM policy from the official AWS Load Balancer Controller policy (`files/alb_controller_iam_policy.json`).
- Creates the controller IAM role trusting `pods.eks.amazonaws.com`.
- Creates the EKS Pod Identity association for the controller service account (`kube-system/aws-load-balancer-controller` by default).

No IRSA/OIDC provider is created for the cluster.

## Inputs

| Name | Type | Default | Description |
| --- | --- | --- | --- |
| `name` | `string` | — | Name prefix for the role and policy. |
| `tags` | `map(string)` | `{}` | Tags for created resources. |
| `cluster_name` | `string` | — | EKS cluster name. |
| `namespace` | `string` | `kube-system` | Controller namespace. |
| `service_account` | `string` | `aws-load-balancer-controller` | Controller service account. |
| `create_pod_identity_association` | `bool` | `true` | Create the Pod Identity association. |

## Outputs

`alb_controller_role_arn`, `alb_controller_policy_arn`, `alb_controller_pod_identity_association_id`.

## Notes

- The policy file mirrors the upstream AWS Load Balancer Controller `iam_policy.json`; update it when upgrading the controller.
- The controller's service account must match `namespace`/`service_account` for Pod Identity to work.

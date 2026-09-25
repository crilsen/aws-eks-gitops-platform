# EKS module

Creates a shared EKS cluster with a small managed node group and the core managed add-ons. Environments are separated by namespace (ADR-022), not by cluster.

## Behavior

- EKS cluster in the provided subnets (at least two AZs), private and public endpoint access controllable.
- Managed node group in the provided node subnets, with configurable instance types and scaling.
- Managed add-ons pinned to the latest compatible version (default: `eks-pod-identity-agent`; `vpc-cni`, `kube-proxy`, and `coredns` are bootstrapped automatically).
- Cluster and node IAM roles with AWS managed policies.
- The cluster OIDC provider lives in the environment root (see `environments/dev`); the ALB controller consumes it via IRSA (ADR-026).

## Inputs

| Name | Type | Default | Description |
| --- | --- | --- | --- |
| `name` | `string` | — | Cluster name (shared). |
| `tags` | `map(string)` | `{}` | Tags for every resource. |
| `cluster_version` | `string` | `1.36` | Kubernetes version. |
| `vpc_id` | `string` | — | VPC id. |
| `subnet_ids` | `list(string)` | — | Control-plane subnets (>= 2 AZs). |
| `node_subnet_ids` | `list(string)` | `[]` | Node subnets (defaults to `subnet_ids`). |
| `endpoint_private_access` | `bool` | `true` | Private API access. |
| `endpoint_public_access` | `bool` | `true` | Public API access. |
| `public_access_cidrs` | `list(string)` | `["0.0.0.0/0"]` | CIDRs allowed on the public endpoint. |
| `node_instance_types` | `list(string)` | `["t3.small"]` | Node instance types. |
| `node_capacity_type` | `string` | `ON_DEMAND` | `ON_DEMAND` or `SPOT`. |
| `node_desired_size` / `node_min_size` / `node_max_size` | `number` | `2` / `1` / `3` | Node scaling. |
| `cluster_enabled_log_types` | `list(string)` | `[]` | Control-plane logs (empty avoids CloudWatch cost). |
| `addons` | `list(string)` | core + pod identity agent | Managed add-ons. |

## Outputs

`cluster_name`, `cluster_version`, `cluster_endpoint`, `cluster_certificate_authority_data`, `cluster_iam_role_arn`, `cluster_oidc_issuer_url`, `cluster_security_group_id_eks_managed`, `node_role_arn`, `node_group_name`, `alb_security_group_id`, `node_security_group_id`, `cluster_security_group_id`.

## Cost notes

- The control plane costs ~US$ 0.10/hour; destroy promptly after the demo.
- Nodes are `t3.small`; keep `node_max_size` low and `cluster_enabled_log_types` empty.

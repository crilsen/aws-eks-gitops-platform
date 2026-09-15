# EKS module

Creates a shared EKS cluster with a small managed node group and the core managed add-ons. Environments are separated by namespace (ADR-022), not by cluster.

## Behavior

- EKS cluster in the provided subnets (at least two AZs), private and public endpoint access controllable.
- Managed node group in the provided node subnets, with configurable instance types and scaling.
- Managed add-ons (`vpc-cni`, `kube-proxy`, `coredns`, `eks-pod-identity-agent`) pinned to the latest compatible version.
- Cluster and node IAM roles with AWS managed policies.
- No OIDC/IRSA provider: the ALB controller uses EKS Pod Identity (ADR-011).

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
| `node_desired_size` / `node_min_size` / `node_max_size` | `number` | `1` / `1` / `2` | Node scaling. |
| `cluster_enabled_log_types` | `list(string)` | `[]` | Control-plane logs (empty avoids CloudWatch cost). |
| `addons` | `list(string)` | core + pod identity agent | Managed add-ons. |

## Outputs

`cluster_name`, `cluster_version`, `cluster_endpoint`, `cluster_certificate_authority_data`, `cluster_iam_role_arn`, `node_role_arn`, `node_group_name`.

## Cost notes

- The control plane costs ~US$ 0.10/hour; destroy promptly after the demo.
- Nodes are `t3.small`; keep `node_max_size` low and `cluster_enabled_log_types` empty.

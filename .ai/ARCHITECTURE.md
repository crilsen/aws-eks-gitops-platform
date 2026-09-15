# Architecture

## Status

This is the **approved target architecture** from the project brief, not observed implementation. No artifacts exist yet.

## Repository layout

```text
aws-eks-gitops-platform/
├── infrastructure/
│   ├── modules/            # vpc, eks, ecr, iam
│   └── environments/dev/   # lab environment root
├── application/
│   ├── src/                # example API (/, /health)
│   ├── Dockerfile
│   ├── helm/               # application chart
│   └── .github/workflows/  # CI
├── gitops/
│   ├── argocd/             # Argo CD install values
│   ├── bootstrap/          # App of Apps entrypoint
│   ├── applications/       # Application / ApplicationSet
│   └── environments/
│       ├── dev/
│       └── prod/
├── docs/
├── README.md
└── .gitignore
```

## Target architecture

```text
AWS (account supplied privately, us-east-1)
└── Existing VPC (adopted; VPC block 10.11.0.0/16)
    ├── Existing Internet Gateway   - reused
    ├── Existing NAT Gateway        - reused for private-subnet egress
    ├── Created subnets /24         - public + private, from the agreed CIDR scheme
    ├── Created route tables        - always module-owned (public -> IGW, private -> NAT)
    ├── EKS cluster                 - latest version, single small managed node
    │   ├── namespace argocd  - Argo CD (Helm), App of Apps
    │   ├── namespace dev     - app + Ingress (ALB), automated prune/selfHeal
    │   └── namespace prod    - app + Ingress (ALB), PR-gated sync
    ├── IAM                   - least privilege; ALB controller via IRSA or EKS Pod Identity
    └── ACM                   - certificate for the ALB HTTPS listener, DNS-validated in Cloudflare

External
├── container registry        - images with immutable SHA tags (ECR removed; GHCR proposed)
└── Cloudflare DNS (crilsen.com) - record pointing to the ALB; ACM DNS validation

Terraform state: S3 backend (bucket name/region supplied privately; lock file per state).
```

## Decisions already made (from the author)

- Adopt the existing VPC, IGW, and NAT (IDs supplied privately, not versioned).
- Subnets are /24 and start from the agreed base (`10.21`, interpretation pending).
- Terraform state in S3.
- Ingress via ALB; TLS via ACM; DNS zone `crilsen.com` on Cloudflare.
- EKS: latest supported version, a single small managed node.

## GitOps flow

```text
git push ─► GitHub Actions (test, lint, trivy, build)
          ─► push image :<git-sha> to the registry (GHCR proposed; no ECR)
          ─► update tag in gitops/environments/dev  ─► commit
          ─► Argo CD detects change ─► sync dev (prune + selfHeal)
prod:     open PR against gitops/environments/prod ─► review + manual sync
```

## Deployment boundary

- Terraform owns AWS: VPC, EKS, IAM, ACM (if used), and the ALB controller identity. The ALB itself is created by the AWS Load Balancer Controller from the Kubernetes `Ingress` and removed on teardown. The container registry is external to AWS (ECR removed).
- Argo CD owns in-cluster state: platform add-ons (Argo CD, AWS Load Balancer Controller) and workloads, declared in `gitops/`.
- No manual `kubectl apply` as the normal path; manual changes exist only for the drift demonstration.

## VPC module design (required)

The `infrastructure/modules/vpc` module must be usable in both a fresh lab account and a pre-existing network:

- **VPC:** create from `vpc_cidr` or adopt an existing `vpc_id` (create-or-use toggle).
- **Subnets:** created by the module from configurable CIDRs (`public_subnet_cidrs`, `private_subnet_cidrs`) and `azs`, inside the new or adopted VPC.
- **Internet Gateway:** can be supplied (`internet_gateway_id`) or created by the module.
- **NAT:** can be supplied (`nat_gateway_id`) to reuse an existing NAT, or created only when explicitly enabled; default is no new NAT (cost rule).
- **Route tables:** always created and owned by the module, with subnet associations and routes to the IGW and/or NAT when available.

## Constraints shaping the design

- `dev` and `prod` share one cluster as namespaces; `prod` is not a separate account or cluster in this lab.
- A shared ALB is acceptable only when technically safe and clearly documented; avoid multiple ALBs.
- Drift and rollback are Git-driven; no `kubectl` fix as the documented recovery path.

## Open architectural decisions

Tracked in `TASKS.md` and `DECISIONS.md`: the exact subnet CIDRs (ADR-019), container registry confirmation (ADR-014), ALB controller identity IRSA vs Pod Identity (ADR-011), the EKS version/nodes posture (ADR-018), the S3 bucket name (ADR-017), the Cloudflare record name, and TLS confirmation. Decided: adopt existing VPC/IGW/NAT (ADR-012), flexible VPC module (ADR-013), ALB ingress (ADR-015), Cloudflare DNS zone `crilsen.com` (ADR-016), S3 state (ADR-017), EKS latest + 1 small node (ADR-018). Region `us-east-1` and the account are known to the author; ids stay in private config.

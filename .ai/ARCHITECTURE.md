# Architecture

## Status

This is the **observed live architecture** (verified against AWS on 2026-09-25), evolved from the approved target in the project brief.

## Repository layout

```text
aws-eks-gitops-platform/
├── infrastructure/
│   ├── modules/            # vpc, eks, iam
│   └── environments/dev/   # lab environment root
├── application/
│   ├── src/                # FastAPI app (/, /health)
│   ├── tests/
│   ├── Dockerfile
│   └── helm/               # application chart (optional ALB Ingress)
├── .github/workflows/      # CI (root, per ADR-021)
├── gitops/
│   ├── argocd/             # Argo CD install values
│   ├── bootstrap/          # App of Apps entrypoint
│   ├── applications/       # Application / ApplicationSet
│   └── environments/
│       ├── dev/
│       └── prd/
├── cert/                   # user-supplied TLS files (gitignored, never committed)
├── skills/                 # infra-up, collect-evidence, teardown scripts
├── evidence/               # plan/apply/status outputs
├── README.md
└── .gitignore
```

## Target architecture

```text
AWS (account supplied privately, us-east-1)
└── Created VPC (10.12.0.0/16, Terraform-managed)
    ├── Created Internet Gateway
    ├── Created NAT Gateway + EIP - private-subnet egress
    ├── Created subnets /24         - public 10.12.21.0/24, 10.12.22.0/24; private 10.12.23.0/24, 10.12.24.0/24
    ├── Created route tables        - always module-owned (public -> IGW, private -> NAT)
    ├── EKS cluster 1.36            - 2× t3.small managed nodes
    │   ├── namespace argocd  - Argo CD (Helm), App of Apps
    │   ├── namespace dev     - app + Ingress (ALB), automated prune/selfHeal
    │   └── namespace prd     - app + Ingress (ALB), PR-gated sync (not deployed yet)
    ├── IAM                   - least privilege; ALB controller via IRSA (ADR-026)
    └── ACM                   - imported user-supplied Let's Encrypt cert (`*.crilsen.com`, gitignored files) for the ALB HTTPS listener

External
├── container registry        - GHCR images with immutable SHA tags (ECR removed)
└── Cloudflare DNS (crilsen.com) - CNAME app-dev.crilsen.com (dev, live); app.crilsen.com (prod, pending prod deploy); no ACM DNS validation, no Route 53

Terraform state: S3 `cn-terraform-state-us-east-1`, keys `aws-eks-gitops-platform/<env>/terraform.tfstate` with native S3 locking.
```

## Decisions already made (from the author)

- Created VPC `10.12.0.0/16` with created IGW and NAT (ADR-012 as amended).
- Subnets are `/24` inside `10.12.0.0/16`: public `10.12.21.0/24` and `10.12.22.0/24`, private `10.12.23.0/24` and `10.12.24.0/24` (ADR-019 as amended).
- Container registry is a parameter (ADR-014): GHCR default, Docker Hub supported.
- Terraform state in S3.
- Ingress via ALB; TLS via ACM; DNS zone `crilsen.com` on Cloudflare (dev `app-dev.crilsen.com`, prod `app.crilsen.com`).
- EKS: 1.36, 2× `t3.small` managed nodes (ADR-018 as amended: scaled from 1, one node could not schedule Argo CD + controller + workload).

## GitOps flow

```text
git push ─► GitHub Actions (test, build, trivy, push)
          ─► push image :<git-sha> to GHCR (no ECR)
          ─► update tag in gitops/environments/dev  ─► commit
          ─► Argo CD detects change ─► sync dev (prune + selfHeal)
prd:      open PR against gitops/environments/prd ─► review + manual sync
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

- `dev` and `prd` share one cluster as namespaces; `prd` is not a separate account or cluster in this lab.
- A shared ALB is acceptable only when technically safe and clearly documented; avoid multiple ALBs.
- Drift and rollback are Git-driven; no `kubectl` fix as the documented recovery path.

## Open architectural decisions

Remaining work (not decisions): flip the GHCR package to public (owner action in the package settings — no working API endpoint found), create the `app.crilsen.com` record on prod deploy, run the drift/promotion/rollback demos, and tear down. Decided and implemented: IRSA for the controller (ADR-026), S3 state (ADR-017), created VPC/IGW/NAT (ADR-012 as amended), flexible VPC module (ADR-013), GHCR registry (ADR-014), ALB ingress (ADR-015), Cloudflare DNS + ACM import (ADR-016/024), EKS 1.36 + 2× `t3.small` (ADR-018), subnet scheme 10.12 (ADR-019 as amended), dedicated SGs (ADR-025). Region `us-east-1` and the account are known to the author; ids stay in private config.

# aws-eks-gitops-platform

Portfolio project demonstrating **Platform Engineering, GitOps, Amazon EKS, Terraform, Kubernetes, Helm, Argo CD, CI/CD, security, and AWS cost control** on a temporary lab environment.

## Architecture

```text
AWS (us-east-1)
└── VPC 10.12.0.0/16 (created by Terraform)
    ├── Public subnets  (10.12.21.0/24, 10.12.22.0/24) — ALB + NAT
    ├── Private subnets (10.12.23.0/24, 10.12.24.0/24) — EKS nodes
    ├── Internet Gateway
    ├── NAT Gateway + EIP
    ├── Route tables (always Terraform-managed)
    ├── Network ACLs (public/private, tagged)
    └── EKS cluster (1.36, 2× t3.small)
        ├── kube-system  — AWS Load Balancer Controller (IRSA), CoreDNS, kube-proxy
        ├── argocd       — Argo CD (App of Apps root)
        ├── dev          — FastAPI app + ALB Ingress (automated sync)
        └── prd          — FastAPI app (PR-gated, manual sync)

External
├── GHCR (ghcr.io/crilsen/aws-eks-gitops-platform) — immutable SHA tags
├── Cloudflare DNS (crilsen.com) — app-dev / app CNAMEs → ALB
└── ACM — imported Let's Encrypt cert (`*.crilsen.com`, user-supplied, gitignored) for ALB HTTPS
```

## Tech Stack

| Layer | Technology |
|---|---|
| IaC | Terraform (modules: vpc, eks, iam) |
| Container | EKS 1.36, managed node group (2× t3.small) |
| GitOps | Argo CD 10.9.1, App of Apps pattern |
| Ingress | AWS Load Balancer Controller 3.5.0, ALB |
| Identity | IRSA (OIDC provider + role annotation) |
| Application | Python 3.12, FastAPI, uvicorn |
| CI/CD | GitHub Actions (Trivy, GHCR push, GitOps tag update) |
| DNS/TLS | Cloudflare + ACM |

## Project Structure

```text
infrastructure/
├── modules/vpc/     VPC, subnets, IGW, NAT, RTs, NACLs
├── modules/eks/     EKS cluster, node group, launch template (IMDS hop limit 2)
├── modules/iam/     ALB controller IAM policy + IRSA role
└── environments/dev/ Root: OIDC provider, module wiring, ALB app template

application/
├── src/app/main.py  FastAPI API (/, /health)
├── tests/           Pytest
├── Dockerfile       Multi-stage non-root
└── helm/            Chart with probes, resources, optional ALB Ingress

gitops/
├── argocd/          Helm values (UI via port-forward)
├── bootstrap/       App of Apps root
├── applications/
│   ├── platform/    AWS Load Balancer Controller (IRSA annotation)
│   └── workloads/   app-dev (auto sync), app-prd (manual)
└── environments/    dev/prd values (image tag, Ingress, hosts)

.github/workflows/
├── ci.yml           pytest → build → Trivy → GHCR push → GitOps tag
└── promote.yml      Manual PR to promote image to prd

skills/
├── infra-up.sh      Full provisioning + Argo CD bootstrap
├── collect-evidence.sh  Capture cluster state
└── teardown.sh      Destroy + verify cleanup

evidence/            Plan, apply, status, destroy outputs
```

## Quick Start

### Prerequisites

- AWS CLI configured with lab account permissions
- Terraform ≥ 1.10
- kubectl
- Helm (`~/bin/helm` or system)
- Docker
- `gh` CLI (for CI token)

### Provision

```bash
./skills/infra-up.sh dev
```

This runs Terraform apply, configures kubeconfig, creates the access entry, installs Argo CD, and bootstraps the App of Apps.

### Access Argo CD

The Argo CD dashboard is accessible only via port-forward (no ALB — single ALB rule, app only):

```bash
kubectl -n argocd port-forward svc/argocd-server 8080:443
# Open: https://localhost:8080
# Username: admin
# Password:
kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath='{.data.password}' | base64 -d
```

This is intentional: exposing Argo CD through the ALB would require a second load balancer and increase cost. Port-forward is sufficient for a portfolio demo and demonstrates Kubernetes networking knowledge.

### Check Status

```bash
./skills/collect-evidence.sh
```

### Teardown

```bash
./skills/teardown.sh dev
```

## Key Technical Decisions

| # | Decision | Rationale |
|---|---|---|
| ADR-005 | `dev`/`prd` as namespaces in one cluster | Cost control (US$100 budget) |
| ADR-011 | IRSA for ALB controller | Battle-tested; Pod Identity caused crashes |
| ADR-013 | Flexible VPC module (create-or-adopt) | Reusable across environments |
| ADR-014 | GHCR (parameterizable registry) | Free for public repos, no AWS credentials needed |
| ADR-015 | ALB (not Envoy) | ALB is AWS-native, simpler for a single cluster |
| ADR-017 | S3 backend with native locking | No DynamoDB needed |
| ADR-019 | Subnets /24 from 10.11.21.0 | Clean CIDR allocation inside 10.12.0.0/16 |
| ADR-022 | One shared cluster | Lab constraint; documented trade-off |

Full decisions: `.ai/DECISIONS.md`

## Security

- Public API endpoint restricted to specific CIDRs (rejects `0.0.0.0/0`)
- IRSA with least-privilege IAM policy (official ALB controller policy)
- Multi-stage Dockerfile with non-root user
- `readOnlyRootFilesystem`, `drop ALL` capabilities in deployment
- `readinessProbe` and `livenessProbe` on `/health`
- Resource requests/limits sized for t3.small
- `AutoDelete = true` tag on all resources

## Cost

Estimated cost when running:

| Resource | ~US$/hour |
|---|---|
| EKS control plane | $0.10 |
| 2× t3.small nodes | $0.04 |
| NAT Gateway + EIP | $0.05 |
| ALB (temporary) | $0.02 |
| **Total** | **~$0.21/h (~$5/day)** |

- NAT is created but can be replaced with an existing one via tfvars
- ALB is created by the controller and destroyed with the environment
- All resources tagged `AutoDelete = true`

## Lessons Learned

1. **IMDS hop limit must be 2** for IRSA to work (EKS defaults to 1)
2. **EKS manages its own security groups** — custom cluster SGs cause node registration failures
3. **`bootstrap_self_managed_addons = true`** needed for VPC CNI to install automatically
4. **ArgoCD reads from git, not filesystem** — Terraform `local_file` must be committed for ArgoCD to pick up changes
5. **macOS `sed` differs from Linux** — use `python3` or `perl` for cross-platform string replacement

## Demo Checklist (for interviews)

- [ ] `terraform apply` — 50+ resources provisioned
- [ ] Cluster active, 2 nodes Ready
- [ ] Argo CD root app Synced
- [ ] ALB controller running with IRSA
- [ ] FastAPI app deployed in `dev` namespace
- [ ] ALB Ingress with Cloudflare DNS
- [ ] `/health` endpoint responding
- [ ] Drift demo: manual edit → self-heal
- [ ] Promotion: PR to prod → manual sync
- [ ] Rollback: git revert → re-sync
- [ ] `terraform destroy` — clean teardown

## Documentation

- Agent context: `AGENTS.md` and `.ai/`
- Architecture decisions: `.ai/DECISIONS.md`
- Validation commands: `.ai/VALIDATION.md`
- Current tasks: `.ai/TASKS.md`

# Session Handoff

## Resume block (read first)

- Repo state: branch `dev`, synced with `origin/dev`; tree clean after `eeb9d35` (EKS module + shared cluster).
- Source of truth: `AGENTS.md` → `.ai/`
- Budget / usage observed: unknown
- Checkpoint updated: 2026-09-15
- Last goal: Add `modules/eks` (shared cluster 1.36, 1× `t3.small`) and wire it into `environments/dev` per ADR-022.
- Exact next action: Build `modules/iam` — ALB controller Pod Identity (role + association) and the GitHub Actions OIDC role — and wire it into `environments/dev`; then `gitops/` and CI.
- Blocked by: None for module work. `terraform apply` (Phase 3) blocked on explicit authorization and a cost review.
- Resume prompt: `Read AGENTS.md and .ai/HANDOFF.md. Continue from the Resume block. Do not rediscover context.`

## Goal

Build a public portfolio GitOps platform on AWS EKS demonstrating Platform Engineering, GitOps, Terraform, Kubernetes, Helm, Argo CD, CI/CD, security, and cost control, within a US$ 100 credit budget.

## Current State

All planning inputs are resolved. `infrastructure/modules/vpc`, `infrastructure/modules/eks`, `infrastructure/environments/dev`, and the Phase 1 application exist and pass local validation. The shared EKS cluster is wired into `environments/dev`. No IAM module, GitOps manifests, or CI exist yet. Nothing has been provisioned on AWS.

## What Was Done

- Adopted `.ai/` context with real project facts and recorded the phased roadmap.
- Recorded ADRs 004–021; resolved all open inputs: EKS Pod Identity (ADR-011), S3 bucket `cn-terraform-state-us-east-1` with `dev`/`prd` folders and native locking (ADR-017), hostnames `app-dev.crilsen.com`/`app.crilsen.com` (ADR-016), EKS 1.36 (ADR-018), Python + FastAPI (ADR-020), root workflows (ADR-021).
- Implemented `infrastructure/modules/vpc` plus its README.
- Implemented `infrastructure/modules/eks` (shared cluster 1.36, 1× `t3.small` managed node group, vpc-cni/kube-proxy/coredns/pod-identity-agent add-ons) plus its README, wired into `environments/dev`.
- Implemented the Phase 1 application.
- Created `infrastructure/environments/dev` (S3 backend, provider `default_tags`, adopted network, subnet CIDRs, EKS module).
- Validated: `terraform fmt`/`validate` (modules and dev root); pytest (2 passed), `docker build`, container smoke test, `helm lint`, `helm template`.

## Files Changed

- `infrastructure/modules/vpc/*` (new)
- `infrastructure/modules/eks/*` (new)
- `infrastructure/environments/dev/*` (new: backend, provider, variables, module calls, outputs, `terraform.tfvars.example`, README, `terraform.lock.hcl`)
- `application/*` (new)
- `.ai/*`, `.gitignore`, `README.md`

## Decisions Made

- Single monorepo with area-separated directories (ADR-004).
- `dev` and `prod` as namespaces in one temporary cluster (ADR-005).
- No NAT Gateway creation or secondary managed services (ADR-006); reused NAT is allowed.
- GitHub OIDC instead of static credentials (ADR-007).
- Immutable SHA image tags only (ADR-008).
- `dev` auto-syncs with prune/selfHeal; `prod` is PR-gated (ADR-009).
- Single temporary ALB via the controller (ADR-010, amended by ADR-016).
- EKS Pod Identity for the ALB controller (ADR-011).
- Adopt existing VPC/IGW/NAT; private egress via reused NAT (ADR-012).
- Flexible create-or-adopt VPC module, always-created route tables (ADR-013).
- Parameterizable registry, GHCR default, Docker Hub supported (ADR-014).
- Ingress via AWS Load Balancer Controller + ALB (ADR-015).
- Cloudflare DNS zone `crilsen.com` + ACM TLS (ADR-016).
- S3 Terraform state (ADR-017).
- EKS latest version, single `t3.small` node (ADR-018).
- Subnets `/24` inside `10.11.0.0/16`, `10.11.21.0/24` onward (ADR-019).
- Application stack: Python + FastAPI (ADR-020).
- GitHub Actions workflows at the repository root (ADR-021).
- Environment isolation: one shared cluster, `dev`/`prd` namespaces, documented trade-off (ADR-022).

## Problems / Risks

- AWS phases consume credits and require explicit authorization and a plan first; the EKS control plane is the dominant cost.
- `tflint`, `checkov`, and `trivy` are not installed, so those checks are pending.
- The adopted VPC/IGW/NAT/ids are private inputs (`terraform.tfvars`, gitignored); the subnet CIDRs must not overlap existing subnets.
- `dev` and `prd` are namespaces in one cluster; `prd` (state folder) will mirror `dev` later.

## Validation Performed

- `terraform fmt -recursive` and `terraform validate` (`modules/vpc`, `modules/eks`, `environments/dev`) — Validated.
- `pytest` in `python:3.12-slim` — Validated (2 passed).
- `docker build` + container smoke test for `/` and `/health` — Validated.
- `helm lint` and `helm template` — Validated.
- `tflint`, `checkov`, `trivy`, `terraform plan` — Not validated (tools absent / plan needs authorization).

## Next Actions

- Phase 2: build `modules/iam` — ALB controller Pod Identity (role + association) and the GitHub Actions OIDC role — and wire into `environments/dev`.
- Phase 4/5: add `gitops/` (Argo CD, App of Apps, dev/prd) and the Cloudflare CNAMEs.
- Phase 6: add CI workflows at the repository root.

# Session Handoff

## Resume block (read first)

- Repo state: branch `dev`, synced with `origin/dev`; app live end-to-end (`app-dev.crilsen.com/health` → 200).
- Source of truth: `AGENTS.md` → `.ai/`
- Budget / usage observed: unknown
- Checkpoint updated: 2026-09-26
- Last goal: Unblock the app deploy (GHCR visibility + multi-arch image) and verify end-to-end.
- Exact next action: Drift/selfHeal demo, prod promotion PR (+ `app.crilsen.com` record), rollback demo, screenshots/GIFs, `terraform destroy`, final README.
- Blocked by: nothing technical. Infra is running and billing (~US$0.21/h) — tear down when done.
- Resume prompt: `Read AGENTS.md and .ai/HANDOFF.md. Continue from the Resume block. Do not rediscover context.`

## Goal

Build a public portfolio GitOps platform on AWS EKS demonstrating Platform Engineering, GitOps, Terraform, Kubernetes, Helm, Argo CD, CI/CD, security, and cost control, within a US$ 100 credit budget.

## Current State

All planning inputs are resolved. Infrastructure (vpc/eks/iam modules + dev root, including the ACM certificate import and dedicated SGs), the Phase 1 application, the `gitops/` definitions, and the CI workflows are implemented and live: cluster ACTIVE, 2 nodes Ready, ArgoCD root + controller `Synced`/`Healthy`, ALB active with the dedicated SG, `app-dev` `Synced`/`Healthy` serving 200 on `/health` via `app-dev.crilsen.com`. Registry: GHCR, package public.

## What Was Done

- Adopted `.ai/` context with real project facts and recorded the phased roadmap.
- Recorded ADRs 004–026; resolved all open inputs and deferred GitHub OIDC (ADR-023).
- Implemented `infrastructure/modules/vpc`, `infrastructure/modules/eks`, and `infrastructure/modules/iam` (ALB controller policy + IRSA role trusting the cluster OIDC provider) with READMEs.
- Implemented the Phase 1 application.
- Created `infrastructure/environments/dev` (S3 backend, provider `default_tags`, created network `10.12.0.0/16`, EKS 1.36 + OIDC provider, IAM role, ACM import) and restricted the public API endpoint to specific CIDRs via `terraform.tfvars` (validation rejects `0.0.0.0/0`). Applied (authorized): 64 managed resources live.
- Implemented `gitops/` (Argo CD 10.9.1 values, App of Apps root, AWS Load Balancer Controller 3.5.0 Application with IRSA annotation, `app-dev`/`app-prd` Applications, dev/prd values with ALB Ingress and Cloudflare hosts).
- Implemented CI at the repository root: `.github/workflows/ci.yml` (pytest, docker build, Trivy, GHCR push with immutable SHA, GitOps dev tag update) and `.github/workflows/promote.yml` (manual PR to promote to prd).
- Imported the user-supplied Let's Encrypt certificate into ACM (`aws_acm_certificate.app`, ADR-024); the ALB discovers it by hostname and the private key stays gitignored.
- Validated: `terraform fmt`/`validate`; pytest (2 passed), `docker build`, container smoke test, `helm lint`/`template` (including with the dev values), YAML parsing of `gitops/`, and actionlint for the workflows.

## Files Changed

- `infrastructure/modules/vpc/*`, `infrastructure/modules/eks/*`, `infrastructure/modules/iam/*` (new)
- `infrastructure/environments/dev/*` (new)
- `application/*` (new)
- `gitops/*` (new)
- `.github/workflows/*` (new)
- `.ai/*`, `.gitignore`, `README.md`

## Decisions Made

- Single monorepo with area-separated directories (ADR-004).
- `dev` and `prd` as namespaces in one temporary cluster (ADR-005).
- NAT Gateway created for private-subnet egress (ADR-006 as amended, ADR-012 as amended); no RDS/OpenSearch/ElastiCache, no Route 53, no EKS Auto Mode.
- GitHub OIDC instead of static credentials (ADR-007).
- Immutable SHA image tags only (ADR-008).
- `dev` auto-syncs with prune/selfHeal; `prod` is PR-gated (ADR-009).
- Single temporary ALB via the controller (ADR-010, amended by ADR-016).
- EKS IRSA for the ALB controller (ADR-026, superseding ADR-011 Pod Identity).
- Adopt existing VPC/IGW/NAT; private egress via reused NAT (ADR-012).
- Flexible create-or-adopt VPC module, always-created route tables (ADR-013).
- Parameterizable registry, GHCR default, Docker Hub supported (ADR-014).
- Ingress via AWS Load Balancer Controller + ALB (ADR-015).
- Cloudflare DNS zone `crilsen.com` + ACM TLS (ADR-016).
- S3 Terraform state (ADR-017).
- EKS 1.36, 2× `t3.small` nodes (ADR-018 as amended).
- Subnets `/24` inside created `10.12.0.0/16`, `10.12.21.0/24` onward (ADR-019 as amended).
- Application stack: Python + FastAPI (ADR-020).
- GitHub Actions workflows at the repository root (ADR-021).
- Environment isolation: one shared cluster, `dev`/`prd` namespaces, documented trade-off (ADR-022).
- GitHub Actions OIDC deferred until CI needs AWS (ADR-023).
- User-supplied TLS certificate imported into ACM (ADR-024, amends ADR-016).
- Dedicated SG per resource with only necessary ports (ADR-025); ALB pinned via rendered override values.

## Problems / Risks

- AWS phases consume credits and require explicit authorization and a plan first; the EKS control plane is the dominant cost.
- `tflint`, `checkov`, and `trivy` are not installed, so those checks are pending.
- Private inputs (`terraform.tfvars`, gitignored): `public_access_cidrs` and the `cert/` paths; the subnet CIDRs must not overlap anything in the VPC.
- `dev` and `prd` are namespaces in one cluster; `prd` (state folder) will mirror `dev` later.

## Validation Performed

- `terraform fmt -recursive` and `terraform validate` (`modules/vpc`, `modules/eks`, `modules/iam`, `environments/dev`) — Validated.
- `pytest` in `python:3.12-slim` — Validated (2 passed).
- `docker build` + container smoke test for `/` and `/health` — Validated.
- `helm lint` and `helm template` (including with `gitops/environments/dev/values.yaml`) — Validated.
- `gitops/` YAML parsing — Validated.
- GitHub Actions workflows — Validated with actionlint.
- `tflint`, `checkov`, `trivy`, `terraform plan` — Not validated (tools absent / plan needs authorization).

## Next Actions

- Owner flips GHCR package `aws-eks-gitops-platform` to public (package settings; API has no working endpoint), then verify `app-dev` Healthy and `/health` via `app-dev.crilsen.com`.
- Phase 7: drift/selfHeal demo, prod promotion PR (+ `app.crilsen.com` record), rollback demo, screenshots/GIFs.
- Phase 8: `terraform destroy` with verification, final README pass.

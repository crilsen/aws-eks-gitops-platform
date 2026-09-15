# Session Handoff

## Resume block (read first)

- Repo state: branch `dev`, synced with `origin/dev`; working tree dirty with the new `gitops/` (commit pending).
- Source of truth: `AGENTS.md` → `.ai/`
- Budget / usage observed: unknown
- Checkpoint updated: 2026-09-15
- Last goal: Add `gitops/` (Argo CD values, App of Apps, platform and dev/prd Applications, environment values).
- Exact next action: Add the CI workflow at the repository root (GHCR build/push with immutable SHA, update `gitops/environments/dev/values.yaml`), then prepare Phase 3 (apply) for authorization.
- Blocked by: None for repo work. `terraform apply` (Phase 3) blocked on explicit authorization and a cost review.
- Resume prompt: `Read AGENTS.md and .ai/HANDOFF.md. Continue from the Resume block. Do not rediscover context.`

## Goal

Build a public portfolio GitOps platform on AWS EKS demonstrating Platform Engineering, GitOps, Terraform, Kubernetes, Helm, Argo CD, CI/CD, security, and cost control, within a US$ 100 credit budget.

## Current State

All planning inputs are resolved. Infrastructure (vpc/eks/iam modules + dev root), the Phase 1 application, and the `gitops/` definitions (Argo CD values, App of Apps, platform and dev/prd Applications, environment values) exist and pass local validation. CI has not been added yet. Nothing has been provisioned on AWS.

## What Was Done

- Adopted `.ai/` context with real project facts and recorded the phased roadmap.
- Recorded ADRs 004–023; resolved all open inputs and deferred GitHub OIDC (ADR-023).
- Implemented `infrastructure/modules/vpc`, `infrastructure/modules/eks`, and `infrastructure/modules/iam` (ALB controller policy + role + Pod Identity association) with READMEs.
- Implemented the Phase 1 application.
- Created `infrastructure/environments/dev` (S3 backend, provider `default_tags`, adopted network, subnet CIDRs, EKS module, IAM module) and restricted the public API endpoint to specific CIDRs via `terraform.tfvars` (validation rejects `0.0.0.0/0`).
- Implemented `gitops/` (Argo CD 10.9.1 values, App of Apps root, AWS Load Balancer Controller 3.5.0 Application, `app-dev`/`app-prd` Applications, dev/prd values with ALB Ingress and Cloudflare hosts).
- Validated: `terraform fmt`/`validate`; pytest (2 passed), `docker build`, container smoke test, `helm lint`/`template` (including with the dev values), and YAML parsing of the `gitops/` files.

## Files Changed

- `infrastructure/modules/vpc/*`, `infrastructure/modules/eks/*`, `infrastructure/modules/iam/*` (new)
- `infrastructure/environments/dev/*` (new)
- `application/*` (new)
- `gitops/*` (new)
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
- GitHub Actions OIDC deferred until CI needs AWS (ADR-023).

## Problems / Risks

- AWS phases consume credits and require explicit authorization and a plan first; the EKS control plane is the dominant cost.
- `tflint`, `checkov`, and `trivy` are not installed, so those checks are pending.
- The adopted VPC/IGW/NAT/ids are private inputs (`terraform.tfvars`, gitignored); the subnet CIDRs must not overlap existing subnets.
- `dev` and `prd` are namespaces in one cluster; `prd` (state folder) will mirror `dev` later.

## Validation Performed

- `terraform fmt -recursive` and `terraform validate` (`modules/vpc`, `modules/eks`, `modules/iam`, `environments/dev`) — Validated.
- `pytest` in `python:3.12-slim` — Validated (2 passed).
- `docker build` + container smoke test for `/` and `/health` — Validated.
- `helm lint` and `helm template` (including with `gitops/environments/dev/values.yaml`) — Validated.
- `gitops/` YAML parsing — Validated.
- `tflint`, `checkov`, `trivy`, `terraform plan` — Not validated (tools absent / plan needs authorization).

## Next Actions

- Phase 6: add the CI workflow at the repository root (build/test, Trivy, GHCR push with immutable SHA, update `gitops/environments/dev/values.yaml`, prod promotion PR).
- Phase 3: prepare the apply plan and cost estimate for authorization.
- Phase 4/5: add the Cloudflare CNAMEs (manual) and verify Argo CD sync after apply.

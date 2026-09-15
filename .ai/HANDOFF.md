# Session Handoff

## Resume block (read first)

- Repo state: branch `dev`, synced with `origin/dev`; tree clean. Latest work committed at `f735f53` (VPC module + Phase 1 app).
- Source of truth: `AGENTS.md` → `.ai/`
- Budget / usage observed: unknown
- Checkpoint updated: 2026-09-15
- Last goal: Implement Phase 1 — FastAPI app (`/`, `/health`), tests, Dockerfile, and Helm chart — and validate locally.
- Exact next action: Create `infrastructure/environments/dev` (wire the VPC module with the confirmed CIDRs, S3 backend, mandatory tags) and the `modules/eks`/`modules/iam`, then wire the GitOps bootstrap; CI (Phase 6) follows.
- Blocked by: None. AWS apply (Phase 3) blocked on explicit authorization; S3 bucket name/lock (ADR-017) and the exact EKS version must be confirmed first.
- Resume prompt: `Read AGENTS.md and .ai/HANDOFF.md. Continue from the Resume block. Do not rediscover context.`

## Goal

Build a public portfolio GitOps platform on AWS EKS demonstrating Platform Engineering, GitOps, Terraform, Kubernetes, Helm, Argo CD, CI/CD, security, and cost control, within a US$ 100 credit budget.

## Current State

Planning is complete for the AWS/network decisions. `infrastructure/modules/vpc` and the Phase 1 application (FastAPI app, tests, Dockerfile, Helm chart) exist and pass local validation. No environment root, EKS/IAM module, GitOps manifests, or CI exist yet. Nothing has been provisioned on AWS.

## What Was Done

- Adopted `.ai/` context with real project facts and recorded the phased roadmap.
- Recorded ADRs 004–021, including the flexible VPC module (ADR-013), adopted network (ADR-012), registry (ADR-014), ALB ingress (ADR-015), Cloudflare DNS + ACM (ADR-016), S3 state (ADR-017), EKS posture (ADR-018), subnet scheme (ADR-019), app stack (ADR-020), root workflows (ADR-021), and Pod Identity (ADR-011).
- Implemented `infrastructure/modules/vpc` plus its README.
- Implemented the Phase 1 application: `application/src/app/main.py`, tests, `Dockerfile`, and `application/helm/`.
- Validated: `terraform fmt`/`validate`; pytest (2 passed), `docker build`, container smoke test (`/` and `/health`), `helm lint`, `helm template`.

## Files Changed

- `infrastructure/modules/vpc/*` (new)
- `application/src/app/*`, `application/tests/*`, `application/pytest.ini`, `application/requirements*.txt`, `application/Dockerfile`, `application/.dockerignore`, `application/helm/*` (new)
- `.ai/PROJECT.md`, `.ai/ARCHITECTURE.md`, `.ai/CONVENTIONS.md`, `.ai/DECISIONS.md`, `.ai/TASKS.md`, `.ai/TOOLS.md`, `.ai/VALIDATION.md`, `.ai/HANDOFF.md`
- `.gitignore`, `README.md`

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

## Problems / Risks

- AWS phases consume credits and require explicit authorization and a plan first; the EKS control plane is the dominant cost.
- `tflint`, `checkov`, and `trivy` are not installed, so those checks are pending.
- Open inputs: S3 bucket name/lock (ADR-017), Cloudflare record name, and the exact EKS version.

## Validation Performed

- `terraform fmt -recursive` and `terraform validate` (`modules/vpc`) — Validated.
- `pytest` in `python:3.12-slim` — Validated (2 passed).
- `docker build` + container smoke test for `/` and `/health` — Validated.
- `helm lint` and `helm template` (container `alpine/helm:3.16.3`) — Validated.
- `tflint`, `checkov`, `trivy` — Not validated (not installed).

## Next Actions

- Phase 2: create `infrastructure/environments/dev` and `modules/eks`/`modules/iam`; validate with `terraform fmt`/`validate`.
- Phase 4/5: add `gitops/` (Argo CD, App of Apps, dev/prod) and the Cloudflare record.
- Phase 6: add CI workflows at the repository root.

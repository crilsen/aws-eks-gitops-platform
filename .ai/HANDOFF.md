# Session Handoff

## Resume block (read first)

- Repo state: branch `dev`, synced with `origin/dev`; working tree dirty with the new `infrastructure/modules/vpc` and updated `.ai/` (commit pending).
- Source of truth: `AGENTS.md` → `.ai/`
- Budget / usage observed: unknown
- Checkpoint updated: 2026-09-15
- Last goal: Implement and validate `infrastructure/modules/vpc` per ADR-013/ADR-019.
- Exact next action: Create `infrastructure/environments/dev` (wire the module with the confirmed CIDRs, S3 backend, mandatory tags) and the `modules/eks`/`modules/iam`; or start Phase 1 once the app language is chosen.
- Blocked by: None for Phase 2. Phase 1 blocked on the application language/framework. AWS apply (Phase 3) blocked on explicit authorization.
- Resume prompt: `Read AGENTS.md and .ai/HANDOFF.md. Continue from the Resume block. Do not rediscover context.`

## Goal

Build a public portfolio GitOps platform on AWS EKS demonstrating Platform Engineering, GitOps, Terraform, Kubernetes, Helm, Argo CD, CI/CD, security, and cost control, within a US$ 100 credit budget.

## Current State

Planning is complete for the AWS/network decisions. `infrastructure/modules/vpc` exists and passes `terraform fmt`/`terraform validate`. No environment root, EKS/IAM module, application, or GitOps artifacts exist yet. Nothing has been provisioned on AWS.

## What Was Done

- Adopted `.ai/` context with real project facts and recorded the phased roadmap.
- Recorded ADRs 004–019, including the flexible VPC module (ADR-013), adopted network (ADR-012), registry (ADR-014), ALB ingress (ADR-015), Cloudflare DNS + ACM (ADR-016), S3 state (ADR-017), EKS posture (ADR-018), and subnet scheme (ADR-019).
- Implemented `infrastructure/modules/vpc` (create-or-adopt VPC, configured `/24` subnets, reusable IGW/NAT, always-created route tables) plus its README.
- Validated the module with `terraform fmt -recursive` and `terraform validate` (AWS provider v6.64.0).

## Files Changed

- `infrastructure/modules/vpc/{versions,variables,main,outputs}.tf`, `infrastructure/modules/vpc/README.md` (new)
- `.ai/PROJECT.md`, `.ai/ARCHITECTURE.md`, `.ai/CONVENTIONS.md`
- `.ai/DECISIONS.md`, `.ai/TASKS.md`, `.ai/TOOLS.md`, `.ai/VALIDATION.md`, `.ai/HANDOFF.md`
- `.gitignore`, `README.md` (project overview)

## Decisions Made

- Single monorepo with area-separated directories (ADR-004).
- `dev` and `prod` as namespaces in one temporary cluster (ADR-005).
- No NAT Gateway creation or secondary managed services (ADR-006); reused NAT is allowed.
- GitHub OIDC instead of static credentials (ADR-007).
- Immutable SHA image tags only (ADR-008).
- `dev` auto-syncs with prune/selfHeal; `prod` is PR-gated (ADR-009).
- Single temporary ALB via the controller (ADR-010, amended by ADR-016).
- Adopt existing VPC/IGW/NAT; private egress via reused NAT (ADR-012).
- Flexible create-or-adopt VPC module, always-created route tables (ADR-013).
- Parameterizable registry, GHCR default, Docker Hub supported (ADR-014).
- Ingress via AWS Load Balancer Controller + ALB (ADR-015).
- Cloudflare DNS zone `crilsen.com` + ACM TLS (ADR-016).
- S3 Terraform state (ADR-017).
- EKS latest version, single `t3.small` node (ADR-018).
- Subnets `/24` inside `10.11.0.0/16`, `10.11.21.0/24` onward (ADR-019).
- Open: ALB controller identity Pod Identity vs IRSA (ADR-011).

## Problems / Risks

- Open decisions remain: ALB controller identity (ADR-011), S3 bucket name/lock (ADR-017), Cloudflare record name, exact EKS version, and the app language (Phase 1).
- AWS phases consume credits and require explicit authorization and a plan first; the EKS control plane is the dominant cost.
- `tflint`, `checkov`, `trivy`, and `helm` are not installed locally, so those checks are pending.

## Validation Performed

- `terraform fmt -recursive` — Validated (no changes needed).
- `terraform validate` for `modules/vpc` — Validated (AWS provider v6.64.0).
- `tflint`, `checkov`, app/Helm checks — Not validated (tools/artifacts absent).

## Next Actions

- Confirm the app language/framework (Phase 1) and the ALB controller identity (ADR-011), S3 bucket name (ADR-017), Cloudflare record name, and EKS version.
- Phase 2: create `infrastructure/environments/dev` and `modules/eks`/`modules/iam`; validate with `terraform fmt`/`validate`.
- Phase 1: implement the example API, Dockerfile, and Helm chart.

# Session Handoff

## Resume block (read first)

- Repo state: branch `dev`, HEAD `89f6134`, working tree dirty (new `.ai/` context adopted, `AGENTS.md`, `.gitignore`, `README.md` pending commit).
- Source of truth: `AGENTS.md` → `.ai/`
- Budget / usage observed: unknown
- Checkpoint updated: 2026-09-15
- Last goal: Record the registry (ECR removed), Cloudflare DNS, ingress, and account/region decisions in the plan.
- Exact next action: Confirm the open decisions (GHCR vs Docker Hub; Cloudflare zone/record; ALB ingress; TLS), then start Phase 1 (app/Docker/Helm) and Phase 2 `modules/vpc` per ADR-013. No code written yet; the user asked to update the plan only.
- Blocked by: None. VPC module implementation is paused only by the user's "plan only, no code yet" instruction. AWS phases (3+) blocked on explicit authorization and the open decisions in `TASKS.md`.
- Resume prompt: `Read AGENTS.md and .ai/HANDOFF.md. Continue from the Resume block. Do not rediscover context.`

## Goal

Build a public portfolio GitOps platform on AWS EKS demonstrating Platform Engineering, GitOps, Terraform, Kubernetes, Helm, Argo CD, CI/CD, security, and cost control, within a US$ 100 credit budget.

## Current State

Context adopted from the approved brief. No application, infrastructure, or GitOps artifacts exist yet. The repository currently holds only `README.md`, `AGENTS.md`, and `.ai/` plus a pending `.gitignore`.

## What Was Done

- Adopted `.ai/PROJECT.md`, `.ai/ARCHITECTURE.md`, `.ai/CONVENTIONS.md` with real project facts.
- Recorded project ADRs 004–012 in `.ai/DECISIONS.md` (monorepo, namespaces, cost guardrails, OIDC, immutable tags, sync policy, ALB, proposed identity/network decisions).
- Wrote the phased roadmap and open decisions in `.ai/TASKS.md`.
- Recorded the flexible VPC module requirement as ADR-013 and reflected it in `ARCHITECTURE.md`, `CONVENTIONS.md`, `TASKS.md` (no module code written yet).
- Recorded registry/DNS/ingress decisions: ECR removed and GHCR proposed (ADR-014), ALB ingress proposed (ADR-015), Cloudflare DNS accepted (ADR-016); region set to `us-east-1`.
- Initialized this Resume block.

## Files Changed

- `.ai/PROJECT.md`, `.ai/ARCHITECTURE.md`, `.ai/CONVENTIONS.md`
- `.ai/DECISIONS.md`, `.ai/TASKS.md`, `.ai/TOOLS.md`, `.ai/VALIDATION.md`
- `.ai/HANDOFF.md`
- `.gitignore`, `README.md` (project overview)

## Decisions Made

- Single monorepo with area-separated directories (ADR-004).
- `dev` and `prod` as namespaces in one temporary cluster (ADR-005).
- No NAT Gateway or secondary managed services (ADR-006).
- GitHub OIDC instead of static credentials (ADR-007).
- Immutable SHA image tags only (ADR-008).
- `dev` auto-syncs with prune/selfHeal; `prod` is PR-gated (ADR-009).
- One temporary ALB via the controller, native DNS only (ADR-010).
- Proposed: EKS Pod Identity for the controller (ADR-011); NAT-free network egress (ADR-012).
- Accepted: flexible create-or-adopt VPC module with supplied IGW/NAT and always-created route tables (ADR-013); Cloudflare DNS (ADR-016).
- Proposed: registry outside AWS, GHCR (ADR-014); ingress via AWS Load Balancer Controller/ALB (ADR-015).

## Problems / Risks

- Open decisions (region/account, network egress, controller identity, EKS version/node size, state backend) must be resolved before the dependent phases.
- AWS phases consume credits and require explicit authorization and a plan first.
- No tooling is installed/verified yet, so validation is limited to structure review.

## Validation Performed

- Structure review only; no build/test/lint tooling exists yet. Nothing else validated.

## Next Actions

- Confirm open decisions: registry (GHCR vs Docker Hub, public/private), Cloudflare zone + record name, ALB ingress, TLS via ACM vs HTTP-only, EKS version/node size, network egress, state backend.
- Phase 1: implement the example API, Dockerfile, and Helm chart; run local tests, `docker build`, `helm lint`, `helm template`.
- Phase 2: implement `modules/vpc` per ADR-013 and validate with `terraform fmt -recursive` / `terraform validate`.

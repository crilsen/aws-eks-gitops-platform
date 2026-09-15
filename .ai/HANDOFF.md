# Session Handoff

## Resume block (read first)

- Repo state: branch `dev`, synced with `origin/dev` (latest context commit `644c8b0`); working tree clean.
- Source of truth: `AGENTS.md` → `.ai/`
- Budget / usage observed: unknown
- Checkpoint updated: 2026-09-15
- Last goal: Record the AWS decisions (S3 state, adopt existing VPC/IGW/NAT, ALB + ACM, Cloudflare `crilsen.com`, EKS latest + 1 small node).
- Exact next action: Get the subnet CIDR interpretation (ADR-019: `10.11.21.0/24` onward vs literal `10.21.0.0/24`) and the registry confirmation (GHCR vs Docker Hub, ADR-014); then start Phase 1 or Phase 2. No code written yet.
- Blocked by: Subnet CIDR (ADR-019) blocks Phase 2. AWS phases (3+) blocked on explicit authorization.
- Resume prompt: `Read AGENTS.md and .ai/HANDOFF.md. Continue from the Resume block. Do not rediscover context.`

## Goal

Build a public portfolio GitOps platform on AWS EKS demonstrating Platform Engineering, GitOps, Terraform, Kubernetes, Helm, Argo CD, CI/CD, security, and cost control, within a US$ 100 credit budget.

## Current State

Context adopted from the approved brief. No application, infrastructure, or GitOps artifacts exist yet. The repository currently holds `README.md` (marked under development), `AGENTS.md`, `.gitignore`, and `.ai/`, committed and pushed on `dev`.

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
- Accepted: flexible create-or-adopt VPC module (ADR-013); Cloudflare DNS + ACM TLS (ADR-016); adopt existing VPC/IGW/NAT with private egress via reused NAT (ADR-012); ALB ingress (ADR-015); S3 state (ADR-017); EKS latest + 1 small node (ADR-018); subnet CIDR scheme (ADR-019, interpretation pending).
- Proposed/open: registry outside AWS — GHCR recommended (ADR-014); ALB controller identity Pod Identity vs IRSA (ADR-011).

## Problems / Risks

- Open decisions (region/account, network egress, controller identity, EKS version/node size, state backend) must be resolved before the dependent phases.
- AWS phases consume credits and require explicit authorization and a plan first.
- No tooling is installed/verified yet, so validation is limited to structure review.

## Validation Performed

- Structure review only; no build/test/lint tooling exists yet. Nothing else validated.

## Next Actions

- Confirm the subnet CIDRs (ADR-019) and the registry (ADR-014: GHCR vs Docker Hub); confirm the node instance type (ADR-018), the S3 bucket name (ADR-017), the controller identity (ADR-011), and the Cloudflare record name.
- Phase 1: implement the example API, Dockerfile, and Helm chart; run local tests, `docker build`, `helm lint`, `helm template`.
- Phase 2: implement `modules/vpc` (adopt existing VPC/IGW/NAT, `/24` subnets, always-created route tables) and `modules/eks`/`iam`; validate with `terraform fmt -recursive` / `terraform validate`.

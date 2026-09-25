# Conventions

## Observed

Implementation exists and is live (EKS 1.36, 2 nodes, ArgoCD synced). The items below mix observed practice with the approved conventions they evolved from.

## Naming and layout

- Repository is a monorepo; keep `infrastructure/`, `application/`, `gitops/`, and `docs/` responsibilities separate so each can be extracted later.
- Terraform uses reusable `infrastructure/modules/` plus environment roots under `infrastructure/environments/`.
- Kubernetes manifests live under `gitops/`, grouped by `environments/`, `applications/`, and platform install values.

## AWS and Terraform

- Tag every taggable resource with: `Project = aws-eks-gitops-platform`, `Environment`, `Owner = Cristiano`, `ManagedBy = Terraform`, `AutoDelete = true`.
- The VPC module must support creating or adopting a VPC, configurable subnet CIDRs, supplied IGW/NAT, and must always create and own its route tables (ADR-013).
- Terraform state lives in S3 with per-state keys (ADR-017); private inputs (`public_access_cidrs`, `cert/` paths) and the bucket name are supplied privately and never versioned.
- Apply least privilege in IAM; never store static AWS credentials — CI pushes to GHCR with `GITHUB_TOKEN` (GitHub OIDC for AWS stays deferred per ADR-023).
- Pin Terraform providers, modules, and Helm chart versions; avoid floating ranges.
- Keep account id, region, credentials, and other sensitive values out of docs and context; use `.tfvars`/`.example` files.
- Never commit `.tfstate`, credentials, tokens, or secrets; `.gitignore` covers state, plans, provider dirs, and secrets.
- Validate with `terraform fmt`, `terraform validate`, and `tflint`; scan with Checkov.

## Kubernetes and application

- Namespaces: `argocd`, `dev`, `prd`.
- Application containers define `readinessProbe`, `livenessProbe`, `requests`, and `limits`; the ALB health check targets `/health`.
- Use `ingressClassName: alb`; DNS is managed in Cloudflare (no Route 53). ACM is allowed for ALB TLS.
- `dev` uses `syncPolicy.automated` with `prune: true` and `selfHeal: true`; `prod` is not auto-synced and is promoted by PR.
- Application is Python + FastAPI (ADR-020); the Helm chart in `application/helm` is the deploy unit and carries the optional ALB `Ingress`.
- GitHub Actions workflows live in the repository root `.github/workflows/`, scoped to the application path (ADR-021).
- Use Sync Waves to order dependent resources (namespace, secrets, ingress controller, application).
- Images live in an external registry (GHCR default, Docker Hub supported; ADR-014) and always use immutable commit-SHA tags; never deploy `latest`.

## Quality and security

- CI runs tests, lint, Trivy image scan, an immutable-tag build, and a registry push (GHCR default).
- Document security trade-offs adopted for the lab rather than hiding them.

## Documentation

- Keep `AGENTS.md` short and route-oriented; reference authoritative docs instead of copying.
- Keep `TASKS.md` current-state only and `HANDOFF.md` operational, not a chat transcript.
- Treat `LEARNINGS.md` as a bounded append-only buffer; promote durable learnings into `CONVENTIONS.md`, `DECISIONS.md`, `TOOLS.md`, or `VALIDATION.md`.
- Keep the Resume block in `HANDOFF.md` current as a rolling checkpoint and honor `.ai/LIMITS.md`.

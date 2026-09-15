# Conventions

## Observed

No implementation artifacts exist yet, so no historical naming, Terraform, Kubernetes, CI/CD, or scripting conventions can be observed. The items below are **approved project conventions** taken from the brief and the template.

## Naming and layout

- Repository is a monorepo; keep `infrastructure/`, `application/`, `gitops/`, and `docs/` responsibilities separate so each can be extracted later.
- Terraform uses reusable `infrastructure/modules/` plus environment roots under `infrastructure/environments/`.
- Kubernetes manifests live under `gitops/`, grouped by `environments/`, `applications/`, and platform install values.

## AWS and Terraform

- Tag every taggable resource with: `Project = aws-eks-gitops-platform`, `Environment`, `Owner = Cristiano`, `ManagedBy = Terraform`, `AutoDelete = true`.
- The VPC module must support creating or adopting a VPC, configurable subnet CIDRs, supplied IGW/NAT, and must always create and own its route tables (ADR-013).
- Apply least privilege in IAM; never create long-lived access keys for CI (use GitHub OIDC).
- Pin Terraform providers, modules, and Helm chart versions; avoid floating ranges.
- Keep account id, region, credentials, and other sensitive values out of docs and context; use `.tfvars`/`.example` files.
- Never commit `.tfstate`, credentials, tokens, or secrets; `.gitignore` covers state, plans, provider dirs, and secrets.
- Validate with `terraform fmt`, `terraform validate`, and `tflint`; scan with Checkov.

## Kubernetes and application

- Namespaces: `argocd`, `dev`, `prod`.
- Application containers define `readinessProbe`, `livenessProbe`, `requests`, and `limits`; the ALB health check targets `/health`.
- Use `ingressClassName: alb`; DNS is managed in Cloudflare (no Route 53). ACM is allowed for ALB TLS.
- `dev` uses `syncPolicy.automated` with `prune: true` and `selfHeal: true`; `prod` is not auto-synced and is promoted by PR.
- Use Sync Waves to order dependent resources (namespace, secrets, ingress controller, application).
- Images live in an external registry (GHCR proposed; ECR removed) and always use immutable commit-SHA tags; never deploy `latest`.

## Quality and security

- CI runs tests, lint, Trivy image scan, an immutable-tag build, and a registry push (GHCR proposed).
- Document security trade-offs adopted for the lab rather than hiding them.

## Documentation

- Keep `AGENTS.md` short and route-oriented; reference authoritative docs instead of copying.
- Keep `TASKS.md` current-state only and `HANDOFF.md` operational, not a chat transcript.
- Treat `LEARNINGS.md` as a bounded append-only buffer; promote durable learnings into `CONVENTIONS.md`, `DECISIONS.md`, `TOOLS.md`, or `VALIDATION.md`.
- Keep the Resume block in `HANDOFF.md` current as a rolling checkpoint and honor `.ai/LIMITS.md`.
